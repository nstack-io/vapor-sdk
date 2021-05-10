@testable import NStack
import XCTVapor

class NStackTests: XCTestCase {
    var app: Application!
    var testLogHandler: NStackTestLogger!

    override func setUp() {
        app = Application(.testing)
        testLogHandler = NStackTestLogger()

        app.clients.use {
            NStackTestClient(
                eventLoop: $0.eventLoopGroup.next(),
                responses: NStackTestResponse().responses
            )
        }

        app.nstack.config = .init(
            applicationName: "nstack-test-application",
            applicationID: "123456789abc",
            restKey: "secret-rest-key",
            enableLogging: true
        )

        app.nstack.localize = LocalizationClient(
            localizationConfig: LocalizationConfig(
                cacheInMinutes: 1,
                retryWaitingPeriodInSeconds: 30,
                notFoundWaitingPeriodInSeconds: 1
            ),
            nstackConfig: app.nstack.config,
            client: app.client,
            logger: Logger(label: "nstack-test-logger", factory: testLogHandler.get(loggerName:)),
            cache: app.nstack.caches.cache
        )
    }

    override func tearDown() {
        app.shutdown()
        app = nil
    }

    // MARK: Localizations

    func test_EnglishLocalizationWithDefaultSettings() throws {
        testLogHandler.logs = []
        let defaultLocalizations = try app.nstack.localize.get(section: "test").wait()
        XCTAssertEqual(defaultLocalizations.count, 1, "Expected the test section to have one key-value pair")
        XCTAssertTrue(defaultLocalizations.contains(where: { $0.key == "greeting" }), "Expected to have a value for the key 'greeting'")
        XCTAssertFalse(defaultLocalizations.contains(where: { $0.key == "farewell" }), "Expected not to have a value for the key 'farewell'")

        // Verify that localizations were fetched from NStack using the logs
        XCTAssertEqual(testLogHandler.logs.count, 3, "Expects three separate logs to be created")
        XCTAssertEqual(testLogHandler.logs[0], "[INFO] Requesting translate for platform: backend - language: en-EN - section: test")
        XCTAssertEqual(testLogHandler.logs[1], "[INFO] Fetching new localizations from NStack")
        XCTAssertEqual(testLogHandler.logs[2], "[INFO] Caching localizations on key: backend_en-en")
    }

    func test_GermanLocalizationsWithDefaultSettings() throws {
        testLogHandler.logs = []
        let defaultLocalizations = try app.nstack.localize.get(language: "da-DK", section: "test").wait()
        XCTAssertEqual(defaultLocalizations.count, 1, "Expected the test section to have one key-value pair")
        XCTAssertTrue(defaultLocalizations.contains(where: { $0.key == "greeting" }), "Expected to have a value for the key 'greeting'")
        XCTAssertFalse(defaultLocalizations.contains(where: { $0.key == "farewell" }), "Expected not to have a value for the key 'farewell'")

        // Verify that localizations were fetched from NStack using the logs
        XCTAssertEqual(testLogHandler.logs.count, 3, "Expects three separate logs to be created")
        XCTAssertEqual(testLogHandler.logs[0], "[INFO] Requesting translate for platform: backend - language: da-DK - section: test")
        XCTAssertEqual(testLogHandler.logs[1], "[INFO] Fetching new localizations from NStack")
        XCTAssertEqual(testLogHandler.logs[2], "[INFO] Caching localizations on key: backend_da-da")
    }

    func test_EnglishLocalizationsForMissingSection() throws {
        testLogHandler.logs = []
        let defaultLocalizations = try app.nstack.localize.get(section: "missing").wait()
        XCTAssertEqual(defaultLocalizations.count, 0, "Expected the `missing` section to have zero key-value pair")

        // Verify that localizations were fetched from NStack using the logs
        print(testLogHandler.logs)
        XCTAssertEqual(testLogHandler.logs.count, 4, "Expects three separate logs to be created")
        XCTAssertEqual(testLogHandler.logs[0], "[INFO] Requesting translate for platform: backend - language: en-EN - section: missing")
        XCTAssertEqual(testLogHandler.logs[1], "[INFO] Fetching new localizations from NStack")
        XCTAssertEqual(testLogHandler.logs[2], "[INFO] Caching localizations on key: backend_en-en")
        XCTAssertEqual(testLogHandler.logs[3], "[INFO] No translation found for section 'missing'")
    }

