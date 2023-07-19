//
//  SQLFunction.swift
//  VTDB
//
//  Created by Dal Bahadur Thapa on 19/12/17.
//  Copyright © 2017 Zoho Corp. All rights reserved.
//

import Foundation

public enum SQLFunction: String {
    case abs = "ABS"
    case avg = "AVG"
    case count = "COUNT"
    case length = "LENGTH"
    case max = "MAX"
    case min = "MIN"
    case sum = "SUM"
    case lower = "LOWER"
    case upper = "UPPER"
    case cast = "CAST"
}

public func abs(_ expression: SQLExpression) -> SQLExpression {
    return SQLFunctionExpression(.abs, arguments: expression)
}

public func avg(_ expression: SQLExpression) -> SQLExpression {
    return SQLFunctionExpression(.avg, arguments: expression)
}

public func count(_ expression: SQLExpression? = nil) -> SQLExpression {
    return SQLFunctionExpression(.count, arguments: expression ?? "*")
}

//public func count(distinct expression: SQLExpression) -> SQLExpression {
//    return SQLFunctionExpression(.countDistinct, arguments: expression)
//}

public func length(_ expression: SQLExpression) -> SQLExpression {
    return SQLFunctionExpression(.length, arguments: expression)
}

public func max(_ expression: SQLExpression) -> SQLExpression {
    return SQLFunctionExpression(.max, arguments: expression)
}

public func min(_ expression: SQLExpression) -> SQLExpression {
    return SQLFunctionExpression(.min, arguments: expression)
}

public func sum(_ expression: SQLExpression) -> SQLExpression {
    return SQLFunctionExpression(.sum, arguments: expression)
}

public func lower(_ expression: SQLExpression) -> SQLExpression {
    return SQLFunctionExpression(.lower, arguments: expression)
}

public func upper(_ expression: SQLExpression) -> SQLExpression {
    return SQLFunctionExpression(.upper, arguments: expression)
}


