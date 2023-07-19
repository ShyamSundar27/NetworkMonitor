//
//  Configuration.swift
//  VTDB
//
//  Created by Dal Bahadur Thapa on 08/12/17.
//  Copyright © 2017 Zoho Corp. All rights reserved.
//

import Foundation
#if SQLCipher
import SQLCipher
#else
import SQLite3
#endif

public struct Configuration {
    
    // MARK: Misc options
    public var foreignKeysEnabled: Bool = false
    public var readonly: Bool = false
    public var mapColumn: Bool = false
    public var trace: TraceFunction?
    #if SQLCipher
    var key: Key?
    var salt: String?
    #endif
    #if SQLEncrypted
    public var encryptionType: EncryptionType = .none
    #endif
    
    // MARK: Transactions
    public var defaultTransactionType: Database.TransactionType = .deferred
    
    // MARK: Concurrency
    public var busyMode: Database.BusyMode = .immediateError
    public var maximumReaderCount: Int = 5
    
    // MARK: Factory Configuration
    
    /// Creates a factory configuration
    public init() { }
    
    // MARK: Not Public
    var threadingMode: Database.ThreadingMode = .default
    var SQLiteOpenFlags: Int32 {
        let readWriteFlags = readonly ? SQLITE_OPEN_READONLY : (SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE)
        return threadingMode.SQLiteOpenFlags | readWriteFlags
    }
    
    public enum Key {
        case passphrase(String)
        case rawKey(Data)
        
        var plainKey: String {
            switch self {
            case .passphrase(let key): return key
            case .rawKey(let data): return "x'\(data.hexadecimal)'"
            }
        }
    }
    
    #if SQLCipher
    public mutating func setKey(_ key: Key) throws {
        switch key {
        case .passphrase(let passphrase):
            if passphrase.hasPrefix("x'") {
                guard passphrase.hasSuffix("'"),
                      let rawKey = passphrase.hexadecimal else {
                    throw VTDBError.invalidKey
                }
                try setKey(.rawKey(rawKey))
            } else {
                self.key = key
                self.salt = nil
            }
        case .rawKey(let data):
            if data.count == 32 {
                self.key = key
                self.salt = nil
            } else if data.count == 48 {
                let saltHex = data.suffix(16).hexadecimal
                self.key = .rawKey(data.prefix(32))
                self.salt = "x'\(saltHex)'"
            } else {
                throw VTDBError.invalidKey
            }
        }
    }
    
    public mutating func setKey(_ key: Key, salt: Data) throws {
        switch key {
        case .passphrase(let passphrase):
            if passphrase.hasPrefix("x'") {
                guard passphrase.hasSuffix("'"),
                      let rawKey = passphrase.hexadecimal else {
                    throw VTDBError.invalidKey
                }
                try setKey(.rawKey(rawKey), salt: salt)
            }
        case .rawKey(let data):
            guard data.count == 32 else {
                throw VTDBError.invalidKey
            }
        }
        self.key = key
        self.salt = "x'\(salt.hexadecimal)'"
    }
    
    public mutating func setKey(_ key: Key, salt: String) throws {
        guard let saltData = salt.hexadecimal else {
            throw VTDBError.invalidSalt
        }
        try setKey(key, salt: saltData)
    }
    #endif
}

/// A tracing function that takes an SQL string.
public typealias TraceFunction = (String) -> Void
