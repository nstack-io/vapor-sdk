@testable import NStack
import XCTVapor

class NStackTests: XCTestCase {
    var app: Application!

    override func setUp() {
        app = Application(.testing)
        app.nstack.config = .init(
            applicationName: "nstack-test-application",
            applicationID: "123456789abc",
            restKey: "secret-rest-key"
        )
        let nstackConfig = LocalizationConfig()
        app.nstack.localize = .init(
            client: NStackTestClient(application: app),
            config: nstackConfig,
            application: app
        )
    }

    override func tearDown() {
        app.shutdown()
        app = nil
    }

    // MARK: Localizations

    func test_EnglishLocalizationWithDefaultSettings() throws {
        let defaultLocalizations = try app.nstack.localize.get(section: "test").wait()
        XCTAssertTrue(defaultLocalizations.count == 1, "Expected the test section to have one key-value pair")
        XCTAssertTrue(defaultLocalizations.contains(where: { $0.key == "greeting" }), "Expected to have a value for the key 'greeting'")
        XCTAssertFalse(defaultLocalizations.contains(where: { $0.key == "farewell" }), "Expected not to have a value for the key 'farewell'")
    }

    func test_GermanLocalizationsWithDefaultSettings() throws {
        let defaultLocalizations = try app.nstack.localize.get(language: "de-DE", section: "test").wait()
        XCTAssertTrue(defaultLocalizations.count == 1, "Expected the test section to have one key-value pair")
        XCTAssertTrue(defaultLocalizations.contains(where: { $0.key == "greeting" }), "Expected to have a value for the key 'greeting'")
        XCTAssertFalse(defaultLocalizations.contains(where: { $0.key == "farewell" }), "Expected not to have a value for the key 'farewell'")
    }

    func test_EnglishLocalizationsForMissingSection() throws {
        let defaultLocalizations = try app.nstack.localize.get(section: "missing").wait()
        XCTAssertTrue(defaultLocalizations.count == 0, "Expected the `missing` section to have zero key-value pair")
    }

    func test_EnglishLocalizationWithTokenReplacement() throws {
        let localization = try app.nstack.localize.get(section: "test", key: "greeting", searchReplacePairs: ["name": "NStack"]).wait()
        XCTAssertEqual(localization, "Hello, NStack!", "Expected {name} to be replaced with NStack")
    }

    // Missing tests: test caching time and waiting time for not found errors and general errors
}