    func test_EnglishLocalizationWithTokenReplacement() throws {
        testLogHandler.logs = []
        let localization = try app.nstack.localize.get(section: "test", key: "greeting", searchReplacePairs: ["name": "NStack"]).wait()
        XCTAssertEqual(localization, "Hello, NStack!", "Expected {name} to be replaced with NStack")
    }

    // Missing tests: test caching time and waiting time for not found errors and general errors
    func test_EnglishLocalizationsFromMemoryCache() throws {
        testLogHandler.logs = []
        // Get translations from NStack
        let cachedLocalizations = try app.nstack.localize.get(section: "test")
            .flatMap { _ in self.app.nstack.localize.get(section: "test") }
            .wait()

        XCTAssertEqual(cachedLocalizations.count, 1, "Expected the test section to have one key-value pair")

        // Verify that localizations were fetched from NStack using the logs
        XCTAssertEqual(testLogHandler.logs.count, 6, "Expects six separate logs to be created")
        XCTAssertEqual(testLogHandler.logs[0], "[INFO] Requesting translate for platform: backend - language: en-EN - section: test")
        XCTAssertEqual(testLogHandler.logs[1], "[INFO] Fetching new localizations from NStack")
        XCTAssertEqual(testLogHandler.logs[2], "[INFO] Caching localizations on key: backend_en-en")
        XCTAssertEqual(testLogHandler.logs[3], "[INFO] Requesting translate for platform: backend - language: en-EN - section: test")
        // The fifth log output informs when the cache expires and will not the
        XCTAssertEqual(testLogHandler.logs[5], "[INFO] Using localizations from memory cache as fallback")
    }

    func test_unsupportedPlatform() throws {
        testLogHandler.logs = []
        let emptyLocalizations = try app.nstack.localize.get(platform: .mobile, section: "test").wait()

        XCTAssertTrue(emptyLocalizations.isEmpty)

        XCTAssertEqual(app.nstack.localize.attempts.count, 1, "Expeccted on attempt to be cached")
        XCTAssertTrue(app.nstack.localize.attempts.contains(where: { $0.key == "mobile_en-en" }))
    }

    func test_EnglishLocalizationsFromVaporCache() throws {
        testLogHandler.logs = []
        // Get translations from NStack
        _ = try app.nstack.localize.get(section: "test").wait() // discard first set of loaded localizations
        app.nstack.localize.localizations = [:] // Reset memory cached localizations to force use of vapor cached version
        let cachedLocalizations = try app.nstack.localize.get(section: "test").wait()

        XCTAssertTrue(cachedLocalizations.count == 1, "Expected the test section to have one key-value pair")

        // Verify that localizations were fetched from NStack using the logs
        XCTAssertEqual(testLogHandler.logs.count, 6, "Expects six separate logs to be created")
        XCTAssertEqual(testLogHandler.logs[0], "[INFO] Requesting translate for platform: backend - language: en-EN - section: test")
        XCTAssertEqual(testLogHandler.logs[1], "[INFO] Fetching new localizations from NStack")
        XCTAssertEqual(testLogHandler.logs[2], "[INFO] Caching localizations on key: backend_en-en")
        XCTAssertEqual(testLogHandler.logs[3], "[INFO] Requesting translate for platform: backend - language: en-EN - section: test")
        // Skipping log output with expiration date since it isn't static
        XCTAssertEqual(testLogHandler.logs[5], "[INFO] Using localizations from Vapor cache as fallback")
    }

    func test_refreshEnglishLocalizationsFromNStackOnExpiredCache() throws {
        testLogHandler.logs = []
        // Add mocked memory cache
        app.nstack.localize.localizations["backend_en-en"] = Localization(
            localizations: ["test": ["greeting": "Hello, {name}!"]], platform: .backend, language: "en-EN", date: Date().addingTimeInterval(-3600)
        )
        let nstackLocalizations = try app.nstack.localize.get(section: "test").wait()

        XCTAssertTrue(nstackLocalizations.count == 1, "Expected the test section to have one key-value pair")

        // Verify that localizations were fetched from NStack using the logs
        XCTAssertEqual(testLogHandler.logs.count, 5, "Expects six separate logs to be created")
        XCTAssertEqual(testLogHandler.logs[0], "[INFO] Requesting translate for platform: backend - language: en-EN - section: test")
        // Skipping log output with expiration date since it isn't static
        XCTAssertEqual(testLogHandler.logs[2], "[INFO] InMemory localization is outdated. Removing it!")
        XCTAssertEqual(testLogHandler.logs[3], "[INFO] Fetching new localizations from NStack")
        XCTAssertEqual(testLogHandler.logs[4], "[INFO] Caching localizations on key: backend_en-en")
    }

