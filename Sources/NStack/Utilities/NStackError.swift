import Vapor

public enum NStackError: Error, AbortError {
    case failedToFetchContent(withMessage: String, andStatus: HTTPStatus)
    case missingResponseBody(forPath: String)

    public var reason: String {
        switch self {
        case .failedToFetchContent(let message, _):
            return "[NStack] \(message)"
        case .missingResponseBody(let path):
            return "[NStack] Response body was missing for path `\(path)`"
        }
    }

    public var status: HTTPResponseStatus {
        switch self {
        case .failedToFetchContent(_, let status):
            return HTTPResponseStatus(statusCode: Int(status.code))
        case .missingResponseBody:
            return .internalServerError
        }
    }
}
