//
//  KeychainHelper.swift
//  Fluffy
//
//  Created by Suolapeikko on 20/11/2017.
//  Copyright © 2018 Antti Tulisalo. All rights reserved.
//

import Foundation

enum KeychainError : Error {
    case RuntimeError(String)
}

struct AccountItem {
    var username: String = ""
    var password: String = ""
}

struct KeychainHelper {

    ///  Helper function to enable easy keychain username and password access
    /// - parameters:
    ///   - String: Service name, eg. app name
    /// - throws: KeychainError
    /// - returns:
    ///   - AccountItem: account information struct
    func loginItems(service:String) throws -> AccountItem {

        var account = AccountItem()

            account.username = try findKeychainAttribute(service: service, attribute: kSecAttrAccount)
            account.password = try findKey(service: service)

        return account
    }
    
    /// Helper function which deletes the old keychain item and creates a new to replace it
    ///
    /// - parameters:
    ///   - String: Service name, eg. app name
    ///   - String: User's name
    ///   - String: Text, eg. password, to be stored int the login keychain
    /// - throws: Decoded error description
    func recreateRecord(service: String, username: String, password: String) throws {
    
        do {
            try deleteKey(service: service, username: username)
        }
        catch(_) {
            // Ignore, as there might not always be keychain item available
        }
        try createKey(service: service, username: username, password: password)
    }
    
    /// Find keychain item attribute based on a service name
    /// - parameters:
    ///   - String: Service name, eg. app name
    ///   - CFString: attribute value, eg. kSecAttrAccount
    /// - throws: KeychainError
    /// - returns:
    ///   - String: attribute name
    func findKeychainAttribute(service: String, attribute: CFString) throws -> String {
        
        let keychainQuery: [NSObject: AnyObject] =  [
            kSecClass : kSecClassGenericPassword,
            kSecAttrService : service as AnyObject,
            kSecReturnAttributes : kCFBooleanTrue,
            kSecReturnData : kCFBooleanTrue,
            kSecMatchLimit : kSecMatchLimitOne]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(keychainQuery as CFDictionary, &dataTypeRef)
        if status == errSecSuccess,
            let retrievedData = dataTypeRef as! NSDictionary? {
            let attr = retrievedData[attribute] as! String
            if(attr.isEmpty) {
                throw KeychainError.RuntimeError(String(describing: "Invalid CFString attribute value"))
            }
            return attr
            
        } else {
            throw KeychainError.RuntimeError(String(describing: SecCopyErrorMessageString(status, nil)))
        }
    }
    
    /// Update keychain attribute based on a service name
    /// - parameters:
    ///   - String: Service name, eg. app name
    ///   - CFString: attribute value, eg. kSecAttrAccount
    ///   - String: new attribute value to be updated
    /// - throws: KeychainError
    func updateKeychainAttribute(service: String, attribute: CFString, value: String) throws {
        
        let keychainQuery: [NSObject: AnyObject] =  [
            kSecClass : kSecClassGenericPassword,
            kSecAttrService : service as AnyObject,
            kSecReturnAttributes : kCFBooleanTrue,
            kSecReturnData : kCFBooleanTrue,
            kSecMatchLimit : kSecMatchLimitOne]

        let updatedValues: [NSObject: AnyObject] =  [
            attribute : value as AnyObject]
        
        let status = SecItemUpdate(keychainQuery as CFDictionary, updatedValues as CFDictionary)
        if(status != errSecSuccess) {
            throw KeychainError.RuntimeError(String(describing: SecCopyErrorMessageString(status, nil)))
        }
    }
    
    /// This function creates an item to user's login keychain
    ///
    /// - parameters:
    ///   - String: Service name, eg. app name
    ///   - String: User's name
    ///   - String: Text, eg. password, to be stored int the login keychain
    /// - throws: Decoded error description
    func createKey(service: String, username: String, password: String) throws {
        
        var resultCode: OSStatus
        
        resultCode = SecKeychainAddGenericPassword(nil, UInt32(service.count), service, UInt32(username.count), username, UInt32(password.count), password, nil)
        
        guard resultCode == 0 else {throw KeychainError.RuntimeError(String(describing: SecCopyErrorMessageString(resultCode, nil)))}
    }
    
    /// This function finds an item from user's login keychain
    ///
    /// - parameters:
    ///   - String: Service name, eg. app name
    /// - throws: The item, eg. password, that has been stored to the login keychain
    /// - returns: Key value as String
    func findKey(service: String) throws -> String  {
        
        var resultCode: OSStatus
        var passwordLength: UInt32 = 0
        var passwordPointer: UnsafeMutableRawPointer? = nil
        var keychainItem: SecKeychainItem?
        let username = ""
        
        resultCode = SecKeychainFindGenericPassword(nil, UInt32(service.count), service, UInt32(username.count), username, &passwordLength, &passwordPointer, &keychainItem)
        
        guard resultCode == 0 else {throw KeychainError.RuntimeError(String(describing: SecCopyErrorMessageString(resultCode, nil)))}
    
        guard let tempStr = NSString(bytes: passwordPointer!, length: Int(passwordLength), encoding: String.Encoding.utf8.rawValue) as String? else {
            return ""
        }

        return tempStr
    }
    
    /// This function deletes an item from user's login keychain
    ///
    /// - parameters:
    ///   - String: Service name, eg. app name
    ///   - String: User's name
    /// - throws: Decoded error description
    func deleteKey(service: String, username: String) throws {
        
        var resultCode: OSStatus
        var passwordLength: UInt32 = 0
        var passwordPointer: UnsafeMutableRawPointer? = nil
        var keychainItem: SecKeychainItem?
        
        resultCode = SecKeychainFindGenericPassword(nil, UInt32(service.count), service, UInt32(username.count), username, &passwordLength, &passwordPointer, &keychainItem)
        
        guard resultCode == 0 else {throw KeychainError.RuntimeError(String(describing: SecCopyErrorMessageString(resultCode, nil)))}
        
        resultCode = SecKeychainItemDelete(keychainItem!)
        
        guard resultCode == 0 else {throw KeychainError.RuntimeError(String(describing: SecCopyErrorMessageString(resultCode, nil)))}
    }
}
