//
//  AuthenticationViewController.swift
//  Fluffy
//
//  Created by Suolapeikko on 20/11/2017.
//  Copyright © 2018 Antti Tulisalo. All rights reserved.
//

import Cocoa
import GSS

class AuthenticationViewController: NSViewController {

    @IBOutlet weak var usernameField: NSTextField!
    @IBOutlet weak var passwordField: NSSecureTextField!
    @IBOutlet weak var authenticateButton: NSButton!
    @IBOutlet weak var cancelButton: NSButton!
    @IBOutlet weak var authenticationPanel: NSPanel!

    weak var delegate: StatusDelegate?
    
    let authHelper = AuthenticationHelper()
    let kcHelper = KeychainHelper()

    @IBAction func authenticateClicked(_ sender: AnyObject) {
        
        guard var username = usernameField?.stringValue, !username.isEmpty else {return}
        guard let password = passwordField?.stringValue, !password.isEmpty else {return}

        var usernameShort: String?
        var usernameLong: String?

        // Store username as instance var with and without domain postfix
        usernameShort = username
        
        if(Variables.hasPlistRealm) {
            username.append("@" + Variables.plistRealm)
        }
        usernameLong = username
        
        let (tgtStatus, tgtError, creds) = authHelper.authenticate(username: usernameLong!, password: password)
        
        // Check if there is an error value and if there is, obtain the description and print it
        if(tgtStatus != 0) {
            
            let alert = NSAlert()
            let errorDict = CFErrorCopyUserInfo(tgtError?.takeRetainedValue()) as Dictionary
            let errorMessage = errorDict.values.first as! String
            alert.messageText = errorMessage    
            alert.addButton(withTitle: "Ok")
            alert.beginSheetModal(for: authenticationPanel, completionHandler: nil)
            delegate?.updateAuthenticationStatus(principal: "", authStatus: false)
            creds.deinitialize(count: 1)
            creds.deallocate()
            
            NSLog(errorMessage)
        }
        else {
            delegate?.updateAuthenticationStatus(principal: usernameShort!, authStatus: true)
            delegate?.startTimer()
            
            // Keychain stuff here, basically delete and create line (instead of updating it)
            let utils = KeychainHelper()
            do {
                try utils.recreateRecord(service: "Fluffy", username: usernameShort!, password: password)
            }
            catch (let message){
                NSLog(message.localizedDescription)
                return
            }
            
            NSApp.stopModal()
            authenticationPanel.close()
        }
    }
        
    @IBAction func cancelClicked(_ sender: AnyObject) {
        NSApp.stopModal()
        authenticationPanel.close()
    }
    
    // This get called every 1 hour to refresh TGT and also from every network change event
    @objc func refreshTGT() -> Bool {
        
        // Find key, get username and password
        var userAccount: AccountItem?
        
        do {
            userAccount = try kcHelper.loginItems(service: "Fluffy")
        }
        catch (let message){
            NSLog(message.localizedDescription)
            delegate?.updateAuthenticationStatus(principal: "", authStatus: false)
            return false
        }
        
        var usernameLong = userAccount?.username

        if(Variables.hasPlistRealm) {
            usernameLong?.append("@" + Variables.plistRealm)
        }
        let (tgtStatus, tgtError, creds) = authHelper.authenticate(username: usernameLong!, password: (userAccount?.password)!)

        // Check if there is an error value and if there is, obtain the description and print it
        // In addition, invalidate the refresh timer
        if(tgtStatus != 0) {
            if(delegate?.authenticationStatus()==true) {
                authHelper.deleteCredentials()
            }
            delegate?.updateAuthenticationStatus(principal: "", authStatus: false)
            let errorDict = CFErrorCopyUserInfo(tgtError?.takeRetainedValue()) as Dictionary
            let errorMessage = errorDict.values.first as! String
            delegate?.stopTimer()
            creds.deinitialize(count: 1)
            creds.deallocate()
            NSLog(errorMessage)

            return false
        }
        else {
            delegate?.updateAuthenticationStatus(principal: userAccount!.username, authStatus: true)            
        }
        return true
    }
    
    override func viewWillAppear() {

        super.viewWillAppear()
        usernameField.stringValue = ""
        passwordField.stringValue = ""
        usernameField.becomeFirstResponder()
    }    
}
