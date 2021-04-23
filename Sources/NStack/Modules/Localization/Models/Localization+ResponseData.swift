extension Localization {
    struct ResponseData: NStackResponse {
        typealias DataObject = LocalizationFormat

        struct Metadata: Decodable {
            let language: Language
            let platform: Platform

            struct Language: Decodable {
                let locale: String
            }

            struct Platform: Decodable {
                var slug: Localize.Platform
            }
        }

        let data: LocalizationFormat
        let meta: Metadata
    }
}

extension Localization {
    init(responseData: ResponseData) {
        self.init(
            localizations: responseData.data,
            platform: responseData.meta.platform.slug,
            language: responseData.meta.language.locale
        )
    }
}
