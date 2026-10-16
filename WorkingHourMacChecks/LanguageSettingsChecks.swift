import Foundation
import Observation

private final class ObservationFlag: @unchecked Sendable {
    private let lock = NSLock()
    private var changed = false

    func markChanged() { lock.withLock { changed = true } }
    var value: Bool { lock.withLock { changed } }
}

// Run against the built app so these checks validate the shipped .lproj resources.
@main
struct LanguageSettingsChecks {
    @MainActor
    static func main() throws {
        guard CommandLine.arguments.count == 2,
              let bundle = Bundle(path: CommandLine.arguments[1]) else {
            fatalError("Pass the built Working Hour Mac.app path")
        }
        let suiteName = "WorkingHourMac.LanguageChecks.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        var checks = 0
        func expect(_ condition: @autoclosure () -> Bool, _ description: String) {
            precondition(condition(), description)
            checks += 1
        }

        let settings = MacLanguageSettings(
            defaults: defaults, resourceBundle: bundle, preferredLanguages: ["zh-Hans-CN"]
        )
        expect(settings.selection == .system, "First launch follows system")
        expect(settings.localizedString("今天") == "今天", "Simplified system uses Simplified text")
        let observedChange = ObservationFlag()
        withObservationTracking {
            _ = settings.localizedString("今天")
        } onChange: {
            observedChange.markChanged()
        }
        settings.selection = .hongKongChinese
        expect(observedChange.value, "Language change invalidates an observed view translation")
        expect(settings.localizedString("今天") == "今日", "Existing settings switch without restart")
        expect(settings.localizedString("语言") == "語言", "Language control translates itself")
        expect(settings.localizedString("刷新") == "重新整理", "Toolbar actions switch language")
        expect(settings.locale.identifier == "zh_HK", "Hong Kong formatting follows selection")
        expect(
            String(format: settings.localizedString("共 %lld 条记录"), locale: settings.locale, 12) == "共 12 項記錄",
            "Interpolated record counts use the selected language"
        )
        let relaunched = MacLanguageSettings(
            defaults: defaults, resourceBundle: bundle, preferredLanguages: ["zh-Hans-CN"]
        )
        expect(relaunched.selection == .hongKongChinese, "Choice persists across settings recreation")
        expect(relaunched.localizedString("今天") == "今日", "Persisted choice overrides system language")
        settings.selection = .simplifiedChinese
        expect(settings.localizedString("今天") == "今天", "Can switch back to Simplified")
        expect(settings.localizedString("刷新") == "刷新", "Toolbar switches back without cached translations")
        settings.selection = .english
        expect(settings.localizedString("今天") == "Today", "English uses the shipped English translation")
        expect(settings.localizedString("语言") == "Language", "English language control")
        expect(settings.localizedString("刷新") == "Refresh", "English toolbar action")
        expect(settings.localizedString("共 1 条记录") == "1 record", "English singular record count")
        expect(settings.localizedString("本机存储") == "Local storage", "Storage label reflects the local release")
        expect(settings.locale.identifier == "en_US", "English date/time formatting")
        expect(
            String(format: settings.localizedString("共 %lld 条记录"), locale: settings.locale, 12) == "12 records",
            "English interpolated record count"
        )
        let englishRelaunched = MacLanguageSettings(defaults: defaults, resourceBundle: bundle, preferredLanguages: ["zh-HK"])
        expect(englishRelaunched.selection == .english, "English preference persists")
        expect(englishRelaunched.localizedString("今天") == "Today", "Saved English choice overrides Hong Kong system")
        expect(settings.localizedString("Missing translation key") == "Missing translation key", "Missing keys remain readable")
        settings.selection = .system
        expect(settings.localizedString("今天") == "今天", "Following system removes the in-app override")
        expect(MacAppLanguage.system.resolved(preferredLanguages: ["zh-Hant-HK"]) == .hongKongChinese, "Traditional Hong Kong system")
        expect(MacAppLanguage.system.resolved(preferredLanguages: ["yue-Hant-HK"]) == .hongKongChinese, "Cantonese system")
        expect(MacAppLanguage.system.resolved(preferredLanguages: ["fr-FR", "zh-Hant-TW"]) == .hongKongChinese, "Preferred supported language fallback")
        expect(MacAppLanguage.system.resolved(preferredLanguages: ["en-GB", "zh-HK"]) == .english, "English system language takes priority")
        expect(MacAppLanguage.system.resolved(preferredLanguages: ["fr-FR"]) == .english, "Unsupported language falls back to English")
        expect(MacAppLanguage.simplifiedChinese.resolved(preferredLanguages: ["zh-HK"]) == .simplifiedChinese, "Explicit selection takes priority")
        defaults.set("unknown-future-language", forKey: MacLanguageSettings.preferenceKey)
        let recovered = MacLanguageSettings(defaults: defaults, resourceBundle: bundle, preferredLanguages: ["zh-HK"])
        expect(recovered.selection == .system, "Invalid saved preferences fall back safely")
        expect(recovered.localizedString("今天") == "今日", "Recovered preference still follows system")
        var referenceKeys: Set<String>?
        for language in ["zh-Hans", "zh-HK", "en"] {
            let path = bundle.path(forResource: language, ofType: "lproj")!
            let table = NSDictionary(contentsOfFile: path + "/Localizable.strings") as! [String: String]
            if let referenceKeys {
                expect(Set(table.keys) == referenceKeys, "All languages ship the same translation keys")
            } else {
                referenceKeys = Set(table.keys)
            }
            for key in ["语言", "切换界面语言", "跟随系统", "语言更改会立即生效，并在下次启动时保留。", "共 %lld 条记录"] {
                expect(table[key] != nil, "Shipped \(language) resource includes \(key)")
            }
        }
        print("Language settings checks passed: \(checks)")
    }
}
