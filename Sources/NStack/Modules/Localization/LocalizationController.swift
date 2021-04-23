import Vapor

public final class LocalizationController {
    let client: NStackClientProtocol
    let localizationConfig: LocalizationConfig
    var localizations: [String: Localization]
    var attempts: [String: TranslationAttempt]
    var cache: Cache
    let logger: NStackLogger
    private let eventLoop: EventLoop

    public enum Platform: String, Codable {
        case backend, api, web, mobile
    }

    init(
        client: NStackClientProtocol,
        config: LocalizationConfig,
        application: Application
    ) {
        self.client = client
        self.localizationConfig = config
        self.localizations = [:]
        self.attempts = [:]
        self.cache = application.nstack.caches.cache
        self.logger = NStackLogger(
            isEnabled: application.nstack.config.enableLogging,
            logger: application.logger
        )
        self.eventLoop = application.client.eventLoop
    }

    struct Paths {
        static var platformResources = "/api​/v2​/content​/localize​/resources​/platforms​"
        static var resourceLocalizations = "/api​/v2​/content​/localize​/resources"
    }
}

public typealias Localize = LocalizationController

public extension LocalizationController {

    final func get(
        platform: Platform? = nil,
        language: String? = nil,
        section: String,
        key: String,
        searchReplacePairs: [String: String]? = nil
    ) -> EventLoopFuture<String> {
        let platform = platform ?? self.localizationConfig.defaultPlatform
        let language = language ?? self.localizationConfig.defaultLanguage

        logger.log(
            message: "Requesting translate for platform: \(platform) - language: \(language) - section: \(section) - key: \(key)",
            withLevel: .info
        )

        return fetchLocalization(platform: platform, language: language)
            .map { [self] localization in
                guard let localization = localization else {
                    logger.log(
                        message: "Failed to get localization for section: \(section) and key: \(key)",
                        withLevel: .notice
                    )
                    return Localization.fallback(section: section, key: key)
                }

                var value = localization.get(logger: logger, section: section, key: key)

                // Search / Replace placeholders
                if let searchReplacePairs = searchReplacePairs {
                    for(search, replace) in searchReplacePairs {
                        value = value.replacingOccurrences(
                            of: localizationConfig.placeholderPrefix + search + localizationConfig.placeholderSuffix,
                            with: replace
                        )
                    }
                }
                return value
            }
            .flatMapError { [self] _ in
                logger.log(
                    message: "Failed to get localization for section: \(section) and key: \(key)",
                    withLevel: .notice
                )
                return eventLoop.future(Localization.fallback(section: section, key: key))
            }
    }

    final func get(
        platform: Platform? = nil,
        language: String? = nil,
        section: String
    ) -> EventLoopFuture<[String: String]> {
        let platform = platform ?? self.localizationConfig.defaultPlatform
        let language = language ?? self.localizationConfig.defaultLanguage

        logger.log(
            message: "Requesting translate for platform: \(platform) - language: \(language) - section: \(section)",
            withLevel: .info
        )

        return fetchLocalization(platform: platform, language: language)
            .map { [self] localization in
                guard let localization = localization else {
                    return Localization.fallback(section: section)
                }
                return localization.get(logger: logger, section: section)
            }
            .flatMapError { [self] _ in
                logger.log(
                    message: "Failed to get localization for section: \(section)",
                    withLevel: .notice
                )
                return eventLoop.future(Localization.fallback(section: section))
            }
    }

    final func preloadLocalization(
        platform: Platform? = nil,
        language: String? = nil
    ) -> EventLoopFuture<Void> {
        let platform = platform ?? localizationConfig.defaultPlatform
        let language = language ?? localizationConfig.defaultLanguage

        return fetchLocalization(platform: platform, language: language).transform(to: ())
    }
    
