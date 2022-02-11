import Vapor

struct NStackClient {
    let client: Client
    let baseURL: URI
    let headers: HTTPHeaders
    let decoder: JSONDecoder

    init(client: Client, config: NStackConfig) {
        self.client = client
        self.headers = [
            "Accept": "application/json",
            "X-application-ID": config.applicationID,
            "X-Rest-Api-Key": config.restKey,
        ]
        self.baseURL = URI(scheme: config.scheme, host: config.baseURL, path: "")
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
        var url = baseURL
        url.path = path

        return getContent(forURI: url, withErrorMessage: errorMessage)
    }

    /// Get NStack content for the provided url. This method should primarily be used to get cached data.
    /// - Parameter url: URL to the (cached) desired content
    /// - Returns: An Event Loop Future holding the decoded response
    func getContent<C>(
        forURL url: String,
        withErrorMessage errorMessage: String
    ) -> EventLoopFuture<C> where C : NStackResponse {
        getContent(forURI: URI(string: url), withErrorMessage: errorMessage)
    }

    private func getContent<C>(
        forURI uri: URI,
        withErrorMessage errorMessage: String
    ) -> EventLoopFuture<C> where C : NStackResponse {
        client.get(uri, headers: headers)
            .flatMapThrowing { response in
                try assertOKResponse(response, errorMessage: errorMessage)

                let body = try getResponseBody(from: response, forPath: uri.path)

                do {
                    return try decoder.decode(C.self, from: body)
                } catch {
                    throw NStackError.decodingResponseBodyFailed(path: uri.path, type: C.self)
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
}
