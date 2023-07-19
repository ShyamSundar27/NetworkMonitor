//
//  VTDBError.swift
//  VTDB iOS
//
//  Created by Dal Bahadur Thapa on 28/02/19.
//  Copyright © 2019 Zoho Corp. All rights reserved.
//

import Foundation

public enum VTDBError: Error {
    case unexpectedType(Int32)
    case invalidReaderCount(Int)
    case invalidData(String)
    case invalidKey
    case invalidSalt
    
    static func getCastError<Type1, Type2>(actualType type1: Type1.Type, expectedType type2: Type2.Type) -> VTDBError {
        return .invalidData("Could not cast value of type `\(type1)` to `\(type2)`")
    }
}
