import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    static let storageKey = "appLanguage"

    case spanish = "es"
    case english = "en"
    case portuguese = "pt"

    var id: String { rawValue }

    var locale: Locale {
        switch self {
        case .spanish: return Locale(identifier: "es")
        case .english: return Locale(identifier: "en")
        case .portuguese: return Locale(identifier: "pt-BR")
        }
    }

    var nativeName: String {
        switch self {
        case .spanish: return "Español"
        case .english: return "English"
        case .portuguese: return "Português"
        }
    }

    var regionLabel: String {
        switch self {
        case .spanish: return "ESPAÑA · LATINOAMÉRICA"
        case .english: return "UNITED STATES · INTERNATIONAL"
        case .portuguese: return "BRASIL · PORTUGAL"
        }
    }

    var codeLabel: String {
        switch self {
        case .spanish: return "ES"
        case .english: return "EN"
        case .portuguese: return "PT"
        }
    }

    var displayName: String { nativeName }

    static func recommended() -> AppLanguage {
        let code = Locale.current.language.languageCode?.identifier.lowercased() ?? "en"
        if code.hasPrefix("es") { return .spanish }
        if code.hasPrefix("pt") { return .portuguese }
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
    static let defaultValue = AppLanguage.spanish
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
