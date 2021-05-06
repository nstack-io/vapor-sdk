public struct LocalizationConfig: Codable {
    public let defaultPlatform: LocalizationPlatform
    public let defaultLanguage: String
    public let cacheInMinutes: Int
    public let placeholderPrefix: String
    public let placeholderSuffix: String
    public let retryWaitingPeriodInSeconds: Double
    public let notFoundWaitingPeriodInSeconds: Double

    public static let `default` = LocalizationConfig(
        defaultPlatform: .backend,
        defaultLanguage: "en-EN",
        cacheInMinutes: 60,
        placeholderPrefix: "{",
        placeholderSuffix: "}",
        retryWaitingPeriodInSeconds: 180,
        notFoundWaitingPeriodInSeconds: 300
    )

    public init(
        defaultPlatform: LocalizationPlatform = LocalizationConfig.default.defaultPlatform,
        defaultLanguage: String = LocalizationConfig.default.defaultLanguage,
        cacheInMinutes: Int =  LocalizationConfig.default.cacheInMinutes,
        placeholderPrefix: String = LocalizationConfig.default.placeholderPrefix,
        placeholderSuffix: String = LocalizationConfig.default.placeholderSuffix,
        retryWaitingPeriodInSeconds: Double = LocalizationConfig.default.retryWaitingPeriodInSeconds,
        notFoundWaitingPeriodInSeconds: Double = LocalizationConfig.default.notFoundWaitingPeriodInSeconds
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

        self.retryWaitingPeriodInSeconds = retryWaitingPeriodInSeconds
        self.notFoundWaitingPeriodInSeconds = notFoundWaitingPeriodInSeconds
    }
}
