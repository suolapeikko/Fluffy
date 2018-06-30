//
//  PasswordVC.swift
//  Fluffy
//
//  Created by Suolapeikko on 20/11/2017.
//  Copyright © 2018 Antti Tulisalo. All rights reserved.
//

import Cocoa
import GSS

class PasswordViewController: NSViewController {

    @IBOutlet weak var passwordPanel: NSPanel!
    @IBOutlet weak var newPasswordLabel: NSTextField!
    @IBOutlet weak var verifyPasswordLabel: NSTextField!
    @IBOutlet weak var newPasswordField: NSSecureTextField!
    @IBOutlet weak var verifyPasswordField: NSSecureTextField!
    @IBOutlet weak var cancelButton: NSButton!
    @IBOutlet weak var changeButton: NSButton!
    @IBOutlet weak var passwordChangeMessage: NSTextField!

    weak var delegate: StatusDelegate?
 
    @IBAction func cancelButtonClicked(_ sender: AnyObject) {
        NSApp.stopModal()
        passwordPanel.close()
    }
    
    @IBAction func changeButtonClicked(_ sender: AnyObject) {
        
        // Refresh ticket, just in case
        _ = delegate?.refreshTGT()
        
        var userAccount = AccountItem()
        var canProceedWithPasswordChange = false
        var canClosePasswordPanel = false
        
        let kcHelper = KeychainHelper()
        let authHelper = AuthenticationHelper()

        // Checking fields for empty values, password typos etc.
        guard let newPassword = newPasswordField?.stringValue, !newPassword.isEmpty else {return}
        guard let verifyPassword = verifyPasswordField?.stringValue, !verifyPassword.isEmpty else {return}
        

        // Make sure that the new passwords match
        if(newPassword != verifyPassword) {
            let alert = NSAlert()
            alert.messageText = "Supplied passwords didn't match"
            alert.addButton(withTitle: "Ok")
            alert.beginSheetModal(for: passwordPanel, completionHandler: nil)
        }
        else {
            // Get user account name and password from keychain
            canProceedWithPasswordChange = true
            do {
                userAccount = try kcHelper.loginItems(service: "Fluffy")
            }
            catch(_) {
                
                let alert = NSAlert()
                alert.messageText = "Password change failed due to missing keychain item for the application"
                alert.addButton(withTitle: "Ok")
                alert.beginSheetModal(for: passwordPanel, completionHandler: nil)
                changeButton.isEnabled = false
                canProceedWithPasswordChange = false
                if(delegate?.authenticationStatus()==true) {
                    authHelper.deleteCredentials()
                }
                delegate?.updateAuthenticationStatus(principal: "", authStatus: false)
            }
        }
        
        // If password checks are ok, proceed with change, otherwise remove identity and update status
        if(canProceedWithPasswordChange == true) {
 
            // Change the password
            let result = authHelper.changePassword(username: userAccount.username, currentPassword: userAccount.password, newPassword: newPassword)
            
            // If the password was changed succesfully, renew the keychain item
            // If it was unsuccesfull, show an error message to end user
            if(result == true) {
                
                // Hide GUI elements and show success message for two seconds
                newPasswordLabel.isHidden = true;
                verifyPasswordLabel.isHidden = true;
                newPasswordField.isHidden = true;
                verifyPasswordField.isHidden = true;
                cancelButton.isHidden = true;
                changeButton.isHidden = true;
                passwordChangeMessage.isHidden = false;
                
                do {
                    try kcHelper.recreateRecord(service: "Fluffy", username: userAccount.username, password: newPassword)
                }
                catch(let message) {
                    NSLog(message.localizedDescription)
                }
                
                canClosePasswordPanel = true
            }
            else { // Password change failed
                let alert = NSAlert()
                alert.messageText = "Change password failed, check your domain password policy rules for details"
                alert.addButton(withTitle: "Ok")
                alert.beginSheetModal(for: passwordPanel, completionHandler: nil)
            }
        }
        
        if(canClosePasswordPanel == true) {

            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                NSApp.stopModal()
                self.passwordPanel.close()
                
                // Re-enable GUI elements
                self.newPasswordLabel.isHidden = true;
                self.verifyPasswordLabel.isHidden = true;
                self.newPasswordField.isHidden = false;
                self.verifyPasswordField.isHidden = false;
                self.cancelButton.isHidden = false;
                self.changeButton.isHidden = false;
                self.passwordChangeMessage.isHidden = true;
            }
        }
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        changeButton.isEnabled = true // If we have disabled this previously due to missing keychain item
        newPasswordField.stringValue = ""
        verifyPasswordField.stringValue = ""
        newPasswordField.becomeFirstResponder()
    }
}

