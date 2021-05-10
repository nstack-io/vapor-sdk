import Vapor

public struct NStackPreloadLocalizationsMiddleware: Middleware {
    let languageHeader: String
    let platformHeader: String

    init(
        languageHeader: String = "X-LOCALIZATIONS-LANGUAGE",
        platformHeader: String = "X-LOCALIZATIONS-PLATFORM"
    ) {
        self.languageHeader = languageHeader
        self.platformHeader = platformHeader
    }

    public func respond(
        to request: Request,
        chainingTo next: Responder
    ) -> EventLoopFuture<Response> {
        let language = request.headers.first(name: languageHeader)
        let platform = request.headers.first(name: platformHeader).flatMap(LocalizationPlatform.init(rawValue:))

        return request.nstack.localize
            .preloadLocalization(
                platform: platform,
                language: language
            )
            .flatMap { _ in
                next.respond(to: request)
            }
    }
}
