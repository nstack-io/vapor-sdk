import Foundation

struct LocalizationResource: NStackResponse {
    var data: [Resource]

    struct Resource: Decodable {
        let id: Int
        let url: String
        let lastUpdatedAt: Date
        let shouldUpdate: Bool
        let language: Language

        struct Language: Decodable {
            let id: Int
            let name: String
            let locale: String
            let direction: String
            let isDefault: Bool
            let idBestFit: Bool

            enum CodingKeys: String, CodingKey {
                case id
                case name
                case locale
                case direction
                case isDefault = "is_default"
                case isBestFit = "is_best_fit"
            }
        }

        enum CodingKeys: String, CodingKey {
            case id
            case url
            case lastUpdatedAt = "last_updated_at"
            case shouldUpdate = "should_update"
            case language
        }
    }

    var meta: String? { nil } // The language response doesn't have any metadata hence hardcoded to be `nil`
}
