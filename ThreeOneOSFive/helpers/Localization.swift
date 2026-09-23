import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    static let storageKey = "appLanguage"

    case spanish = "es"
    case english = "en"
    case portuguese = "pt"
    case indonesian = "id"
    case french = "fr"
    case arabic = "ar"
    case russian = "ru"
    case thai = "th"
    case vietnamese = "vi"

    var id: String { rawValue }

    var locale: Locale {
        switch self {
        case .spanish: return Locale(identifier: "es")
        case .english: return Locale(identifier: "en")
        case .portuguese: return Locale(identifier: "pt-BR")
        case .indonesian: return Locale(identifier: "id")
        case .french: return Locale(identifier: "fr")
        case .arabic: return Locale(identifier: "ar")
        case .russian: return Locale(identifier: "ru")
        case .thai: return Locale(identifier: "th")
        case .vietnamese: return Locale(identifier: "vi")
        }
    }

    var nativeName: String {
        switch self {
        case .spanish: return "Español"
        case .english: return "English"
        case .portuguese: return "Português"
        case .indonesian: return "Bahasa Indonesia"
        case .french: return "Français"
        case .arabic: return "العربية"
        case .russian: return "Русский"
        case .thai: return "ไทย"
        case .vietnamese: return "Tiếng Việt"
        }
    }

    var regionLabel: String {
        switch self {
        case .spanish: return "ESPAÑA · LATINOAMÉRICA"
        case .english: return "UNITED STATES · INTERNATIONAL"
        case .portuguese: return "BRASIL · PORTUGAL"
        case .indonesian: return "INDONESIA"
        case .french: return "FRANCE · AFRIQUE"
        case .arabic: return "MENA"
        case .russian: return "RUSSIA · CIS"
        case .thai: return "THAILAND"
        case .vietnamese: return "VIETNAM"
        }
    }

    var codeLabel: String {
        rawValue.uppercased()
    }

    var displayName: String { nativeName }

    static func recommended() -> AppLanguage {
        let code = Locale.current.language.languageCode?.identifier.lowercased() ?? "en"
        if code.hasPrefix("es") { return .spanish }
        if code.hasPrefix("pt") { return .portuguese }
        if code.hasPrefix("id") || code == "in" { return .indonesian }
        if code.hasPrefix("fr") { return .french }
        if code.hasPrefix("ar") { return .arabic }
        if code.hasPrefix("ru") { return .russian }
        if code.hasPrefix("th") { return .thai }
        if code.hasPrefix("vi") { return .vietnamese }
        return .english
    }

    static var current: AppLanguage {
        AppLanguage(rawValue: UserDefaults.standard.string(forKey: storageKey) ?? "") ?? recommended()
    }

    func text(_ key: String) -> String {
        let local = localizedBundle.localizedString(forKey: key, value: nil, table: nil)
        if local != key { return local }
        guard let enPath = Bundle.main.path(forResource: "en", ofType: "lproj"),
              let english = Bundle(path: enPath) else {
            return key
        }
        return english.localizedString(forKey: key, value: key, table: nil)
    }

    func text(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: text(key), locale: locale, arguments: arguments)
    }

    private var localizedBundle: Bundle {
        guard let path = Bundle.main.path(forResource: rawValue, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return .main
        }
        return bundle
    }
}

private struct AppLanguageEnvironmentKey: EnvironmentKey {
    static let defaultValue = AppLanguage.recommended()
}

extension EnvironmentValues {
    var appLanguage: AppLanguage {
        get { self[AppLanguageEnvironmentKey.self] }
        set { self[AppLanguageEnvironmentKey.self] = newValue }
    }
}

extension ExploitStatus {
    func displayText(language: AppLanguage) -> String {
        switch self {
        case .notStarted:
            return language.text("status.not_attempted")
        case .success(let method):
            let localizedMethod = method == "Simulator preview"
                ? language.text("method.simulator_preview")
                : method
            return language.text("status.ok_via", localizedMethod)
        case .failed(let method, let code):
            return language.text("status.failed_via", method, code)
        case .unsupported(let message):
            return language.text("status.unsupported_reason", message)
        }
    }
}
