//
//  SystemSnapshot.swift
//  SysKit
    

import Foundation

/// The top-level structure providing a unified interface to the system's information.
///
/// It aggregates several categories of system data:
/// - `os`: Operating system details such as version, build, and update info.
/// - `macos`: macOS-specific metadata.
/// - `security`: Security-related information.
/// - `user`: Information about user accounts, including Apple accounts, crypto users, deleted users, and system flags.
///
/// This struct acts as the single entry point for accessing system-wide information.
@MainActor
public struct SystemSnapshot {
    private init() {}
    
    public static let os = OperatingSystemInfo()
    public static let macos = MacOS()
    public static let security = SecurityInfo()
    public static let user = SystemUserAccounts()
}
