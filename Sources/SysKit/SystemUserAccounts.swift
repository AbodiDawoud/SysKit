//
//  SystemUserAccounts.swift
//  SysKit
    

import AppKit


/// A structure that provides information about the system’s user accounts,
/// including the currently signed-in Apple account.
public struct SystemUserAccounts {
    /// The Apple account currently signed in on this device, if available.
    public var appleAccount: AppleAccount?
    
    
    /// The list of cryptographically managed users stored in the system.
    public let cryptoUsers: [CryptoUser]
    
    
    /// A list of recently logged-in users, represented by their usernames.
    public let recentUsers: [String]
    
    
    /// A list of deleted user accounts that were previously present on the system.
    public let deletedUsers: [DeletedUser]
    
    
    /// A Boolean value indicating whether the Guest account is enabled on this system.
    public let guestEnabled: Bool
    
    
    /// Initializes a new `SystemUserAccounts` snapshot of the system.
    /// Reads from system preference files and account databases.
    public init() {
        if let meAccount = Self.accountsDictionary()?.first {
            appleAccount = AppleAccount(
                accountId: meAccount["AccountID"] as? String ?? "Unknow",
                displayName: meAccount["DisplayName"] as? String ?? "Unknow",
                isVerified: (meAccount["primaryEmailVerified"] as? Int) == 1
            )
        }
        
        cryptoUsers = Self.loadCryptoUsers()
        recentUsers = Self.loginwindowPlistValue(forKey: "RecentUsers") ?? []
        deletedUsers = Self.loadDeletedUsers()
        
        guestEnabled = Self.loginwindowPlistValue(forKey: "GuestEnabled") ?? false
    }
    
    
    /// A Boolean value indicating whether the current logged-in user
    /// is the system’s Guest user.
    public var isCurrentUserGuest: Bool {
        let pw = getpwuid(getuid())
        if let name = pw?.pointee.pw_name {
            let username = String(cString: name)
            return username.lowercased() == "guest"
        }
        
        return false
    }
    
    
    /// A Boolean value indicating whether the current logged-in user
    /// has administrative privileges.
    public var isCurrentUserAdmin: Bool {
        let userName = NSUserName()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/dsmemberutil")
        process.arguments = ["checkmembership", "-U", userName, "-G", "admin"]

        let pipe = Pipe()
        process.standardOutput = pipe

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            print("Error running dsmemberutil: \(error)")
            return false
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: data, encoding: .utf8) {
            return output.contains("user is a member")
        }
        
        return false
    }

    
    /// Opens the Apple ID preferences pane in System Settings.
    public func openAppleIDPrefs() {
        let AFUtilities = NSClassFromString("AFUtilities") as! NSObject.Type
        AFUtilities.perform("openAppleIDPref")
    }
    
    
    /// Opens the Users & Groups preferences pane in System Settings.
    public func openUsersAndGroupsPrefs() {
        let AFUtilities = NSClassFromString("AFUtilities") as! NSObject.Type
        AFUtilities.perform("openUsersAndGroupsPref")
    }
    
    
    /// Returns the password hint for the specified user,
    /// or `nil` if the hint cannot be retrieved.
    public func getPasswordHint(for user: String) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/dscl")
        process.arguments = [".", "-read", "/Users/\(user)", "hint"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return nil
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard var output = String(data: data, encoding: .utf8) else { return nil }

        output = output.trimmingCharacters(in: .whitespacesAndNewlines)

        // Extract text after "hint: "
        if let range = output.range(of: "hint: ") {
            return String(output[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return nil
    }
}

private extension SystemUserAccounts {
    private static func accountsDictionary() -> [[String: Any]]? {
        let dom = UserDefaults.standard.persistentDomain(forName: "MobileMeAccounts")
        let accounts = dom?["Accounts"] as? [[String: Any]]
        
        return accounts
    }
    
    
    private static func loginwindowPlistValue<T>(forKey key: String) -> T? {
        let plistPath = "/Library/Preferences/com.apple.loginwindow.plist"
        guard let dic = NSDictionary(contentsOfFile: plistPath) as? [String: Any]
        else { return nil }
        
        return dic[key] as? T
    }
    
    
    private static func loadDeletedUsers() -> [DeletedUser] {
        let plistPath = "/Library/Preferences/com.apple.preferences.accounts.plist"
        guard let dic = NSDictionary(contentsOfFile: plistPath) as? [String: Any],
              let deletedUsersArray = dic["deletedUsers"] as? [[String: Any]]
        else { return [] }
        
        var users: [DeletedUser] = []
        for user in deletedUsersArray {
            users.append(
                DeletedUser(
                    name: user["name"] as? String ?? "N/A",
                    realName: user["dsAttrTypeStandard:RealName"] as? String ?? "N/A",
                    uniqueID: user["dsAttrTypeStandard:UniqueID"] as? Int ?? 111,
                    deleteDate: user["date"] as? Date ?? .distantPast
                )
            )
        }
        
        return users
    }

    
    private static func loadCryptoUsers() -> [CryptoUser] {
        let prebootRoot = "/System/Volumes/Preboot/"
        let suffix = "/var/db/CryptoUserInfo.plist"
        var uuid: String = ""
        
        try? FileManager.default.contentsOfDirectory(atPath: prebootRoot).forEach {
            //A36FE7A4-377D-4257-BAC0-410C4917641A
            if $0.contains("-") && $0.count == 36 {
                uuid = $0
                return
            }
        }
        
        let fullPath = prebootRoot + uuid + suffix
        
        guard let dic = NSDictionary(contentsOfFile: fullPath) as? [String: [String: Any]]
        else { return [] }
        
        var foundUsers = [CryptoUser]()
        for user in dic.values {
            if let userType = user["UserType"] as? String, userType.hasPrefix("ICloud")
            { continue }
            
            
            foundUsers.append(
                CryptoUser(
                    fullName: user["FullName"] as? String ?? "N/A",
                    shortName: user["ShortName"] as? String ?? "N/A",
                    passwordHint: user["PasswordHint"] as? String ?? "N/A",
                    pictureData: user["PictureData"] as? Data ?? Data(),
                    userType: user["UserType"] as? String ?? "N/A"
                )
            )
        }
        
        return foundUsers
    }
}



/// Represents an Apple account signed in on this device.
public struct AppleAccount {
    /// A unique identifier string for the Apple account.
    public let accountId: String
    
    /// The display name associated with the Apple account.
    public let displayName: String
    
    /// A Boolean value indicating whether the account’s primary email is verified.
    public let isVerified: Bool
}


/// Represents a cryptographically managed local user account.
public struct CryptoUser {
    /// The full name of the user.
    public let fullName: String
    
    /// The short (username) of the user.
    public let shortName: String
    
    /// A password hint set for the user, if available.
    public let passwordHint: String
    
    /// Raw image data representing the user’s profile picture.
    public let pictureData: Data
    
    /// A string describing the type of cryptographic user.
    public let userType: String
}


/// Represents a previously deleted user account on the system.
public struct DeletedUser {
    /// The account’s short name (username).
    public let name: String
    
    /// The full real name of the deleted user.
    public let realName: String
    
    /// The unique numerical identifier (UID) of the user.
    public let uniqueID: Int
    
    /// The date when the account was deleted.
    public let deleteDate: Date
}
