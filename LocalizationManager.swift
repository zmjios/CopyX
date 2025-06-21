// ... existing code ...
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

// MARK: - LocalizationManager
class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()

    enum Language: String, CaseIterable, Identifiable {
        case auto = "auto"
        case en = "en"
        case zhHans = "zh-Hans"

        var id: String { self.rawValue }

        var displayName: String {
            switch self {
            case .auto: return "language_auto".localized
            case .en: return "language_en".localized
            case .zhHans: return "language_zh_hans".localized
            }
        }
    }

    @Published var language: Language {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: "selectedLanguage")
            self.revision += 1
        }
    }

    @Published var revision: Int = 0
    private var bundle: Bundle?

    private init() {
        let savedLang = UserDefaults.standard.string(forKey: "selectedLanguage") ?? "auto"
        self.language = Language(rawValue: savedLang) ?? .auto
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(systemLocaleDidChange),
            name: NSLocale.currentLocaleDidChangeNotification,
            object: nil
        )
        print("🌍 LocalizationManager initialized, language: \(self.language.rawValue)")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func systemLocaleDidChange() {
        if language == .auto {
            print("🌍 System locale changed, triggering UI update via revision.")
            self.revision += 1
        }
    }
    
    func setLanguage(_ language: Language) {
        self.language = language
    }

    func localizedString(forKey key: String) -> String {
        let effectiveLanguage: Language
        
        let preferred = Locale.preferredLanguages.first ?? "en"
        print("--- Translating key: '\(key)' ---")
        print("   - Current setting: \(language.rawValue)")
        print("   - System preferred: \(preferred)")
        
        if language == .auto {
            if preferred.starts(with: "zh") {
                effectiveLanguage = .zhHans
                print("   - Mode: auto. Detected: Chinese. Using: zh-Hans")
            } else {
                effectiveLanguage = .en
                print("   - Mode: auto. Detected: non-Chinese. Using: en")
            }
        } else {
            effectiveLanguage = language
            print("   - Mode: manual. Using: \(language.rawValue)")
        }
        
        guard let path = Bundle.main.path(forResource: effectiveLanguage.rawValue, ofType: "lproj") else {
            print("   - ❌ BUNDLE NOT FOUND for lang: \(effectiveLanguage.rawValue)")
            if let englishPath = Bundle.main.path(forResource: "en", ofType: "lproj"),
               let englishBundle = Bundle(path: englishPath) {
                print("   - ✅ Falling back to English bundle.")
                return englishBundle.localizedString(forKey: key, value: key, table: nil)
            }
            print("   - ❌ English fallback bundle also not found. Returning key.")
            return key
        }
        
        guard let bundle = Bundle(path: path) else {
            print("   - ❌ Could not load bundle from path: \(path)")
            return key
        }
        
        print("   - ✅ Successfully loaded bundle for: \(effectiveLanguage.rawValue)")
        let translatedString = bundle.localizedString(forKey: key, value: key, table: nil)
        print("   - Result: '\(translatedString)'")
        return translatedString
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
