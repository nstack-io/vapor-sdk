import Vapor

protocol NStackClientProtocol {
    init(application: Application)
    func getContent<C: NStackResponse>(forPath: String) -> EventLoopFuture<C>
}

final class NStackClient: NStackClientProtocol {
    let client: Client
    let config: NStackConfig
    let decoder: JSONDecoder

    init(application: Application) {
        self.client = application.client
        self.config = application.nstack.config
        self.decoder = JSONDecoder()
    }

    /// Get NStack content for the provided path.
    /// - Parameter path: path to the desired content
    /// - Returns: An Event Loop Future holding the decoded response
    func getContent<C>(forPath path: String) -> EventLoopFuture<C> where C : NStackResponse {
        let url = URI(path: "\(config.baseURL)/\(path)")

        return client.get(url, headers: authHeaders())
            .flatMapThrowing { [self] response in
                try assertOKResponse(response, errorMessage: "")

                let body = try getResponseBody(from: response, forPath: path)

                return try decoder.decode(C.self, from: body)
            }
    }

    private func assertOKResponse(_ response: ClientResponse, errorMessage: String) throws {
        guard response.status == .ok else {

            throw NStackError.failedToFetchContent(
                withMessage: "\(errorMessage): \(response)",
                andStatus: response.status
            )
        }
    }

    private func getResponseBody(from response: ClientResponse, forPath path: String) throws -> ByteBuffer {
        guard let body = response.body else {
            throw NStackError.missingResponseBody(forPath: path)
        }
        return body
    }

    private func authHeaders() -> HTTPHeaders {
        [
            "Accept": "application/json",
            "X-Application-Id": config.applicationID,
            "X-Rest-Api-Key": config.restKey,
        ]
    }
}

//{
//    "data": {
//        "default": {
//            "title": "NStack SDK Demo",
//            "test": "test"
//        },
//        "test": {
//            "testDollarSign": "__testDollarSign",
//            "testSingleQuotationMark": "__testSingleQuotationMark",
//            "testDoubleQuotationMark": "__testDoubleQuotationMark",
//            "testMultipleLines": "__testMultipleLines"
//        }
//    },
//    "meta": {
//        "language": {
//            "id": 7,
//            "name": "German (Austria)",
//            "locale": "de-AT",
//            "direction": "LRM",
//            "is_default": false,
//            "is_best_fit": false
//        },
//        "platform": {
//            "id": 515,
//            "slug": "mobile"
//        }
//    }
//}
