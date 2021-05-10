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
}
