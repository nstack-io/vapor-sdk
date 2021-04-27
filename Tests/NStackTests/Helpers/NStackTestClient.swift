import Vapor
@testable import NStack

struct NStackTestClient: NStackClientProtocol {
    let eventLoop: EventLoop

    init(application: Application) {
        self.eventLoop = application.client.eventLoop
    }

    func getContent<C>(
        forPath path: String,
        withErrorMessage message: String
    ) -> EventLoopFuture<C> where C : NStackResponse {
        switch path {
        // Localization paths
        case "\(LocalizationController.Paths.platformResources)/backend":
            return eventLoop.future(NStackTestResponse.localizationResources as! C)
        case "\(LocalizationController.Paths.resourceLocalizations)/1":
            return eventLoop.future(NStackTestResponse.localizationsEnglish as! C)
        case "\(LocalizationController.Paths.platformResources)/2":
            return eventLoop.future(NStackTestResponse.localizationsGerman as! C)
        default:
            return eventLoop.future(error: NStackError.unexpectedLocalizationError(message: message))
        }
    }
}

enum NStackTestResponse {
    static var localizationResources = LocalizationResource(
        data: [
            .init(
                id: 1,
                url: "",
                lastUpdatedAt: Date(),
                language: .init(locale: "en-EN")
            ),
            .init(
                id: 2,
                url: "",
                lastUpdatedAt: Date(),
                language: .init(locale: "de-DE")
            )
        ],
        meta: nil
    )

    static var localizationsEnglish = Localization.ResponseData(
        data: [
            "test": [
                "greeting": "Hello, {name}!"
            ]
        ],
        meta: .init(
            language: .init(locale: "en_EN"),
            platform: .init(slug: .backend)
        )
    )

    static var localizationsGerman = Localization.ResponseData(
        data: [
            "test": [
                "greeting": "Hallo, {name}!"
            ]
        ],
        meta: .init(
            language: .init(locale: "de_DE"),
            platform: .init(slug: .backend)
        )
    )
}
