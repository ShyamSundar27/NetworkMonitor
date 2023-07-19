//
//  KeychainWrapper.swift
//  VTDB
//
//  Created by Dal Bahadur Thapa on 30/05/18.
//  Copyright © 2018 Zoho Corp. All rights reserved.
//

import Foundation

public enum KeychainError: Error {
    case notFound
    case unhandledError(status: OSStatus)
}

open class KeychainWrapper {
    private let SecMatchLimit: String = kSecMatchLimit as String
    private let SecReturnData: String = kSecReturnData as String
    private let SecReturnPersistentRef: String = kSecReturnPersistentRef as String
    private let SecValueData: String = kSecValueData as String
    private let SecAttrAccessible: String = kSecAttrAccessible as String
    private let SecClass: String = kSecClass as String
    private let SecAttrService: String = kSecAttrService as String
    private let SecAttrGeneric: String = kSecAttrGeneric as String
    private let SecAttrAccount: String = kSecAttrAccount as String
    private let SecAttrAccessGroup: String = kSecAttrAccessGroup as String
    private let SecReturnAttributes: String = kSecReturnAttributes as String
    
    public let accessibility = kSecAttrAccessibleWhenUnlocked
    
    private (set) public var serviceName: String
    private (set) public var accessGroup: String?
    
    public init(serviceName: String, accessGroup: String? = nil) {
        self.serviceName = serviceName
        self.accessGroup = accessGroup
    }
    
    // MARK:- Public Methods
    open func hasValue(forKey key: String) -> Bool {
        do {
            _ = try data(forKey: key)
            return true
        } catch {
            return false
        }
    }
    
    open func allKeys() -> Set<String> {
        var keychainQueryDictionary: [String: Any] = [
            SecClass: kSecClassGenericPassword,
            SecAttrService: serviceName,
            SecReturnAttributes: kCFBooleanTrue,
            SecMatchLimit: kSecMatchLimitAll,
            ]
        
        if let accessGroup = self.accessGroup {
            keychainQueryDictionary[SecAttrAccessGroup] = accessGroup
        }
        
        var result: AnyObject?
        let status = SecItemCopyMatching(keychainQueryDictionary as CFDictionary, &result)
        
        guard status == errSecSuccess else { return [] }
        
        var keys = Set<String>()
        if let results = result as? [[AnyHashable: Any]] {
            for attributes in results {
                if let accountData = attributes[SecAttrAccount] as? Data,
                    let account = String(data: accountData, encoding: String.Encoding.utf8) {
                    keys.insert(account)
                }
            }
        }
        return keys
    }
    
    // MARK: Public Getters
    open func integer(forKey key: String) throws -> Int? {
        return Int(data: try data(forKey: key))
    }
    
    open func float(forKey key: String) throws -> Float? {
        return Float(data: try data(forKey: key))
    }
    
    open func double(forKey key: String) throws -> Double? {
        return Double(data: try data(forKey: key))
    }
    
    open func bool(forKey key: String) throws -> Bool? {
        return Bool(data: try data(forKey: key))
    }
    
    open func string(forKey key: String) throws -> String? {
        return String(data: try data(forKey: key))
    }
    
    open func data(forKey key: String) throws -> Data {
        var keychainQueryDictionary = setupKeychainQueryDictionary(forKey: key)
        
        // Limit search results to one
        keychainQueryDictionary[SecMatchLimit] = kSecMatchLimitOne
        // Specify we want Data/CFData returned
        keychainQueryDictionary[SecReturnData] = kCFBooleanTrue
        
        // Search
        var result: AnyObject?
        let status = SecItemCopyMatching(keychainQueryDictionary as CFDictionary, &result)
        
        if status == noErr {
            return result as! Data
        }
        guard status != errSecItemNotFound else { throw KeychainError.notFound }
        throw KeychainError.unhandledError(status: status)
    }
    
    // MARK: Public Setters
    open func set(_ value: Int, forKey key: String) throws {
        try set(value.data, forKey: key)
    }
    
    open func set(_ value: Float, forKey key: String) throws {
        try set(value.data, forKey: key)
    }
    
    open func set(_ value: Double, forKey key: String) throws {
        try set(value.data, forKey: key)
    }
    
