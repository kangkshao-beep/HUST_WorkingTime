import SwiftUI

struct MacLanguagePicker: View {
    @State private var settings = MacLanguageSettings.shared

    var body: some View {
        Picker(macLocalized("语言"), selection: $settings.selection) {
            Text(macLocalized("跟随系统")).tag(MacAppLanguage.system)
            Text(verbatim: "简体中文").tag(MacAppLanguage.simplifiedChinese)
            Text(verbatim: "繁體中文（香港）").tag(MacAppLanguage.hongKongChinese)
            Text(verbatim: "English").tag(MacAppLanguage.english)
        }
        .accessibilityIdentifier("interfaceLanguagePicker")
    }
}

struct MacLanguageSettingsView: View {
    @State private var settings = MacLanguageSettings.shared

    var body: some View {
        Form {
            MacLanguagePicker()
            Text(macLocalized("语言更改会立即生效，并在下次启动时保留。"))
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(width: 400)
        .environment(\.locale, settings.locale)
    }
}
