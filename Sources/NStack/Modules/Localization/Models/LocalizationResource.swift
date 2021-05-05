import Foundation

struct LocalizationResource: NStackResponse {
    var data: [Resource]

    struct Resource: Decodable {
        let id: Int
        let url: String
        let lastUpdatedAt: Date
        let shouldUpdate: Bool
        let language: LocalizationLanguage
    }

    var meta: String? { nil } // The language response doesn't have any metadata hence hardcoded to be `nil`
}
