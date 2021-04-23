import Foundation

struct LocalizationResource: NStackResponse {
    var data: [Resource]
    var meta: String? // Resources endpoint do not return a metadata object, hence the optional string that will always be set to `nil`

    struct Resource: Decodable {
        let id: Int
        let url: String
        let lastUpdatedAt: Date
        let language: Language

        struct Language: Decodable {
            let locale: String
        }
    }
}
