import Vapor

public struct NStackPreloadLocalizationsMiddleware: Middleware {
    public func respond(
        to request: Request,
        chainingTo next: Responder
    ) -> EventLoopFuture<Response> {
        request.nstack.localize
            .preloadLocalization()
            .flatMap { _ in
                next.respond(to: request)
            }
    }
}
