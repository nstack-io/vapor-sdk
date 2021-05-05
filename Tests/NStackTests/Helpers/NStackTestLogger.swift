import Vapor

class NStackTestLogger: LogHandler {
    func get(loggerName: String) -> NStackTestLogger {
        self
    }

    func log(
        level: Logger.Level,
        message: Logger.Message,
        metadata: Logger.Metadata?,
        source: String,
        file: String,
        function: String,
        line: UInt
    ) {
        logs.append("[\(level.name)] \(message)")
    }

    subscript(metadataKey metadataKey: String) -> Logger.Metadata.Value? {
        get {
            return self[metadataKey: metadataKey]
        }
        set(newValue) {
            self[metadataKey: metadataKey] = newValue
        }
    }

    var metadata: Logger.Metadata

    var logLevel: Logger.Level

    var logs = [String]()

    init() {
        metadata = [:]
        logLevel = .info
    }
}
