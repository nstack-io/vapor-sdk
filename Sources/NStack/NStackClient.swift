import Vapor

struct NStackClient {
    let client: Client
    let config: NStackConfig
    let decoder: JSONDecoder

    init(application: Application) {
        self.client = application.client
        self.config = application.nstack.config
        self.decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
    }

    /// Get NStack content for the provided path.
    /// - Parameter path: path to the desired content
    /// - Returns: An Event Loop Future holding the decoded response
    func getContent<C>(
        forPath path: String,
        withErrorMessage errorMessage: String
    ) -> EventLoopFuture<C> where C : NStackResponse {
        let url = URI(scheme: config.scheme, host: config.baseURL, path: path)

        return client.get(url, headers: authHeaders())
            .flatMapThrowing { [self] response in
                try assertOKResponse(response, errorMessage: errorMessage)

                let body = try getResponseBody(from: response, forPath: path)

                do {
                    return try decoder.decode(C.self, from: body)
                } catch {
                    throw NStackError.decodingResponseBodyFailed(path: path, type: C.self)
                }
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
            "X-application-ID": config.applicationID,
            "X-Rest-Api-Key": config.restKey,
        ]
    }
}
