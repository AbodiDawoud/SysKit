//
//  MacOS.swift
//  SysKit
    

import AppKit


public struct MacOS {
    /// The human-readable Mac model name (e.g., "MacBook Pro").
    public let macModelName: String
    
    
    /// Additional model details.
    ///
    /// Example: "13-inch, M3, 2024"
    public let macModelDetails: String
    
    
    /// Processor or chip description.
    ///
    /// Example: "Apple M1 Pro" or "Intel Core i7"
    public let chip: String
    
    
    /// Installed memory size as a string (eg., "16 GB")
    public let memory: String
    
    
    /// The logic board identifier for this Mac.
    public let boardID: String
    
    
    /// Regulatory identifier associated with the device.
    public let regulatoryID: String
    
    
    /// The device serial number string.
    public let serialString: String
    
    
    /// Configuration code for this Mac model/configuration.
    public let configCode: String
    
    
    /// Indicates whether the Mac has user-upgradable memory.
    public let hasUpgradableMemory: Bool

    
    
    public init() {
        let platform = Self.sharedPlatformInfo()
        
        self.macModelName =         platform.value(forKey: "macModelName") as! String
        self.macModelDetails =      platform.value(forKey: "macModelDetails") as? String ?? "N/A"
        self.chip =                 platform.value(forKey: "processorString") as! String
        self.memory =               platform.value(forKey: "installedMemorySize") as! String
        
        self.boardID =              platform.value(forKey: "boardID") as? String ?? "N/A"
        self.serialString =         platform.value(forKey: "serialString") as? String ?? "N/A"
        self.regulatoryID =         platform.value(forKey: "regulatoryID") as? String ?? "N/A"
        
        self.configCode =           platform.value(forKey: "configCode") as? String ?? "N/A"
        self.hasUpgradableMemory =  platform.value(forKey: "hasUpgradableMemory") as? Bool ?? false
    }
    
    
    /// The machine model identifier (eg., "MacBookPro12,1")
    public var modelIdentifier: String {
        return sysctlValue("hw.model")
    }
    
    
    /// The macOS kernel version string (eg., "Darwin 23.0.0")
    public var kernelVersion: String {
        return "\(sysctlValue("kern.ostype")) \(sysctlValue("kern.osrelease"))"
    }
    
    
    /// The system uptime as a formatted string.
    ///
    /// Example: 4 hours, 10 minutes
    public var formattedSystemUptime: String {
        let uptime = ProcessInfo.processInfo.systemUptime
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day, .hour, .minute]
        formatter.unitsStyle = .full  // or .abbreviated for short style
        return formatter.string(from: uptime) ?? "N/A"
    }
    
    
    /// Opens the **About This Mac** app in new window.
    public func launchAboutThisMac() {
        let appPath = "/System/Library/CoreServices/Applications/About This Mac.app"
        NSWorkspace.shared.open(
            URL(filePath: appPath)
        )
    }
}

extension MacOS {
    internal static func sharedPlatformInfo() -> NSObject {
        let frameworkPath = "/System/Library/PrivateFrameworks/AboutSettings.framework/AboutSettings"
        let handler = dlopen(frameworkPath, RTLD_NOW)
        defer { dlclose(handler) }
        
        
        let class_name = "ASPlatformInfo"
        let ASPlatformInfo = NSClassFromString(class_name) as! NSObject.Type
        return ASPlatformInfo.value(forKey: "shared") as! NSObject
    }
    
    private func sysctlValue(_ name: String) -> String {
        var size = 0
        sysctlbyname(name, nil, &size, nil, 0)
        var buffer = [CChar](repeating: 0,  count: size)
        sysctlbyname(name, &buffer, &size, nil, 0)
        return String(cString: buffer, encoding: .utf8) ?? "N/A"
    }
}
