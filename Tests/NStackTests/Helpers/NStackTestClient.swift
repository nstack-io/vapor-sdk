import Vapor
@testable import NStack

struct NStackTestClient: Client {
    func delegating(to eventLoop: EventLoop) -> Client {
        NStackTestClient(eventLoop: eventLoop, responses: [:])
    }

    func send(_ request: ClientRequest) -> EventLoopFuture<ClientResponse> {
        guard let response = responses[request.url.string] else {
            return eventLoop.future(error: NStackError.unexpectedLocalizationError(message: "message"))
        }
        return eventLoop.future(response)
    }

    let eventLoop: EventLoop
    let responses: [String: ClientResponse]

//    func getContent<C>(
//        forPath path: String,
//        withErrorMessage message: String
//    ) -> EventLoopFuture<C> where C : NStackResponse {
//        switch path {
//        // Localization paths
//        case "\(LocalizationController.Paths.platformResources)/backend":
//            return eventLoop.future(NStackTestResponse.localizationResources as! C)
//        case "\(LocalizationController.Paths.resourceLocalizations)/1":
//            return eventLoop.future(NStackTestResponse.localizationsEnglish as! C)
//        case "\(LocalizationController.Paths.resourceLocalizations)/2":
//            return eventLoop.future(NStackTestResponse.localizationsGerman as! C)
//        default:
//            return eventLoop.future(error: NStackError.unexpectedLocalizationError(message: message))
//        }
//    }
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
