//
//  SoftwareUpdates.swift
//  SysKit
    

import Foundation


@MainActor
public struct SoftwareUpdatesInfo {
    static let shared = SoftwareUpdatesInfo()
    
    
    /// The build number of the previous update, if available.
    public let previousUpdateBuild: String
    
    
    /// The timestamp of the last system upgrade, if available.
    /// Expressed as a UNIX epoch (seconds since 1970).
    public let lastUpgradeTimestamp: Double?
    
    
    /// Holds the raw data from `com.apple.SoftwareUpdate.plist`.
    private let plist: SoftwareUpdates
    

    public init() {
        self.previousUpdateBuild  =          Self.powerlogdPlistValue(forKey: "PreviousUpdateBuild") ?? "N/A"
        self.lastUpgradeTimestamp =          Self.powerlogdPlistValue(forKey: "LastUpgradeSystemTimestamp")
        
        
        let plistPath = URL(fileURLWithPath: "/Library/Preferences/com.apple.SoftwareUpdate.plist")
        let plistData = try! Data(contentsOf: plistPath)
        let decoder = PropertyListDecoder()
        
        plist = try! decoder.decode(SoftwareUpdates.self, from: plistData)
    }
    
    
    
    public var recommendedUpdates: [SoftwareUpdates.Recommended] {
        plist.recommended
    }
    
    
    public var previousOffers: Dictionary<String, Date> {
        plist.previousOffers
    }
    
    
    /// The last time software updates were checked.
    public var lastCheck: Date {
        plist.lastSuccessfulCheck
    }
    
    
    public var automaticDownload: Bool {
        plist.automaticDownload
    }
    
    
    public var automaticallyInstallMacOSUpdates: Bool {
        plist.automaticallyInstallMacOSUpdates
    }
    
    
    public var criticalUpdateInstall: Bool {
        plist.criticalUpdateInstall
    }
    
    
    /// A string representation of the last system upgrade timestamp.
    /// Returns the date formatted as `yyyy-MM-dd HH:mm:ss`, or `nil` if unavailable.
    public var lastUpgradeTimeFormatted: String {
        guard let timestamp = lastUpgradeTimestamp else { return "N/A" }
        let date = Date(timeIntervalSince1970: timestamp)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: date)
    }
    
    
    private static func powerlogdPlistValue<T>(forKey key: String) -> T? {
        let plistPath = "/Library/Preferences/com.apple.powerlogd.plist"
        guard let dic = NSDictionary(contentsOfFile: plistPath) as? [String: Any]
        else { return nil }
        
        return dic[key] as? T
    }
}



// MARK: -  Structures

/// Represent the raw plist file for Software Updates hosted in /Library/Preferences dictionary
public struct SoftwareUpdates: Decodable {
    let recommended: [Recommended]
    let previousOffers: Dictionary<String, Date>
    let lastSuccessfulCheck: Date
    
    let automaticDownload: Bool
    let criticalUpdateInstall: Bool
    let automaticallyInstallMacOSUpdates: Bool

    
    
    enum CodingKeys: String, CodingKey {
        case recommended = "RecommendedUpdates"
        case previousOffers = "FirstOfferDateDictionary"
        case lastSuccessfulCheck = "LastSuccessfulDate"
        
        case automaticDownload = "AutomaticDownload"
        case criticalUpdateInstall = "CriticalUpdateInstall"
        case automaticallyInstallMacOSUpdates = "AutomaticallyInstallMacOSUpdates"
    }

    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        recommended = try container.decode([Recommended].self, forKey: .recommended)
        previousOffers = try container.decode(Dictionary<String, Date>.self, forKey: .previousOffers)
        lastSuccessfulCheck = try container.decode(Date.self, forKey: .lastSuccessfulCheck)
        
        /*
         I've assigned default values for those properties because they will not appearing in the .plist file
         before making any changes from the settings app
         the default values is the true values that macOS configures for all mac machines by default.
         */
        automaticDownload = try container.decodeIfPresent(Bool.self, forKey: .automaticDownload) ?? true
        criticalUpdateInstall = try container.decodeIfPresent(Bool.self, forKey: .criticalUpdateInstall) ?? true
        automaticallyInstallMacOSUpdates = try container.decodeIfPresent(Bool.self, forKey: .automaticallyInstallMacOSUpdates) ?? false
    }
}

public extension SoftwareUpdates {
    struct Recommended: Decodable {
        public let identifier: String
        public let displayName: String
        public let productKey: String
        public let displayVersion: String
        
        enum CodingKeys: String, CodingKey {
            case identifier = "Identifier"
            case displayName = "Display Name"
            case productKey = "Product Key"
            case displayVersion = "Display Version"
        }
        
        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.identifier = try container.decode(String.self, forKey: .identifier)
            self.displayName = try container.decode(String.self, forKey: .displayName)
            self.productKey = try container.decode(String.self, forKey: .productKey)
            self.displayVersion = try container.decode(String.self, forKey: .displayVersion)
        }
    }
}
