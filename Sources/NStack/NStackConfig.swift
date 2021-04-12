public struct NStackConfig {
    public let applicationName: String
    public let applicationID: String
    public let restKey: String
    public let enableLogging: Bool
    public let baseURL: String

    public init(
        applicationName: String,
        applicationID: String,
        restKey: String,
        enableLogging: Bool = false,
        baseURL: String = "https://nstack.io/api/v2/"
    ) {
        self.applicationName = applicationName
        self.applicationID = applicationID
        self.restKey = restKey
        self.enableLogging = enableLogging
        self.baseURL = baseURL
    }
}
