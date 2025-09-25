//
//  ContentView.swift
//  ExampleApp
    

import SwiftUI
import SysKit


struct ContentView: View {
    @State private var showUsersSheet: Bool = false
    @State private var showSoftwareUpdatesSheet: Bool = false
    
    var body: some View {
        Form {
            Section {
                VStack(spacing: 0) {
                    Image(.macbookair132022Midnight)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150, height: 150)
                    
                    Text(NSFullUserName())
                        .font(.headline)
                        .offset(x: 0, y: -10)
                }
                .frame(maxWidth: .infinity)
                .offset(x: 0, y: -10)
            }
            

            Section {
                LabeledContent("Users & Groups") {
                    Image(systemName: "chevron.right")
                        .bold()
                        .imageScale(.small)
                }
                .onTapGesture { showUsersSheet.toggle() }
            }
            
            
            Section("MacOS Metadata") {
                LabeledContent("Mac Model", value: SystemSnapshot.macos.macModelName)
                LabeledContent("Identifier", value: SystemSnapshot.macos.modelIdentifier)
                LabeledContent("Details", value: SystemSnapshot.macos.macModelDetails)
                LabeledContent("Chip", value: SystemSnapshot.macos.chip)
                LabeledContent("Memory", value: SystemSnapshot.macos.memory)
                
                LabeledContent("Serial Number", value: SystemSnapshot.macos.serialString)
                LabeledContent("Board ID", value: SystemSnapshot.macos.boardID)
                LabeledContent("Regulatory ID", value: SystemSnapshot.macos.regulatoryID)
                LabeledContent("Kernel Version", value: SystemSnapshot.macos.kernelVersion)
                LabeledContent("Uptime", value: SystemSnapshot.macos.formattedSystemUptime)
                
                Button("About This Mac", action: SystemSnapshot.macos.launchAboutThisMac)
                    .leftAlignment()
            }
            
            
            Section("Operating System") {
                HStack {
                    SystemSnapshot.os.osIcon
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                    
                    Text(SystemSnapshot.os.osTitleString)
                    
                    Spacer()
                    
                    Text("Version \(SystemSnapshot.os.osVersionString) (Build \(SystemSnapshot.os.osBuildString))")
                }
            
                LabeledContent("Previous Build", value: SystemSnapshot.os.softwareUpdates.previousUpdateBuild)
                LabeledContent("Upgrade Time", value: SystemSnapshot.os.softwareUpdates.lastUpgradeTimeFormatted)
                
                LabeledContent("Beta Version", value: SystemSnapshot.os.isBeta.str)
                LabeledContent("Internal Build", value: SystemSnapshot.os.isInternal.str)
                LabeledContent("Virtual Machine", value: SystemSnapshot.os.isVirtualMachine.str)

                
                Button("Software Updates") { showSoftwareUpdatesSheet.toggle() }
                    .leftAlignment()
            }
            
            
            Section("Security") {
                LabeledContent("Allowed App Sources", value: SystemSnapshot.security.allowedAppSources)
                
                LabeledContent(
                    "SIP Enabled",
                    value: SystemSnapshot.security.sipEnabled.str
                )
                
                LabeledContent(
                    "File Vault Enabled",
                    value: SystemSnapshot.security.fileVaultEnabled.str
                )
                
                LabeledContent(
                    "GateKeeper Enabled",
                    value: SystemSnapshot.security.gatekeeperEnabled.str
                )
                
                LabeledContent(
                    "Firwall Enabled",
                    value: SystemSnapshot.security.firewallEnabled.str
                )
                
                LabeledContent(
                    "FindMe Enabled",
                    value: SystemSnapshot.security.findMeEnabled.str
                )
                
                Button("Security Preferences", action: SystemSnapshot.security.openSecurityPref)
                    .leftAlignment()
            }
        }
        .formStyle(.grouped)
        .navigationTitle("This-Mac")
        .popover(isPresented: $showUsersSheet) {
            NavigationStack(root: UsersGroupsView.init)
        }
        .popover(isPresented: $showSoftwareUpdatesSheet) {
            NavigationStack(root: SoftwareUpdatesView.init)
        }
    }
}



struct UsersGroupsView: View {
    private let usr = SystemSnapshot.user
    
