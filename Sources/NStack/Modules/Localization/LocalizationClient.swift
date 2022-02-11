import Vapor

public final class LocalizationClient {
    let client: NStackClient
    let localizationConfig: LocalizationConfig
    var localizations: [String: Localization]
    var attempts: [String: TranslationAttempt]
    let cache: Cache
    let logger: NStackLogger
    private let eventLoop: EventLoop

    public init(
        localizationConfig: LocalizationConfig,
        nstackConfig: NStackConfig,
        client: Client,
        logger: Logger,
        cache: Cache
    ) {
        self.client = .init(client: client, config: nstackConfig)
        self.localizationConfig = localizationConfig
        self.localizations = [:]
        self.attempts = [:]
        self.cache = cache
        self.logger = NStackLogger(
            isEnabled: nstackConfig.enableLogging,
            logger: logger
        )
        self.eventLoop = client.eventLoop
    }

    struct Paths {
        static var platformResources = "/api/v2/content/localize/resources/platforms"
        static var resourceLocalizations = "/api/v2/content/localize/resources"
    }
}

public extension LocalizationClient {

    /// Get localizations matching the provided section - key pair.
    /// - Parameters:
    ///   - platform: platform for which the localizations belong. If none is provided the defaiult platform will be taken from the LocalizationConfig
    ///   - language: language for which the localizations belong. If none is provided the defaiult language will be taken from the LocalizationConfig
    ///   - section: the section you are looking for
    ///   - key: the key you want to match
    ///   - searchReplacePairs: an optional set of search/replace pairs, to replace any tokens in the localized value
    /// - Returns: The localized value for the section/key pair
    func get(
        platform: LocalizationPlatform? = nil,
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
                    for (search, replace) in searchReplacePairs {
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

    /// Get localizations matching the provided section.
    /// - Parameters:
    ///   - platform: platform for which the localizations belong. If none is provided the defaiult platform will be taken from the LocalizationConfig
    ///   - language: language for which the localizations belong. If none is provided the defaiult language will be taken from the LocalizationConfig
    ///   - section: the section you are looking for
    /// - Returns: The localized values for the section
    func get(
        platform: LocalizationPlatform? = nil,
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

    /// Preload localizations for the provided platform and language. If none is provided the dafault values will be used from the LocalizationConfig
    /// - Parameters:
    ///   - platform: optional platform
    ///   - language: optional language
    /// - Returns: EventLoopFuture holding Void once the localizations is preloaded and cached
    func preloadLocalization(
        platform: LocalizationPlatform? = nil,
        language: String? = nil
    ) -> EventLoopFuture<Void> {
        let platform = platform ?? localizationConfig.defaultPlatform
        let language = language ?? localizationConfig.defaultLanguage

        return fetchLocalization(platform: platform, language: language).transform(to: ())
    }
    
    private func fetchLocalization(
        platform: LocalizationPlatform,
        language: String
    ) -> EventLoopFuture<Localization?> {
        let cacheKey = LocalizationClient.makeCacheKey(platform: platform, language: language)

        // Check for recent look up attempts
        if let attempt: TranslationAttempt = attempts[cacheKey],
            attempt.avoidFetchingAgain(
                retryWaitingPeriodInSeconds: localizationConfig.retryWaitingPeriodInSeconds,
                notFoundWaitingPeriodInSeconds: localizationConfig.notFoundWaitingPeriodInSeconds
        ) {
            logger.log(message: "Failed lately, no reason to try again", withLevel: .info)

            if let memoryLocalization = getLocalizationsFromMemory(platform: platform, language: language) {
                logger.log(message: "Using localizations from memory cache as fallback", withLevel: .info)
                return eventLoop.future(memoryLocalization)
            }

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
                    logger.log(message: "Using localizations from Vapor cache as fallback", withLevel: .info)
                    return eventLoop.future(cachedLocalization)
                }

                // Fetch localizations from NStack
                logger.log(message: "Fetching new localizations from NStack", withLevel: .info)
                return getLocalizationsFromNStack(platform: platform, language: language)
            }
    }

    private func getLocalizationsFromMemory(
        platform: LocalizationPlatform,
        language: String
    ) -> Localization? {
        let cacheKey = LocalizationClient.makeCacheKey(platform: platform, language: language)

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

    private func getLocalizationsFromCache(
        platform: LocalizationPlatform,
        language: String
    ) -> EventLoopFuture<Localization?> {
        let cacheKey = LocalizationClient.makeCacheKey(platform: platform, language: language)
        return cache.get(cacheKey, as: Localization.self).map { [self] localization in
            if localization?.isOutdated(logger: logger, localizationConfig.cacheInMinutes) == true {
                logger.log(message: "Localization cache is outdated", withLevel: .info)
                // TODO: how to drop a cache in Vapor 4?
                return nil
            }
            return localization
        }
    }

    private func getLocalizationsFromNStack(
        platform: LocalizationPlatform,
        language: String
    ) -> EventLoopFuture<Localization?> {
        let resourcePath = "\(Paths.platformResources)/\(platform.rawValue)"
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
            let errorMessage = "[NStack] Could not find any localizations for platform: \(platform) and language: \(language)"

            // Use the URL for the cached and published localizations if they exists
            if URL(string: resource.url) != nil {
                return client.getContent(forURL: resource.url, withErrorMessage: errorMessage)
            }

            // Else create the path and get localizations directly from NStack
            let path = "\(Paths.resourceLocalizations)/\(resource.id)"
            return client.getContent(forPath: path, withErrorMessage: errorMessage)
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
            let cacheKey = LocalizationClient.makeCacheKey(platform: platform, language: language)
            attempts[cacheKey] = TranslationAttempt(error: nstackError)
            throw nstackError
        }
    }

    private func setCache(
        localization: Localization
    ) -> EventLoopFuture<Void> {
        let cacheKey = LocalizationClient.makeCacheKey(
            platform: localization.platform,
            language: localization.language
        )
        logger.log(message: "Caching localizations on key: \(cacheKey)", withLevel: .info)

        // Put in memory cache
        localizations[cacheKey] = localization

        // Put in vapor KeyedCache
        return cache.set(cacheKey, to: localization)
    }

    private static func makeCacheKey(platform: LocalizationPlatform, language: String) -> String {
        return platform.rawValue.lowercased() + "_" + language.lowercased()
    }
}