    open func set(_ value: Bool, forKey key: String) throws {
        try set(value.data, forKey: key)
    }
    
    open func set(_ value: String, forKey key: String) throws {
        try set(value.data, forKey: key)
    }
    
    open func set(_ value: Data, forKey key: String) throws {
        var keychainQueryDictionary: [String: Any] = setupKeychainQueryDictionary(forKey: key)
        
        keychainQueryDictionary[SecValueData] = value
        keychainQueryDictionary[SecAttrAccessible] = accessibility
        
        let status: OSStatus = SecItemAdd(keychainQueryDictionary as CFDictionary, nil)
        
        if status == errSecSuccess {
            return
        } else if status == errSecDuplicateItem {
            try update(value, forKey: key)
        }
        guard status == errSecSuccess else  {
            throw KeychainError.unhandledError(status: status)
        }
        
    }
    
    open func removeObject(forKey key: String) throws {
        let keychainQueryDictionary: [String:Any] = setupKeychainQueryDictionary(forKey: key)
        let status: OSStatus = SecItemDelete(keychainQueryDictionary as CFDictionary)
        guard status == errSecSuccess else  {
            throw KeychainError.unhandledError(status: status)
        }
    }
    
    open func removeAllKeys() throws {
        var keychainQueryDictionary: [String: Any] = [SecClass: kSecClassGenericPassword]
        
        keychainQueryDictionary[SecAttrService] = serviceName
        if let accessGroup = accessGroup {
            keychainQueryDictionary[SecAttrAccessGroup] = accessGroup
        }
        
        let status: OSStatus = SecItemDelete(keychainQueryDictionary as CFDictionary)
        guard status == errSecSuccess else  {
            throw KeychainError.unhandledError(status: status)
        }
    }
    
    open class func wipeKeychain() throws {
        try deleteKeychainSecClass(kSecClassGenericPassword) // Generic password items
        try deleteKeychainSecClass(kSecClassInternetPassword) // Internet password items
        try deleteKeychainSecClass(kSecClassCertificate) // Certificate items
        try deleteKeychainSecClass(kSecClassKey) // Cryptographic key items
        try deleteKeychainSecClass(kSecClassIdentity) // Identity items
    }
    
    // MARK: Private Methods
    private class func deleteKeychainSecClass(_ secClass: AnyObject) throws {
        let query = [kSecClass as String: secClass]
        let status: OSStatus = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess else  {
            throw KeychainError.unhandledError(status: status)
        }
    }
    
    private func update(_ value: Data, forKey key: String) throws {
        let keychainQueryDictionary: [String: Any] = setupKeychainQueryDictionary(forKey: key)
        let updateDictionary = [SecValueData: value]
        
        let status: OSStatus = SecItemUpdate(keychainQueryDictionary as CFDictionary, updateDictionary as CFDictionary)
        guard status == errSecSuccess else  {
            throw KeychainError.unhandledError(status: status)
        }
    }
    
    private func setupKeychainQueryDictionary(forKey key: String) -> [String:Any] {
        // Setup default access as generic password (rather than a certificate, internet password, etc)
        var keychainQueryDictionary: [String:Any] = [SecClass: kSecClassGenericPassword]
        
        // Uniquely identify this keychain accessor
        keychainQueryDictionary[SecAttrService] = serviceName
        keychainQueryDictionary[SecAttrAccessible] = accessibility
        
        // Set the keychain access group if defined
        if let accessGroup = self.accessGroup {
            keychainQueryDictionary[SecAttrAccessGroup] = accessGroup
        }
        
        // Uniquely identify the account who will be accessing the keychain
        let encodedIdentifier: Data? = key.data(using: String.Encoding.utf8)
        keychainQueryDictionary[SecAttrGeneric] = encodedIdentifier
        keychainQueryDictionary[SecAttrAccount] = encodedIdentifier
        
        return keychainQueryDictionary
    }
}

extension KeychainWrapper {
    
    func getValue<T: DataConvertible>(forKey key: String) throws -> T? {
        return T(data: try data(forKey: key))
    }
    
    func set<T: DataConvertible>(_ value: T, forKey key: String) throws {
        try set(value.data, forKey: key)
    }
}