    var body: some View {
        Form {
            if let appleAccount = usr.appleAccount {
                Section {
                    LabeledContent("Full Name", value: appleAccount.displayName)
                    LabeledContent("Email", value: appleAccount.accountId)
                    LabeledContent("Verified", value: appleAccount.isVerified.str)
                } header: {
                    Button(action: usr.openAppleIDPrefs) {
                        Label("Apple ID", systemImage: "apple.logo")
                    }
                    .pointingHand()
                    .buttonStyle(.plain)
                }
            }
            
            if !usr.cryptoUsers.isEmpty {
                Section("Crypto User") {
                    ForEach(usr.cryptoUsers, id: \.fullName) {
                        cryptoUserRow($0)
                    }
                }
            }
            
            
            Section("Recent Users") {
                ForEach(usr.recentUsers, id: \.self) {
                    Text($0)
                }
            }
            
            if usr.deletedUsers.isEmpty == false {
                Section("Deleted Users") {
                    ForEach(usr.deletedUsers, id: \.self) {
                        deletedUserRow($0)
                    }
                }
            }
            
            Section {
                LabeledContent("Guest User", value: usr.isCurrentUserGuest.str)
                LabeledContent("Admin User", value: usr.isCurrentUserAdmin.str)
            } header: {
                Button(action: usr.openUsersAndGroupsPrefs) {
                    Label("Current User", systemImage: "person.crop.circle.dashed")
                }
                .pointingHand()
                .buttonStyle(.plain)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Users & Groups")
    }
    
    func deletedUserRow(_ user: DeletedUser) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 0) {
                Text(user.realName)
                Text(" • ")
                    .bold()
                    .foregroundStyle(.gray)
                Text(user.name)
            }
            
            Text("Deleted " + user.deleteDate.formatted(date: .numeric, time: .shortened))
                .font(.subheadline)
                .foregroundStyle(.gray)
        }
    }
    
    func cryptoUserRow(_ user: CryptoUser) -> some View {
        HStack {
            Image(nsImage:
                    .init(data: user.pictureData) ?? NSImage(symbolName: "person.circle.fill", variableValue: 1.0)!
            )
            .resizable()
            .scaledToFit()
            .frame(width: 33, height: 33)
            .clipShape(.circle)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(user.fullName)
                
                Text(user.shortName)
                    .font(.subheadline)
                    .foregroundStyle(.orange)
            }
            
            Spacer()
            
            Divider().padding(.vertical, 2)
            
            Text(user.passwordHint)
                .foregroundStyle(.secondary)
        }
    }
}



struct SoftwareUpdatesView: View {
    let updatesManager = SystemSnapshot.os.softwareUpdates
    
    var body: some View {
        Form {
            Section {
                HStack {
                    Button(action: SystemSnapshot.os.launchSoftwareUpdate) {
                        Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90")
                            .bold()
                            .foregroundStyle(.blue)
                    }
                    .pointingHand()
                    .buttonStyle(.plain)
                    
                    LabeledContent("Last check Time", value: updatesManager.lastCheck.formatted)
                }
            }
            
            Section {
                LabeledContent("Download new updates when available", value: updatesManager.automaticDownload ? "On" : "Off")
                LabeledContent("Install macOS updates", value: updatesManager.automaticallyInstallMacOSUpdates ? "On" : "Off")
                LabeledContent("Install critical updates", value: updatesManager.criticalUpdateInstall ? "On" : "Off")
            }
            
            Section("Recommended Updates") {
                ForEach(updatesManager.recommendedUpdates, id: \.identifier) { update in
                    HStack(spacing: 0) {
                        Text(update.displayName)
                        
                        // Avoid display update version if display name already contains it
                        if update.displayName.contains(update.displayVersion) == false {
                            Text(" • ").bold().foregroundStyle(.gray)
                            
                            Text(update.displayVersion)
                                .font(.subheadline)
                                .foregroundStyle(.orange)
                        }
                    }
                }
            }
            
            Section("Offers Dictionary") {
                ForEach(updatesManager.previousOffers.shuffled(), id: \.key) { offer in
                    LabeledContent("\(offer.key)", value: offer.value.formatted)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Software Updates")
    }
}