    private final func fetchLocalization(
        platform: Platform,
        language: String
    ) -> EventLoopFuture<Localization?> {
        let cacheKey = LocalizationController.makeCacheKey(platform: platform, language: language)

        // Check for recent look up attempts
        if let attempt: TranslationAttempt = attempts[cacheKey],
            attempt.avoidFetchingAgain(
                retryWaitingPeriodInMinutes: localizationConfig.retryWaitingPeriodInMinutes,
                notFoundWaitingPeriodInMinutes: localizationConfig.notFoundWaitingPeriodInMinutes
        ) {
            logger.log(message: "Failed lately, no reason to try again", withLevel: .info)

            // Try vapor cache
            return getLocalizationsFromCache(platform: platform,language: language)
                .map { [self] localization in
                    if localization == nil {
                        logger.log(message: "Failed lately and no cache", withLevel: .info)
                    } else {
                        logger.log(message: "Vapor cache used as fallback", withLevel: .info)
                    }
                    return localization
                }
        }

        // Try using memory cache
        if let memoryLocalization = getLocalizationsFromMemory(platform: platform, language: language) {
            logger.log(message: "Using localizations from memory cache as fallback", withLevel: .info)
            return eventLoop.future(memoryLocalization)
        }

        // Try using vapor cache
        return getLocalizationsFromCache(platform: platform, language: language)
            .flatMap { [self] cachedLocalization in
                if let cachedLocalization = cachedLocalization {
                    logger.log(message: "Using Vapor cache used as fallback", withLevel: .info)
                    return eventLoop.future(cachedLocalization)
                }

                // Fetch localizations from NStack
                logger.log(message: "Fetching new localizations from NStack", withLevel: .info)
                return getLocalizationsFromNStack(platform: platform, language: language)
            }
    }

    private final func getLocalizationsFromMemory(
        platform: Platform,
        language: String
    ) -> Localization? {
        let cacheKey = LocalizationController.makeCacheKey(platform: platform, language: language)

        // Look up in memory
        let localization: Localization? = localizations[cacheKey]

        // If outdated remove
        if localization?.isOutdated(logger: logger, localizationConfig.cacheInMinutes) == true {
            logger.log(message: "InMemory localization is outdated. Removing it!", withLevel: .info)
            localizations.removeValue(forKey: cacheKey)
            return nil
        }

        return localization
    }

    private final func getLocalizationsFromCache(
        platform: Platform,
        language: String
    ) -> EventLoopFuture<Localization?> {
        let cacheKey = LocalizationController.makeCacheKey(platform: platform, language: language)
        return cache.get(cacheKey, as: Localization.self).map { [self] localization in
            if localization?.isOutdated(logger: logger, localizationConfig.cacheInMinutes) == true {
                logger.log(message: "Localization cache is outdated", withLevel: .info)
                // TODO: how to drop a cache in Vapor 4?
                return nil
            }
            return localization
        }
    }

    private final func getLocalizationsFromNStack(
        platform: Platform,
        language: String
    ) -> EventLoopFuture<Localization?> {
        let resourcePath = "\(Paths.resourceLocalizations)/\(platform.rawValue)"
        return client.getContent(
            forPath: resourcePath,
            withErrorMessage: "[NStack] Could not find any localization resources for platform \(platform)"
        )
        .flatMapThrowing { [self] (resources: LocalizationResource) in
            guard let resource = resources.data.first(where: { $0.language.locale == language }) else {
                logger.log(
                    message: "[NStack] Could not find any localization resource for platform: \(platform) and language \(language)",
                    withLevel: .notice
                )
                throw NStackError.localizationLanguageNotSupported(language: language, platform: platform.rawValue)
            }
            return resource
        }
        .flatMap { [self] (resource: LocalizationResource.Resource) in
            let path = "​\(Paths.resourceLocalizations)/\(resource.id)"
            return client.getContent(
                forPath: path,
                withErrorMessage: "[NStack] Could not find any localizations for platform: \(platform) and language: \(language)"
            )
        }
        .flatMap { [self] (localizationResponse: Localization.ResponseData) in
            // Cache localizations in memory and in Vapor cache
            let localizations = Localization(responseData: localizationResponse)
            return setCache(localization: localizations)
                .transform(to: localizations)
        }
        .flatMapErrorThrowing { [self] error in
            var nstackError: NStackError {
                if let nstackError = error as? NStackError {
                    return nstackError
                }
                return NStackError.unexpectedLocalizationError(message: error.localizedDescription)
            }
            let cacheKey = Localize.makeCacheKey(platform: platform, language: language)
            attempts[cacheKey] = TranslationAttempt(error: nstackError)
            throw nstackError
        }
    }

    private final func setCache(
        localization: Localization
    ) -> EventLoopFuture<Void> {
        let cacheKey = LocalizationController.makeCacheKey(
            platform: localization.platform,
            language: localization.language
        )
        logger.log(message: "Caching localizations on key: \(cacheKey)", withLevel: .info)

        // Put in memory cache
        localizations[cacheKey] = localization

        // Put in vapor KeyedCache
        return cache.set(cacheKey, to: localization)
    }

    private static func makeCacheKey(platform: Platform, language: String) -> String {
        return platform.rawValue.lowercased() + "_" + language.lowercased()
    }
}
