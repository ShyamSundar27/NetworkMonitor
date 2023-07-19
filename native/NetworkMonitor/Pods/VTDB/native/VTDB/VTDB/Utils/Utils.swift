//
//  Utils.swift
//  VTDB
//
//  Created by Dal Bahadur Thapa on 24/04/18.
//  Copyright © 2018 Zoho Corp. All rights reserved.
//

import Foundation

/// A wrapper for value type
class Wrapper<T> {
    let value: T
    init(_ value: T) {
        self.value = value
    }
}

extension String {
    /// Create `Data` from hexadecimal string representation
    ///
    /// This creates a `Data` object from hex string. Note, if the string has any spaces or non-hex characters (e.g. starts with '<' and with a '>'), those are ignored and only hex characters are processed.
    ///
    /// - returns: Data represented by this hexadecimal string.
    
    var hexadecimal: Data? {
        var data = Data(capacity: count / 2)
        
        let regex = try! NSRegularExpression(pattern: "[0-9a-f]{1,2}", options: .caseInsensitive)
        regex.enumerateMatches(in: self, range: NSRange(startIndex..., in: self)) { match, _, _ in
            let byteString = (self as NSString).substring(with: match!.range)
            let num = UInt8(byteString, radix: 16)!
            data.append(num)
        }
        
        guard data.count > 0 else { return nil }
        
        return data
    }
    
    /// Returns the receiver, quoted for safe insertion as an identifier in an
    /// SQL query.
    ///
    ///     db.execute("SELECT * FROM \(tableName.quotedDatabaseIdentifier)")
    public var quotedDatabaseIdentifier: String {
        return "\"" + self + "\""
    }
    
    func matches(_ regex: String) -> Bool {
        return self.range(of: regex, options: .regularExpression) != nil
    }
    
    func matchingStrings(regex pattern: String) -> [String] {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            let range = NSMakeRange(0, self.count)
            return regex.matches(in: self, range: range).map {
                String(self[Range($0.range, in: self)!])
            }
        } catch {
            print("invalid regex: \(error.localizedDescription)")
            return []
        }
    }
    
    func matchingStrings(regex: NSRegularExpression) -> [String] {
        let range = NSMakeRange(0, self.count)
        return regex.matches(in: self, range: range).map {
            String(self[Range($0.range, in: self)!])
        }
    }
    
    mutating func replace(regex pattern: String, with replaceString: String) {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            let range = NSMakeRange(0, self.count)
            self = regex.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: replaceString)
        } catch {
            print("invalid regex: \(error.localizedDescription)")
            return
        }
    }
    
    mutating func replace(regex: NSRegularExpression, with replaceString: String) {
        let range = NSMakeRange(0, self.count)
        self = regex.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: replaceString)
    }
    
    func replacingOccurrences(regex pattern: String, with replaceString: String) -> String {
        var string = self
        string.replace(regex: pattern, with: replaceString)
        return string
    }
    
    func replacingOccurrences(regex: NSRegularExpression, with replaceString: String) -> String {
        var string = self
        string.replace(regex: regex, with: replaceString)
        return string
    }
    
    func split(regex pattern: String) -> [String] {
        let stop = "*VTDB*"
        return replacingOccurrences(regex: pattern, with: stop).components(separatedBy: stop).filter { !$0.isEmpty }
    }
    
    func split(regex: NSRegularExpression) -> [String] {
        let stop = "*VTDB*"
        return replacingOccurrences(regex: regex, with: stop).components(separatedBy: stop).filter { !$0.isEmpty }
    }
}

func makeRegex(pattern: String, options: NSRegularExpression.Options? = .caseInsensitive) -> NSRegularExpression {
    if let options = options {
        return try! NSRegularExpression(pattern: pattern, options: options)
    } else {
        return try! NSRegularExpression(pattern: pattern)
    }
}

/// Return as many question marks separated with commas as the *count* argument.
///
///     databaseQuestionMarks(count: 3) // "?,?,?"
public func databaseQuestionMarks(count: Int) -> String {
    return String(String(repeating: "?,", count: count).dropLast())
}

extension Dictionary {
    var allKeys: [Key] {
        return Array(keys)
    }
    
    var allValues: [Value] {
        return Array(values)
    }
}

extension Data {
    /// Hexadecimal string representation of `Data` object.
    var hexadecimal: String {
        return map { String(format: "%02x", $0) }
            .joined()
    }
    
    public static func randomBytes(ofLength length: Int) -> Data {
        let keyData = NSMutableData(length: length)!
        let result = SecRandomCopyBytes(kSecRandomDefault, length, keyData.mutableBytes.bindMemory(to: UInt8.self, capacity: length))
        assert(result == 0, "Failed to get random bytes")
        return keyData as Data
    }
}

func throwFirstError<T>(execute: () throws -> T, finally: () throws -> Void) throws -> T {
    var result: T?
    var firstError: Error?
    do {
        result = try execute()
    } catch {
        firstError = error
    }
    do {
        try finally()
    } catch {
        if firstError == nil {
            firstError = error
        }
    }
    if let firstError = firstError {
        throw firstError
    }
    return result!
}
