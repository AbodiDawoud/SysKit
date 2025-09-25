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
    
    
    /// A Boolean value indicating whether the OS is a beta release.
    public let isBeta: Bool
    
    
    /// A Boolean value indicating whether the OS is an internal (Apple-only) build.
    public let isInternal: Bool
    
    
    /// A boolean value indicating whether the system is running in a virtual machine.
    public let isVirtualMachine: Bool
    
    
    /// Provides useful information about pending and applied software updates.
    public let softwareUpdates: SoftwareUpdatesInfo
    
    
    
    public init() {
        let platform = MacOS.sharedPlatformInfo()

        self.osTitleString =         platform.value(forKey: "osTitleString") as! String
        self.osVersionString =       platform.value(forKey: "osVersionString") as! String
        self.osBuildString =         platform.value(forKey: "osBuildString") as! String
        
        
        let AFUtilities   =          NSClassFromString("AFUtilities") as! NSObject.Type
        let AAFDeviceInfo =          NSClassFromString("AAFDeviceInfo") as! NSObject.Type
        
        self.isBeta =                platform.value(forKey: "isBeta") as! Bool
        self.isInternal =            AFUtilities.value(forKey: "isInternalBuild") as! Bool
        self.isVirtualMachine =      AAFDeviceInfo.value(forKey: "isVirtualMachine") as! Bool

        self.softwareUpdates =       SoftwareUpdatesInfo()
    }

    
    /// An icon image representing the current macOS system.
    public var osIcon: Image {
        Image(
            "AboutThisMacRoundel",
            bundle: .init(identifier: "com.apple.preferences.SystemDesktopAppearance")!,
        )
    }
    
    
    /// Opens the Software Update settings in System Settings.
    public func launchSoftwareUpdate() {
        let url = URL(string: "x-apple.systempreferences:com.apple.Software-Update-Settings.extension")!
        NSWorkspace.shared.open(url)
    }
}
