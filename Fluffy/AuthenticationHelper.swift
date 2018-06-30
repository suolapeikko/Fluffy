//
//  AuthenticationHelper.swift
//  Fluffy
//
//  Created by Suolapeikko on 19/11/2017.
//  Copyright © 2018 Antti Tulisalo. All rights reserved.
//

import Foundation
import GSS

struct AuthenticationHelper {
    
    ///  Helper function which tries to create TGT for the user
    /// - parameters:
    ///   - String: username
    ///   - String: password
    /// - returns:
    ///   - OM_uint32: status code
    ///   - Unmanaged<CFError> error reference
    func authenticate(username: String, password: String) -> (OM_uint32, Unmanaged<CFError>?) {
        
        // Create GSS name
        let gssName = GSSCreateName(username as CFTypeRef, &__gss_c_nt_user_name_oid_desc, nil)
        
        // Create password dictionary for TGT grant
        let pwdValue: Dictionary = [kGSSICPassword:password]
        
        // Create Identity for the user
        let cred: UnsafeMutablePointer<gss_cred_id_t> = UnsafeMutablePointer.allocate(capacity: 1)
        defer {
            cred.deinitialize(count: 1)
            cred.deallocate()
        }
        var tgtError: Unmanaged<CFError>?
        
        // Try to obtain kerberos credentials
        let tgtStatus = gss_aapl_initial_cred(gssName!, &__gss_krb5_mechanism_oid_desc, pwdValue as CFDictionary?, cred, &tgtError)
        
        return (tgtStatus, tgtError)
    }
    
    ///  Helper function which tries to create persistent credentials for the calling method
    /// - parameters:
    ///   - String: username
    ///   - String: password
    /// - returns:
    ///   - OM_uint32: status code
    ///   - Unmanaged<CFError> error reference
    ///   - UnsafeMutablePointer<gss_cred_id_t> user credentials
    func authenticate(username: String, password: String) -> (OM_uint32, Unmanaged<CFError>?, UnsafeMutablePointer<gss_cred_id_t>) {
        
        // Create GSS name
        let gssName = GSSCreateName(username as CFTypeRef, &__gss_c_nt_user_name_oid_desc, nil)
        
        // Create password dictionary for TGT grant
        let pwdValue: Dictionary = [kGSSICPassword:password]
        
        // Create Identity for the user (for some reason the only way to create a valid but null ref is to allocate and deallocate)
        let cred: UnsafeMutablePointer<gss_cred_id_t> = UnsafeMutablePointer.allocate(capacity: 1)
        
        var tgtError: Unmanaged<CFError>?
        
        // Try to obtain kerberos credentials
        let tgtStatus = gss_aapl_initial_cred(gssName!, &__gss_krb5_mechanism_oid_desc, pwdValue as CFDictionary?, cred, &tgtError)
        
        return (tgtStatus, tgtError, cred)
    }
    
    ///  This function changes the password for the user
    /// - parameters:
    ///   - String: username
    ///   - String: currentPassword
    ///   - String: newPassword
    /// - returns:
    ///   - Bool success or failure
    func changePassword(username: String, currentPassword: String, newPassword: String) -> Bool {
        
        // Create GSS name
        let gssName = GSSCreateName(username as CFTypeRef, &__gss_c_nt_user_name_oid_desc, nil)
        
        // Create password dictionary for password change
        let pwdValues: Dictionary = [kGSSChangePasswordOldPassword:currentPassword, kGSSChangePasswordNewPassword:newPassword]
        
        var pwdError: Unmanaged<CFError>?
        
        let status = gss_aapl_change_password(gssName!, &__gss_krb5_mechanism_oid_desc, pwdValues as CFDictionary, &pwdError)
        
        // Check if there is an error value and if there is, obtain the description and print it to NSLog
        if(status > 0) {
            let errorDict = CFErrorCopyUserInfo(pwdError?.takeRetainedValue()) as Dictionary
            NSLog(errorDict.values.first! as! String)
            
            return false
        }
        else {
            return true
        }
    }
    
    /**
     Deletes all user's kerberos tickets
     */
    func deleteCredentials() {
        
        let kdestroyCommand = CliCommand(launchPath: "/usr/bin/kdestroy", arguments: [])
        
        // Prepare task helper
        let chainedCommand = TaskHelper(commands: [kdestroyCommand])
        
        // Execute kdestroy
        do {
            _ = try chainedCommand.execute()
        }
        catch _ {
            NSLog("Failed to execute command kdestroy")
        }
    }
}
