//
//  SecurityInfo.swift
//  SysKit


import Foundation
import AppKit


/// Provides information about the security configuration of the current macOS system.
@MainActor
public struct SecurityInfo {
    public init() {}
    
    
    /// Indicates whether **System Integrity Protection (SIP)** is enabled.
    ///
    /// SIP protects critical system files and processes from being modified,
    /// even by the root user. It’s typically enabled on modern macOS installations.
    public var sipEnabled: Bool { isSIPEenabled() }
    
    /// Indicates whether **Gatekeeper** is enabled.
    ///
    /// Gatekeeper helps protect users from running untrusted apps by verifying
    /// that downloaded apps are signed and meet Apple’s security requirements.
    /// If disabled, apps from any source can run without checks.
    public var gatekeeperEnabled: Bool { isGatekeeperEnabled() }
    
    
    /// Indicates whether **FileVault** disk encryption is enabled.
    ///
    /// FileVault encrypts the startup disk to protect data at rest.
    /// When enabled, the entire disk requires authentication at boot to be accessed.
    public var fileVaultEnabled: Bool { isFileVaultEnabled() }
    
    
    /// The configured policy for which app sources are allowed on this Mac.
    ///
    /// Possible values include:
    /// - `.appStoreOnly` – only apps from the Mac App Store
    /// - `.appStoreAndIdentifiedDevelopers` – apps from the Mac App Store and identified developers
    /// - `.anywhere` – apps from any source (Gatekeeper disabled)
    /// - `.unknown` – could not determine the setting
    public var allowedAppSources: String { getAllowedAppSources().rawValue }
    
    
    /// Indicates whether **Find My Mac** is enabled.
    ///
    /// When enabled, this feature helps locate and protect your Mac if it’s lost or stolen.
    public var findMeEnabled: Bool { isFindMeEnabled() }
    
    
    /// Indicates whether the macOS Firewall is enabled.
    public var firewallEnabled: Bool { isFirewallEnabled() }
    
    
    /// Opens the **Security & Privacy** section of System Settings.
    public func openSecurityPref() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security")!
        NSWorkspace.shared.open(url)
    }
}


// Private methods
private extension SecurityInfo {
    private func isSIPEenabled() -> Bool {
        let process = Process()
        process.launchPath = "/usr/bin/env"
        process.arguments = ["csrutil", "status"]

        let pipe = Pipe()
        process.standardOutput = pipe
        try? process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: data, encoding: .utf8) {
            return output.contains("enabled")
        }
        return false
    }
    
    private func isGatekeeperEnabled() -> Bool {
        let process = Process()
        process.launchPath = "/usr/sbin/spctl"
        process.arguments = ["--status"]

        let pipe = Pipe()
        process.standardOutput = pipe
        try? process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: data, encoding: .utf8) {
            return output.contains("assessments enabled")
        }
        return false
    }
    
    private func isFileVaultEnabled() -> Bool {
        let process = Process()
        process.launchPath = "/usr/bin/fdesetup"
        process.arguments = ["status"]

        let pipe = Pipe()
        process.standardOutput = pipe
        try? process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: data, encoding: .utf8) {
            return output.contains("FileVault is On")
        }
        return false
    }
    
    private func getAllowedAppSources() -> SecurityInfo.AllowedAppSources {
        let process = Process()
        process.launchPath = "/usr/sbin/spctl"
        process.arguments = ["--status", "--verbose"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        try? process.run()
        process.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8)
        else { return .unknown }
            
        if output.contains("assessments disabled") {
            return .anywhere
        } else if output.contains("developer id enabled") {
            return .appStoreAndIdentifiedDevelopers
        } else if output.contains("developer id disabled") {
            return .appStoreOnly
        } else {
            return .unknown
        }
    }
    
    private func isFindMeEnabled() -> Bool {
        let path = "/Library/Preferences/com.apple.FindMyMac.plist"
        guard let plist = NSDictionary(contentsOfFile: path) as? [String: Any],
            let isEnabled = plist["FMMEnabled"] as? Int
        else { return false }
        
        return isEnabled == 1
    }
    
    private func isFirewallEnabled() -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/libexec/ApplicationFirewall/socketfilterfw")
        process.arguments = ["--getglobalstate"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return false
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else { return false }

        // Example output: "Firewall is enabled. (State = 1)"
        return output.contains("enabled") || output.contains("State = 1")
    }
}


public extension SecurityInfo {
    enum AllowedAppSources: String {
        /// Only applications from the Mac App Store are allowed.
        case appStoreOnly = "App Store"
        
        /// Applications from the Mac App Store and apps signed by identified developers are allowed.
        case appStoreAndIdentifiedDevelopers = "App Store and Trusted Developers"
        
        /// Applications from any source are allowed (Gatekeeper is disabled).
        case anywhere = "Anywhere"
        
        /// The current state could not be determined.
        case unknown = "Unknown"
    }
}