    func test_usesFallbackIfRecentNStackErrorAndNoCache() throws {
        testLogHandler.logs = []
        app.nstack.localize.attempts["backend_en-en"] = .init(error: .unexpectedLocalizationError(message: "test error"))
        let localizations = try app.nstack.localize.get(section: "test").wait()
        XCTAssertTrue(localizations.isEmpty, "Expected the localizations to be empty since an error whas logged recently and no cache exists")

        XCTAssertEqual(testLogHandler.logs.count, 3)
        XCTAssertEqual(testLogHandler.logs[0], "[INFO] Requesting translate for platform: backend - language: en-EN - section: test")
        XCTAssertEqual(testLogHandler.logs[1], "[INFO] Failed lately, no reason to try again")
        XCTAssertEqual(testLogHandler.logs[2], "[INFO] Failed lately and no cache")
    }

    func test_usesCacheIfRecentNStackError() throws {
        testLogHandler.logs = []
        app.nstack.localize.attempts["backend_en-en"] = .init(error: .unexpectedLocalizationError(message: "test error"))
        // Add mocked memory cache
        app.nstack.localize.localizations["backend_en-en"] = Localization(
            localizations: ["test": ["greeting": "Hello, {name}!"]], platform: .backend, language: "en-EN", date: Date()
        )

        let localizations = try app.nstack.localize.get(section: "test").wait()
        XCTAssertFalse(localizations.isEmpty, "Expected the localizations to be empty since an error whas logged recently and no cache exists")

        XCTAssertEqual(testLogHandler.logs.count, 4)
        XCTAssertEqual(testLogHandler.logs[0], "[INFO] Requesting translate for platform: backend - language: en-EN - section: test")
        XCTAssertEqual(testLogHandler.logs[1], "[INFO] Failed lately, no reason to try again")
        XCTAssertEqual(testLogHandler.logs[3], "[INFO] Using localizations from memory cache as fallback")
    }

    func test_fetchesFromNStackIfAttemptWaitingPeriodIsOver() throws {
        testLogHandler.logs = []
        app.nstack.localize.attempts["backend_en-en"] = .init(error: .unexpectedLocalizationError(message: "test error"), date: Date().addingTimeInterval(-3600))
        let localizations = try app.nstack.localize.get(section: "test").wait()
        XCTAssertFalse(localizations.isEmpty, "Expected the localizations be fetched again since the waiting peroid since last error is over")

        XCTAssertEqual(testLogHandler.logs.count, 3)
        XCTAssertEqual(testLogHandler.logs[0], "[INFO] Requesting translate for platform: backend - language: en-EN - section: test")
        XCTAssertEqual(testLogHandler.logs[1], "[INFO] Fetching new localizations from NStack")
        XCTAssertEqual(testLogHandler.logs[2], "[INFO] Caching localizations on key: backend_en-en")
    }

    func test_localizationsPreloadingMiddleware() throws {
        // register the route using the preload middelware
        testLogHandler.logs = []
        app.grouped(
            NStackPreloadLocalizationsMiddleware(
                languageHeader: "X-LOCALIZATIONS-LANGUAGE",
                platformHeader: "X-LOCALIZATIONS-PLATFORM"
            )
        )
        .get("greeting") { req -> EventLoopFuture<String> in
            let name = try req.query.get(String.self, at: "name")
            return req.nstack.localize
                .get(section: "test", key: "greeting", searchReplacePairs: ["name": name])
        }

        try app.test(
            .GET,
            "greeting?name=Vapor",
            headers: ["X-LOCALIZATION-LANGUAGES": "en-EN", "X-LOCALIZATION-PLATFORMS": "backend"],
            afterResponse: { response in
                XCTAssertEqual(response.status, .ok)

                let responseText = response.body.getString(at: 0, length: 13)
                XCTAssertEqual(responseText, "Hello, Vapor!")
            }
        )

        // MARK: Check logs

        XCTAssertEqual(testLogHandler.logs.count, 5)
        XCTAssertEqual(testLogHandler.logs[0], "[INFO] Fetching new localizations from NStack")
        XCTAssertEqual(testLogHandler.logs[1], "[INFO] Caching localizations on key: backend_en-en")
        XCTAssertEqual(testLogHandler.logs[2], "[INFO] Requesting translate for platform: backend - language: en-EN - section: test - key: greeting")
        // Skipping log output with expiration date since it isn't static
        XCTAssertEqual(testLogHandler.logs[4], "[INFO] Using localizations from memory cache as fallback")
    }
}
