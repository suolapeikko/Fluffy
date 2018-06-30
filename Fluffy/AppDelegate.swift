//
//  AppDelegate.swift
//  Fluffy
//
//  Created by Suolapeikko on 20/11/2017.
//  Copyright © 2018 Antti Tulisalo. All rights reserved.
//

import Cocoa
import SystemConfiguration

// Network change notification (listener: MenuViewController)
let networkChangeNotification = Notification(name: Notification.Name(rawValue: "networkChanged"))

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var menuView: MenuViewController!

    let authHelper = AuthenticationHelper()
    let kcHelper = KeychainHelper()

    func applicationDidFinishLaunching(_ aNotification: Notification) {

        // Check for pre-configured kerberos realm from plist file
        // This is meant for enterprise deployment with pre-configured realm
        // eg. defaults write com.github.suolapeikko.Fluffy kerberos_realm "MYREALM.COM"
        let realm = UserDefaults.standard.string(forKey: "kerberos_realm")
        if (realm != nil) {
            Variables.hasPlistRealm = true
            Variables.plistRealm = realm!
        }

        // Check for pre-configured enablement of password change functionality
        // This is meant for enterprise deployment is there is also a need for kpasswd functionality
        // eg. defaults write com.github.suolapeikko.Fluffy enable_password_change -bool true
        Variables.enablePasswordChange = UserDefaults.standard.bool(forKey: "enable_password_change")

        // This is needed for notifications about network status changes, eg. user changes network adapter or starts VPN
        prepareAndRunNetworkChangeNotifications()

        // Check possible existing authentication info during app startup
        // Case 1: No password line found in keychain -> enable "Enable SSO" item
        // Case 2: Keychain line exists, but TGT attempt failed -> enable "Enable SSO" item
        // Case 3: keychain line exists and TGT attempt is successful -> disable "Enable SSO" item and enable "Change password" item

        // Check if there is a keychain entry for the app containing authentication info
        var userAccount: AccountItem
        do {
            try userAccount = kcHelper.loginItems(service: "Fluffy")
        }
        catch (_){
            menuView.updateAuthenticationStatus(principal: "", authStatus: false)
            menuView.viewWillAppear()
            return
        }

        // Authenticate using credentials found in keychain
        let (tgtStatus, _, credentials) =  authHelper.authenticate(username: userAccount.username, password: userAccount.password)
        
        // Failed, update gui and clean credentials
        if(tgtStatus > 0) {
            menuView.updateAuthenticationStatus(principal: "", authStatus: false)
            credentials.deinitialize(count: 1)
            credentials.deallocate()
        }
        else { // Success, update gui and store credentials and start refresh timer
            menuView.updateAuthenticationStatus(principal: userAccount.username, authStatus: true)
            menuView.startTimer()
        }
        
        menuView.viewWillAppear()
    }
    
    /**
        Set up network change notifications. MenuViewController is listening to these changes.
    */
    func prepareAndRunNetworkChangeNotifications() {
        
        let changed: SCDynamicStoreCallBack = {dynamicStore,_,_ in
            
            NotificationQueue.default.enqueue(networkChangeNotification, postingStyle: .now)
        }
        
        var dynamicContext = SCDynamicStoreContext(version: 0, info: nil, retain: nil, release: nil, copyDescription: nil)
        let dcAddress = withUnsafeMutablePointer(to: &dynamicContext, {UnsafeMutablePointer<SCDynamicStoreContext>($0)})
        
        if let dynamicStore = SCDynamicStoreCreate(kCFAllocatorDefault, "com.github.suolapeikko.fluffy.notifications.networkchanged" as CFString, changed, dcAddress) {
            
            let keys: [CFString] = ["State:/Network/Global/IPv4" as CFString]
            let keysArray = keys as CFArray
            
            SCDynamicStoreSetNotificationKeys(dynamicStore, nil, keysArray)
            
            let loop = SCDynamicStoreCreateRunLoopSource(kCFAllocatorDefault, dynamicStore, 0)
            CFRunLoopAddSource(CFRunLoopGetCurrent(), loop, CFRunLoopMode.defaultMode)
            
            CFRunLoopRun()
        }
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        
        // Insert code here to tear down your application
        if(menuView.authenticationStatus()==true) {
            authHelper.deleteCredentials()
            menuView.stopTimer()
        }
    }    
}
