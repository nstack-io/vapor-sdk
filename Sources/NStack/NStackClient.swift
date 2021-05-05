import Vapor

struct NStackClient {
    let client: Client
    let config: NStackConfig
    let decoder: JSONDecoder

    init(client: Client, config: NStackConfig) {
        self.client = client
        self.config = config
        self.decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
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

    /// Get NStack content for the provided url. This method should primarily be used to get cached data.
    /// - Parameter url: URL to the (cached) desired content
    /// - Returns: An Event Loop Future holding the decoded response
    func getContent<C>(
        forURL url: String,
        withErrorMessage errorMessage: String
    ) -> EventLoopFuture<C> where C : NStackResponse {
        client.get(URI(string: url), headers: authHeaders())
            .flatMapThrowing { [self] response in
                try assertOKResponse(response, errorMessage: errorMessage)

                let body = try getResponseBody(from: response, forPath: url)

                do {
                    return try decoder.decode(C.self, from: body)
                } catch {
                    throw NStackError.decodingResponseBodyFailed(path: url, type: C.self)
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
