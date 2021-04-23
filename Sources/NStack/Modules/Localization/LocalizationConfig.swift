public struct LocalizationConfig: Codable {
    public let defaultPlatform: Localize.Platform
    public let defaultLanguage: String
    public let cacheInMinutes: Int
    public let placeholderPrefix: String
    public let placeholderSuffix: String
    public let retryWaitingPeriodInMinutes: Double
    public let notFoundWaitingPeriodInMinutes: Double

    public static let `default` = LocalizationConfig(
        defaultPlatform: .backend,
        defaultLanguage: "en-EN",
        cacheInMinutes: 60,
        placeholderPrefix: "{",
        placeholderSuffix: "}",
        retryWaitingPeriodInMinutes: 3,
        notFoundWaitingPeriodInMinutes: 5
    )

    public init(
        defaultPlatform: Localize.Platform = LocalizationConfig.default.defaultPlatform,
        defaultLanguage: String = LocalizationConfig.default.defaultLanguage,
        cacheInMinutes: Int =  LocalizationConfig.default.cacheInMinutes,
        placeholderPrefix: String = LocalizationConfig.default.placeholderPrefix,
        placeholderSuffix: String = LocalizationConfig.default.placeholderSuffix,
        retryWaitingPeriodInMinutes: Double = LocalizationConfig.default.retryWaitingPeriodInMinutes,
        notFoundWaitingPeriodInMinutes: Double = LocalizationConfig.default.notFoundWaitingPeriodInMinutes
    ) {
        self.defaultPlatform = defaultPlatform
        self.defaultLanguage = defaultLanguage
        self.cacheInMinutes = cacheInMinutes

        if placeholderPrefix.isEmpty || placeholderSuffix.isEmpty {
            debugPrint("placeholder prefix/suffix must not be empty, applying default ones")
            self.placeholderPrefix = LocalizationConfig.default.placeholderPrefix
            self.placeholderSuffix = LocalizationConfig.default.placeholderSuffix
        } else {
            self.placeholderPrefix = placeholderPrefix
            self.placeholderSuffix = placeholderSuffix
        }

        self.retryWaitingPeriodInMinutes = retryWaitingPeriodInMinutes
        self.notFoundWaitingPeriodInMinutes = notFoundWaitingPeriodInMinutes
    }
}
