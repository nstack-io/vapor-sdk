public enum LocalizationPlatform: String, Codable {
    case backend, api, web, mobile

    struct ResponseData: Decodable {
        let id: Int
        let slug: LocalizationPlatform
    }
}
