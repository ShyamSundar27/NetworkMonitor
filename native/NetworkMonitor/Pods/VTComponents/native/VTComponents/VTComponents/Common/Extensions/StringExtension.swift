//
//  StringExtension.swift
//  ZohoMail
//
//  Created by Robin Rajasekaran on 19/12/18.
//  Copyright © 2018 Zoho Corporation. All rights reserved.
//

import Foundation


extension String {
    
    public var length: Int {
        return (self as NSString).length
    }
    
    public func replacingWhiteSpaceCharacters() -> String {
        var str = self
        for index in 0...str.length-1 {
            if str.isWhitespaceCharacter(in: NSRange(location: index, length: 1)) {
                str = (str as NSString).replacingCharacters(in: NSRange(location: index, length: 1), with: " ")
            }
        }
        return str
    }
    
    public func isWhitespaceCharacter(in range: NSRange) -> Bool {
        if let character = (self as NSString).substring(with: range).utf16.first, CharacterSet.whitespacesAndNewlines.contains(UnicodeScalar(character)!) {
            return true
        }
        return false
    }
    
    public func getPlaceHolderLetters(limit: Int = 2) -> String {
        if self.isEmpty {
            return ""
        }
        var result = ""
        let splitedArr = self.split(separator: " ")
        for wordSequence in splitedArr {
            let word = String(wordSequence)
            if let firstLetter = getFirstAlphabet(from: word) {
                result += firstLetter
            }
            if result.count == limit {
                break
            }
        }
        if result.isEmpty, let char = self.first {
            result = String(char)
        }
        result = result.uppercased()
        return result
    }
    
    public func capitalizingFirstLetter() -> String {
        return prefix(1).capitalized + dropFirst()
    }
    
    public mutating func capitalizeFirstLetter() {
        self = self.capitalizingFirstLetter()
    }
    
    
    // MARK: - Helper methods
    
    private func getFirstAlphabet(from string: String) -> String? {
        for uniCode in string.unicodeScalars {
            if CharacterSet.letters.contains(uniCode) {
                return String(uniCode)
            }
        }
        return nil
    }
}


