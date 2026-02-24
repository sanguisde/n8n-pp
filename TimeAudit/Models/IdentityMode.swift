import Foundation

// MARK: - Identity Mode

/// Global app identity mode that changes all wording and gamification.
enum IdentityMode: String, Codable, CaseIterable, Identifiable {
    case standard
    case faith

    var id: String { rawValue }

    /// Display name for settings picker
    var displayName: String {
        switch self {
        case .standard: return "Standard"
        case .faith: return "Glaubens-Modus"
        }
    }

    /// Short description for settings
    var description: String {
        switch self {
        case .standard: return "Produktivitaets-fokussiert"
        case .faith: return "Glaubens- und Berufungs-fokussiert"
        }
    }
}
