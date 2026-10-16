import Foundation
import Observation

enum MacAppLanguage: String, CaseIterable, Identifiable {
    case system
    case simplifiedChinese = "zh-Hans"
    case hongKongChinese = "zh-HK"
    case english = "en"

    var id: String { rawValue }

    func resolved(preferredLanguages: [String]) -> MacAppLanguage {
        guard self == .system else { return self }
        for language in preferredLanguages {
            let identifier = language.lowercased().replacingOccurrences(of: "_", with: "-")
            if identifier == "en" || identifier.hasPrefix("en-") {
                return .english
            }
            if identifier.hasPrefix("yue") || identifier.hasPrefix("zh-hant")
                || ["zh-hk", "zh-mo", "zh-tw"].contains(identifier) {
                return .hongKongChinese
            }
            if identifier == "zh" || identifier.hasPrefix("zh-hans")
                || ["zh-cn", "zh-sg"].contains(identifier) {
                return .simplifiedChinese
            }
        }
        return .english
    }

    var localeIdentifier: String {
        switch self {
        case .hongKongChinese: "zh_HK"
        case .english: "en_US"
        case .system, .simplifiedChinese: "zh_CN"
        }
    }
}

@MainActor
@Observable
final class MacLanguageSettings {
    static let shared = MacLanguageSettings()
    static let preferenceKey = "macInterfaceLanguage"

    var selection: MacAppLanguage {
        didSet { defaults.set(selection.rawValue, forKey: Self.preferenceKey) }
    }

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let preferredLanguages: [String]?
    @ObservationIgnored private let localizedBundles: [MacAppLanguage: Bundle]

    init(
        defaults: UserDefaults = .standard,
        resourceBundle: Bundle = .main,
        preferredLanguages: [String]? = nil
    ) {
        self.defaults = defaults
        self.preferredLanguages = preferredLanguages
        selection = defaults.string(forKey: Self.preferenceKey)
            .flatMap(MacAppLanguage.init(rawValue:)) ?? .system
        localizedBundles = Dictionary(uniqueKeysWithValues: MacAppLanguage.allCases.compactMap { language in
            guard language != .system,
                  let path = resourceBundle.path(forResource: language.rawValue, ofType: "lproj"),
                  let bundle = Bundle(path: path) else { return nil }
            return (language, bundle)
        })
    }

    var effectiveLanguage: MacAppLanguage {
        selection.resolved(preferredLanguages: preferredLanguages ?? Locale.preferredLanguages)
    }

    var locale: Locale { Locale(identifier: effectiveLanguage.localeIdentifier) }

    func localizedString(_ key: String) -> String {
        localizedBundles[effectiveLanguage]?.localizedString(forKey: key, value: key, table: nil) ?? key
    }
}

@MainActor
func macLocalized(_ key: String, _ arguments: CVarArg...) -> String {
    let settings = MacLanguageSettings.shared
    let format = settings.localizedString(key)
    guard !arguments.isEmpty else { return format }
    return String(format: format, locale: settings.locale, arguments: arguments)
}
