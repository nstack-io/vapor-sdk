import Vapor

struct NStackLogger {
    let isEnabled: Bool
    private let logger: Logger

    init(isEnabled: Bool, logger: Logger) {
        self.isEnabled = isEnabled
        self.logger = logger
    }

    func log(message: Logger.Message, withLevel level: Logger.Level) {
        if isEnabled {
            logger.log(level: level, message)
        }
    }
}
