public struct NStackConfig {
    public let applicationName: String
    public let applicationID: String
    public let restKey: String
    public let enableLogging: Bool
    public let scheme: String
    public let baseURL: String

    public init(
        applicationName: String,
        applicationID: String,
        restKey: String,
        enableLogging: Bool = false,
        scheme: String = "https",
        baseURL: String = "nstack.io"
    ) {
        self.applicationName = applicationName
        self.applicationID = applicationID
        self.restKey = restKey
        self.enableLogging = enableLogging
        self.scheme = scheme
        self.baseURL = baseURL
    }
}
