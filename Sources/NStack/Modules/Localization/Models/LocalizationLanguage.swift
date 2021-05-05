struct LocalizationLanguage: Decodable {
    let id: Int
    let name: String
    let locale: String
    let direction: String
    let isDefault: Bool
    let isBestFit: Bool
}
