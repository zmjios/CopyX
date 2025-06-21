import Foundation
import SwiftUI

// MARK: - LocalizationManager
class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()

    // A single, complete definition for all supported languages, nested inside the manager.
    enum Language: String, CaseIterable, Identifiable {
        case auto = "auto"
        case en = "en"
        case zh = "zh-Hans"
        case de = "de"
        case fr = "fr"
        case es = "es"
        case ja = "ja"

        var id: String { self.rawValue }

        var localizedName: String {
            switch self {
            case .auto:
                return "language_auto".localized
            case .en:
                return "language_en".localized
            case .zh:
                return "language_zh_hans".localized
            case .de:
                return "language_de".localized
            case .fr:
                return "language_fr".localized
            case .es:
                return "language_es".localized
            case .ja:
                return "language_ja".localized
            }
        }
    }

    @Published var language: Language {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: "selectedLanguage")
            // Manually trigger UI updates on language change
            self.revision += 1
        }
    }

    @Published var revision: Int = 0

    private init() {
        let savedLang = UserDefaults.standard.string(forKey: "selectedLanguage") ?? "auto"
        self.language = Language(rawValue: savedLang) ?? .auto
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(systemLocaleDidChange),
            name: NSLocale.currentLocaleDidChangeNotification,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func systemLocaleDidChange() {
        if language == .auto {
            DispatchQueue.main.async {
                self.revision += 1
            }
        }
    }
    
    func setLanguage(_ language: Language) {
         DispatchQueue.main.async {
            self.language = language
        }
    }

    func localizedString(forKey key: String) -> String {
        let targetLanguageCode: String
        
        if self.language == .auto {
            // In "auto" mode, find the best supported language based on the user's system preferences.
            let supportedCodes = Language.allCases.map { $0.rawValue }.filter { $0 != "auto" }
            let preferredCode = Bundle.preferredLocalizations(from: supportedCodes, forPreferences: Locale.preferredLanguages).first ?? "en"
            targetLanguageCode = preferredCode
        } else {
            // In manual mode, use the selected language's raw value.
            targetLanguageCode = self.language.rawValue
        }
        
//        print("🔍 Localizing key '\(key)' for lang: \(targetLanguageCode)")
        
        guard let path = Bundle.main.path(forResource: targetLanguageCode, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            print("❌ BUNDLE NOT FOUND for lang: \(targetLanguageCode). Falling back to English.")
            // If the desired bundle doesn't exist, fall back to the English bundle.
            guard let fallbackPath = Bundle.main.path(forResource: "en", ofType: "lproj"),
                  let fallbackBundle = Bundle(path: fallbackPath) else {
                // If even the English bundle is missing, just return the key.
                print("❌❌ FALLBACK BUNDLE 'en' NOT FOUND. Returning key.")
                return key
            }
            return fallbackBundle.localizedString(forKey: key, value: key, table: nil)
        }
        
        // Load the bundle and return the localized string.
        // print("✅ Bundle found. Localizing '\(key)'.")
        return bundle.localizedString(forKey: key, value: key, table: nil)
    }
}

// MARK: - String Extension for Localization
extension String {
    var localized: String {
        return LocalizationManager.shared.localizedString(forKey: self)
    }
}

// MARK: - LocalizedText View
struct LocalizedText: View {
    let key: String
    
    @EnvironmentObject private var localizationManager: LocalizationManager
    
    init(_ key: String) {
        self.key = key
    }
    
    var body: some View {
        Text(localizationManager.localizedString(forKey: key))
    }
}
