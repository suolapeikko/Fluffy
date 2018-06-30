//
//  MenuViewController.swift
//  Fluffy
//
//  Created by Suolapeikko on 20/11/2017.
//  Copyright © 2018 Antti Tulisalo. All rights reserved.
//

import Cocoa
import GSS

var Timestamp: Double {
    return Double("\(NSDate().timeIntervalSince1970 * 1000)")!
}

class MenuViewController: NSViewController, StatusDelegate {

    @IBOutlet weak var mainMenu: NSMenu!
    @IBOutlet weak var enableSSOItem: NSMenuItem!
    @IBOutlet weak var disableSSOItem: NSMenuItem!
    @IBOutlet weak var changePasswordItem: NSMenuItem!
    @IBOutlet weak var quitItem: NSMenuItem!
    
    @IBOutlet weak var passwordVC: PasswordViewController!
    @IBOutlet weak var authenticationVC: AuthenticationViewController!
   
    var statusBar = NSStatusBar.system
    var statusItem: NSStatusItem?
    var menuImage: NSImage?
    
    var isAuthenticated = false
    var lastNetworkRefresh = 0.0
    
    var authHelper = AuthenticationHelper()
    let kcHelper = KeychainHelper()

    // TGT refresh timer
    var timer: Timer?
    
    // Needs this override to prepare the Menu
    override func awakeFromNib() {

        // Initialize VC delegates
        authenticationVC.delegate = self
        passwordVC.delegate = self
        
        // Register for network change notifications.
        NotificationCenter.default.addObserver(self, selector: #selector(networkChanged), name: NSNotification.Name(rawValue: "networkChanged"), object: nil)

        // Initialize Menu & items
        statusItem = statusBar.statusItem( withLength: NSStatusItem.variableLength)
        statusItem?.image = menuImage
        statusItem?.menu = mainMenu        
    }
    
    override func viewWillAppear() {
        
        super.viewWillAppear()
        
        if(Variables.enablePasswordChange==false) {
            mainMenu.removeItem(changePasswordItem)
        }
    }

    /**
         User clicks "Quit"
     */
    @IBAction func quitApplication(_ sender: AnyObject) {
        
        // Credentials are released and timer stopped in App Delegate's applicationWillTerminate
        NSApplication.shared.terminate(self)
    }
    
    /**
         User clicks "Change password"
     */
    @IBAction func changePasswordClicked(_ sender: AnyObject) {
        passwordVC.passwordPanel.makeKeyAndOrderFront(self)
        passwordVC.viewWillAppear()
        NSApp.activate(ignoringOtherApps: true)
        NSApp.runModal(for: passwordVC.passwordPanel)
    }

    /**
         User clicks "Enable Single Sign-on"
     */
    @IBAction func enableSSOClicked(_ sender: AnyObject) {
        
        var needsCredentials = false
        var userAccount = AccountItem()
        
        // First check if keychain item exist and if it fails or does not exist then prompt for credentials
        
        // Check whether keychain item already exists and if it can be used for authentication
        do {
            userAccount = try kcHelper.loginItems(service: "Fluffy")
            let (tgtStatus, tgtError, creds) = authHelper.authenticate(username: userAccount.username, password: userAccount.password)
            
            // Check if there is an error value and if there is, mark for credentials prompt
            if(tgtStatus > 0) {
                
                let errorDict = CFErrorCopyUserInfo(tgtError?.takeRetainedValue()) as Dictionary
                let errorMessage = errorDict.values.first as! String
                updateAuthenticationStatus(principal: "", authStatus: false)
                needsCredentials = true
                creds.deinitialize(count: 1)
                creds.deallocate()
                NSLog(errorMessage)
            }
            else {
                updateAuthenticationStatus(principal: userAccount.username, authStatus: true)
                startTimer()
            }
        }
        catch(_) { // Not found, so mark for credentials prompt
            needsCredentials = true
        }
        
        // Needs manual credential prompt, so forward work to authentication view
        if(needsCredentials == true) {
            authenticationVC.authenticationPanel.makeKeyAndOrderFront(self)
            authenticationVC.viewWillAppear()
            NSApp.activate(ignoringOtherApps: true)
            NSApp.runModal(for: authenticationVC.authenticationPanel)
        }
    }
    
    /**
         User clicks "Disable Single Sign-on"
     */
    @IBAction func disableSSOClicked(_ sender: AnyObject) {
        
        authHelper.deleteCredentials()
        stopTimer()
        updateAuthenticationStatus(principal: "", authStatus: false)
    }
    
    /**
         Switch between authentication statuses and update GUI accordingly
     */
    func updateAuthenticationStatus(principal: String, authStatus: Bool) {
        
        if(authStatus==true) {
            menuImage = NSImage(named: NSImage.Name(rawValue: "MenuIconBlack"))
            menuImage?.isTemplate = true // Alpha mask to support dark mode
            
            if(Variables.enablePasswordChange==true) {
                changePasswordItem.isEnabled = true
            }
            
            enableSSOItem.isEnabled = false
            enableSSOItem.title = "Single Sign-on Enabled"
            disableSSOItem.isEnabled = true
            isAuthenticated = true
        }
        else {
            menuImage = NSImage(named: NSImage.Name(rawValue: "MenuIconGray")) // Supports dark mode by default
            
            if(Variables.enablePasswordChange==true) {
                changePasswordItem.isEnabled = false
            }

            enableSSOItem.isEnabled = true
            enableSSOItem.title = "Enable Single Sign-on"
            disableSSOItem.isEnabled = false
            isAuthenticated = false
        }
        statusItem?.image = menuImage
    }
        
    func startTimer() {
        timer = Timer.scheduledTimer(timeInterval: 3600, target: authenticationVC, selector: #selector(authenticationVC.refreshTGT), userInfo: nil, repeats: true);
    }
    
    func stopTimer() {
        timer?.invalidate()
    }
    
    func refreshTGT() -> Bool {
        return authenticationVC.refreshTGT()
    }
    
    /**
        Registered in awakeFromNib()
    */
    @objc func networkChanged() {
        
        // Need to check the timestamp due to double calls to the method when changing Wi-Fi
        let now = Timestamp

        if(now - lastNetworkRefresh > 1000) {
            // Need to wait for two seconds if network joining takes time
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                _ = self.authenticationVC.refreshTGT()
            }
        }
        lastNetworkRefresh = now
    }
    
    func authenticationStatus() -> Bool {
        return isAuthenticated
    }    
}
