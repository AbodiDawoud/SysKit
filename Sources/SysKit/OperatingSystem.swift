//
//  OperatingSystemInfo.swift
//  SysKit


import SwiftUI


/// A structure that provides information about the currently installed macOS system
public struct OperatingSystemInfo {
    /// The human-readable name of the OS (e.g., "macOS Sequoia").
    public let osTitleString: String
    
    
    /// The version string of the OS (e.g., "15.0").
    public let osVersionString: String
    
    
    /// The build number of the OS (e.g., "24A335").
    public let osBuildString: String
    
    
    /// The build number of the previous update, if available.
    public let previousUpdateBuild: String?
    
    
    /// The timestamp of the last system upgrade, if available.
    /// Expressed as a UNIX epoch (seconds since 1970).
    public let lastUpgradeSystemTimestamp: Double?
    
    
    /// The date of the last successful software update check.
    public let lastSuccessfulCheck: Date
    
    
    /// A Boolean value indicating whether the OS is a beta release.
    public let isBeta: Bool
    
    
    /// A Boolean value indicating whether the OS is an internal (Apple-only) build.
    public let isInternal: Bool
    
    
    /// A boolean value indicating whether the system is running in a virtual machine.
    public let isVirtualMachine: Bool
    
    
    public init() {
        let platform = MacOS.sharedPlatformInfo()

        self.osTitleString =        platform.value(forKey: "osTitleString") as! String
        self.osVersionString =      platform.value(forKey: "osVersionString") as! String
        self.osBuildString =        platform.value(forKey: "osBuildString") as! String

        self.previousUpdateBuild =          Self.powerlogdPlistValue(forKey: "PreviousUpdateBuild")
        self.lastUpgradeSystemTimestamp =   Self.powerlogdPlistValue(forKey: "LastUpgradeSystemTimestamp")
        
        
        let suPlist = Self.softwareUpdatedPlist()
        self.lastSuccessfulCheck = suPlist["LastSuccessfulDate"] as! Date
        
        
        let AFUtilities   =          NSClassFromString("AFUtilities") as! NSObject.Type
        let AAFDeviceInfo =          NSClassFromString("AAFDeviceInfo") as! NSObject.Type
        
        self.isBeta =              platform.value(forKey: "isBeta") as! Bool
        self.isInternal =          AFUtilities.value(forKey: "isInternalBuild") as! Bool
        self.isVirtualMachine =    AAFDeviceInfo.value(forKey: "isVirtualMachine") as! Bool
    }

    
    /// An icon image representing the current macOS system.
    public var osIcon: Image {
        Image(
            "AboutThisMacRoundel",
            bundle: .init(identifier: "com.apple.preferences.SystemDesktopAppearance")!,
        )
    }
    
    
    /// A string representation of the last system upgrade timestamp.
    /// Returns the date formatted as `yyyy-MM-dd HH:mm:ss`, or `nil` if unavailable.
    public var lastUpgradeSystemFormatted: String? {
        guard let timestamp = lastUpgradeSystemTimestamp else { return nil }
        let date = Date(timeIntervalSince1970: timestamp)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: date)
    }
    
    
    /// Opens the Software Update settings in System Settings.
    public func launchSoftwareUpdate() {
        let url = URL(string: "x-apple.systempreferences:com.apple.Software-Update-Settings.extension")!
        NSWorkspace.shared.open(url)
    }
}


private extension OperatingSystemInfo {
    private static func powerlogdPlistValue<T>(forKey key: String) -> T? {
        let plistPath = "/Library/Preferences/com.apple.powerlogd.plist"
        guard let dic = NSDictionary(contentsOfFile: plistPath) as? [String: Any]
        else { return nil }
        
        return dic[key] as? T
    }
    
    private static func softwareUpdatedPlist() -> NSDictionary {
        let plistPath = "/Library/Preferences/com.apple.SoftwareUpdate.plist"
        return NSDictionary(contentsOfFile: plistPath)!
    }
}


