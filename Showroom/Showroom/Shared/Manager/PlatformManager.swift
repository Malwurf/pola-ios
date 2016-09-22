import Foundation
import RxSwift

extension Platform {
    var locale: NSLocale {
        return NSLocale(localeIdentifier: self.nsLocaleIdentifier)
    }
    
    private var nsLocaleIdentifier: String {
        switch self {
        case Polish: return "pl"
        case German: return "de"
        }
    }
    
    var languageCode: String {
        switch self {
        case Polish: return "pl"
        case German: return "de"
        }
    }
    
    var currencyCode: String {
        switch self {
        case Polish: return "PLN"
        case German: return "EUR"
        }
    }
}

final class PlatformManager {
    private static let platformCodeKey = "PlatformCodeKey"
    private let storage: KeyValueStorage
    private let api: ApiService
    private(set) var availablePlatforms: [Platform] = Platform.allValues

    private(set) var shouldSkipPlatformSelection: Bool {
        get {
            return storage.load(forKey: "shouldSkipPlatformSelectionView") ?? false
        }
        set {
            storage.save(newValue, forKey: "shouldSkipPlatformSelectionView")
        }
    }
    
    init(keyValueStorage: KeyValueStorage, api: ApiService) {
        self.storage = keyValueStorage
        self.api = api
        
        if let platform = platform {
            api.configuration = ApiServiceConfiguration(platform: platform)
        }
    }
    
    let platformObservable = PublishSubject<Platform>()
    
    var platform: Platform? {
        set {
            guard let newValue = newValue else {
                logError("Tried to set platform to nil")
                return
            }
            storage.clear(forType: .Cache)
            storage.clear(forType: .Persistent)
            
            if storage.save(newValue.code, forKey: PlatformManager.platformCodeKey) {
                logInfo("Did set app platform: \(newValue) to user defaults")
                shouldSkipPlatformSelection = true
            } else {
                logError("Failed to set app platform \(newValue) to user defaults")
            }
            api.configuration = ApiServiceConfiguration(platform: newValue)
            platformObservable.onNext(newValue)
        }
        get {
            guard let platformCode: String = storage.load(forKey: PlatformManager.platformCodeKey) else {
                logError("Could not find language code in user defaults for key: \(PlatformManager.platformCodeKey)")
                return nil
            }
            guard let platform = Platform(code: platformCode) else {
                logError("No available platform with code: \(platformCode)")
                return nil
            }
            return platform
        }
    }
}

// MARK:- Utils

extension PlatformManager {
    var webpageUrl: NSURL? {
        guard let platform = platform else { return nil }
        
        if Constants.isStagingEnv {
            return NSURL(string: "https://\(platform.code).test.shwrm.net")
        } else {
            return NSURL(string: "https://www.showroom.\(platform.code)")
        }
    }
    
    var reportEmail: String? {
        guard let platform = platform else { return nil }
        
        if Constants.isAppStore {
            return "iosv\(NSBundle.appVersionNumber)@showroom.\(platform.code)"
        } else {
            return "iosv1.1@showroom.\(platform.code)"
        }
    }
    
    func initializePlatformWithDeviceLanguage() {
        if !shouldSkipPlatformSelection {
            let deviceLanguageCode = NSLocale.currentLocale().languageCode
            logInfo("Trying to find available app platform matching the device language with languageCode: \(deviceLanguageCode)")
            
            if let matchingAvailableLanguage = availablePlatforms.find({ $0.languageCode == deviceLanguageCode }) {
                platform = matchingAvailableLanguage
                shouldSkipPlatformSelection = true
            }
        }
    }
    
    func translation(forKey key: String) -> String? {
        guard let languageCode = platform?.languageCode else { return nil }
        let budleType = "lproj"
        guard let bundlePath = NSBundle.mainBundle().pathForResource(languageCode, ofType: budleType) else {
            logError("Could not find bundle path for resource: \(languageCode).\(budleType)")
            return nil
        }
        guard let languageBundle = NSBundle(path: bundlePath) else {
            logError("Could not find bundle with path: \(bundlePath)")
            return nil
        }
        let translatedString = languageBundle.localizedStringForKey(key, value: "", table: nil)
        guard !translatedString.isEmpty else {
            logError("No localizable string file for the selected language")
            return nil
        }
        return translatedString
    }
}