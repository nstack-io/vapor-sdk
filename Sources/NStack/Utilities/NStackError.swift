import Vapor

public enum NStackError: Error, AbortError {
    case decodingResponseBodyFailed(path: String, type: Decodable.Type)
    case failedToFetchContent(withMessage: String, andStatus: HTTPStatus)
    case localizationLanguageNotSupported(language: String, platform: String)
    case missingResponseBody(forPath: String)
    case unexpectedLocalizationError(message: String)

    public var reason: String {
        switch self {
        case .decodingResponseBodyFailed(let path, let type):
            return "[NStack] Could not decode response body of type \(type) for path: \(path)"
        case .failedToFetchContent(let message, _):
            return "[NStack] \(message)"
        case .localizationLanguageNotSupported(let language, let platform):
            return "[NStack] Could not find any localization resource for platform: \(platform) and language \(language)"
        case .missingResponseBody(let path):
            return "[NStack] Response body was missing for path `\(path)`"
        case .unexpectedLocalizationError(let message):
            return "[NStack] Something unexpected happended while fetching latests localizations. Error message is: \(message)"
        }
    }

    public var status: HTTPResponseStatus {
        switch self {
        case .decodingResponseBodyFailed:
            return .internalServerError
        case .failedToFetchContent(_, let status):
            return HTTPResponseStatus(statusCode: Int(status.code))
        case .localizationLanguageNotSupported:
            return .notFound
        case .missingResponseBody:
            return .internalServerError
        case .unexpectedLocalizationError:
            return .internalServerError
        }
    }
}
