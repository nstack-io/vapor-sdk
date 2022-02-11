import Foundation

struct Localization: Codable {
    typealias Section = String
    typealias Key = String
    typealias Translation = String
    typealias LocalizationFormat = [Section: [Key: Translation]]

    let localizations: LocalizationFormat
    let platform: LocalizationPlatform
    let language: String
    let date: Date

    init(
        localizations: LocalizationFormat,
        platform: LocalizationPlatform,
        language: String,
        date: Date = Date()
    ) {
        self.localizations = localizations
        self.platform = platform
        self.language = language
        self.date = date
    }

    func isOutdated(logger: NStackLogger, _ cacheInMinutes: Int) -> Bool {
        let cacheInSeconds: TimeInterval = Double(cacheInMinutes) * 60
        let expirationDate: Date = self.date.addingTimeInterval(cacheInSeconds)

        logger.log(
            message: "Expiration of current cache is: \(expirationDate), current time is: \(Date())",
            withLevel: .info
        )
        return expirationDate.compare(Date()) == .orderedAscending
    }

    func get(logger: NStackLogger, section: Section, key: Key) -> Translation {
        guard let translation = localizations[section]?[key] else {
            logger.log(
                message: "No translation found for section '\(section)' and key '\(key)'",
                withLevel: .info
            )
            return Localization.fallback(section: section, key: key)
        }
        return translation
    }

    func get(logger: NStackLogger, section: Section) -> [Key: Translation] {
        guard let sectionTranslations = localizations[section] else {
            logger.log(
                message: "No translation found for section '\(section)'",
                withLevel: .info
            )
            return Localization.fallback(section: section)
        }
        return sectionTranslations
    }

    static func fallback(section: Section, key: Key) -> Translation {
        return section + "." + key
    }

    static func fallback(section: Section) -> [Key: Translation] {
        return [:]
    }
}
