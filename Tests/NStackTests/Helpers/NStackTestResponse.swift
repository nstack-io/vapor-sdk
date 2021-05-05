@testable import NStack
import Vapor

struct NStackTestResponse {
    var responses: [String: ClientResponse]

    init() {
        self.responses = [:]
        responses["https://nstack.io\(LocalizationClient.Paths.platformResources)/backend"] = .init(
            status: .ok,
            headers: .init([("Content-Type", "application/json")]),
            body: .init(string: NStackTestResponseBody.localizationResources)
        )
        responses["https://nstack.io\(LocalizationClient.Paths.platformResources)/mobile"] = .init(
            status: .notFound,
            headers: .init([("Content-Type", "application/json")]),
            body: .init(string: NStackTestResponseBody.notFoundMessage)
        )
        responses["https://cdn-raw.vapor.cloud/nstack/data/localize-publish/publish-danish-test.json"] = .init(
            status: .ok,
            headers: .init([("Content-Type", "application/json")]),
            body: .init(string: NStackTestResponseBody.localizationsDanish)
        )
        responses["https://cdn-raw.vapor.cloud/nstack/data/localize-publish/publish-english-test.json"] = .init(
            status: .ok,
            headers: .init([("Content-Type", "application/json")]),
            body: .init(string: NStackTestResponseBody.localizationsEnglish)
        )
        responses["https://nstack.io\(LocalizationClient.Paths.resourceLocalizations)/1280"] = .init(
            status: .ok,
            headers: .init([("Content-Type", "application/json")]),
            body: .init(string: NStackTestResponseBody.localizationsDanish)
        )
        responses["https://nstack.io\(LocalizationClient.Paths.resourceLocalizations)/1281"] = .init(
            status: .ok,
            headers: .init([("Content-Type", "application/json")]),
            body: .init(string: NStackTestResponseBody.localizationsEnglish)
        )
    }
}

enum NStackTestResponseBody {
    static var localizationResources = """
    {
      "data": [
        {
          "id": 1280,
          "url": "https://cdn-raw.vapor.cloud/nstack/data/localize-publish/publish-danish-test.json",
          "last_updated_at": "2020-11-09T13:53:56+00:00",
          "should_update": true,
          "language": {
            "id": 6,
            "name": "Danish",
            "locale": "da-DK",
            "direction": "LRM",
            "is_default": true,
            "is_best_fit": true
          }
        },
        {
          "id": 1281,
          "url": "https://cdn-raw.vapor.cloud/nstack/data/localize-publish/publish-english-test.json",
          "last_updated_at": "2020-11-09T13:54:05+00:00",
          "should_update": true,
          "language": {
            "id": 56,
            "name": "English",
            "locale": "en-EN",
            "direction": "LRM",
            "is_default": false,
            "is_best_fit": false
          }
        }
      ]
    }
    """

    static var localizationsEnglish = """
    {
      "data": {
        "test": {
          "greeting": "Hello, {name}!"
        }
      },
      "meta": {
        "language": {
          "id": 56,
          "name": "English",
          "locale": "en-EN",
          "direction": "LRM",
          "is_default": false,
          "is_best_fit": false
        },
        "platform": {
          "id": 535,
          "slug": "backend"
        }
      }
    }
    """

    static var localizationsDanish = """
    {
      "data": {
        "test": {
          "greeting": "Hej, {name}!"
        }
      },
      "meta": {
        "language": {
          "id": 57,
          "name": "Danish",
          "locale": "da-DA",
          "direction": "LRM",
          "is_default": false,
          "is_best_fit": false
        },
        "platform": {
          "id": 535,
          "slug": "backend"
        }
      }
    }
    """

    static var notFoundMessage = """
    {
      "message": "Could not find platform with slug [mobile] for authed application",
      "class": "NStack\\Support\\Exceptions\\HttpException",
      "localized_message": null,
      "code": null,
      "errors": [],
      "service": null
    }
    """
}
