import Vapor

public extension Request {
    struct NStack {
        let request: Request

        public var localize: LocalizationClient { request.application.nstack.localize }
    }

    var nstack: NStack { .init(request: self) }
}
