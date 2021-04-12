extension Localization {
    struct ResponseData: NStackResponse {
        typealias DataObject = LocalizationFormat

        struct Metadata: Decodable {
            let language: Language
            let platform: Platform

            struct Language: Decodable {
                let id: Int
                let name: String
                let locale: String
                let direction: String
                let isDefault: Bool
                let isBestFit: Bool

                enum CodingKeys: String, CodingKey {
                    case id
                    case name
                    case locale
                    case direction
                    case isDefault = "is_default"
                    case isBestFit = "is_best_fit"
                }
            }

            struct Platform: Decodable {
                var id: Int
                var slug: String
            }
        }

        let data: LocalizationFormat
        let meta: Metadata
    }
}
