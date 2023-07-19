//
//  SQLOperator.swift
//  VTDB
//
//  Created by Dal Bahadur Thapa on 19/12/17.
//  Copyright © 2017 Zoho Corp. All rights reserved.
//

import Foundation

public enum SQLOrder: String {
    case asc = "ASC"
    case desc = "DESC"
}

public enum SQLBinaryOperator: String {
    case add = "+"
    case minus = "-"
    case multiply = "*"
    case divide = "/"
    case lessThan = "<"
    case lessThanOrEqual = "<="
    case greaterThan = ">"
    case greaterThanOrEqual = ">="
    case equal = "="
    case notEqual = "<>"
    case `is` = "IS"
    case isNot = "IS NOT"
    case and = "AND"
    case or = "OR"
    case like = "LIKE"
}

public func + (lhs: SQLExpression, rhs: SQLExpression) -> SQLExpression {
    return SQLBinaryExpression(.add, lhs: lhs, rhs: rhs)
}

public func - (lhs: SQLExpression, rhs: SQLExpression) -> SQLExpression {
    return SQLBinaryExpression(.minus, lhs: lhs, rhs: rhs)
}

public func / (lhs: SQLExpression, rhs: SQLExpression) -> SQLExpression {
    return SQLBinaryExpression(.divide, lhs: lhs, rhs: rhs)
}

public func * (lhs: SQLExpression, rhs: SQLExpression) -> SQLExpression {
    return SQLBinaryExpression(.multiply, lhs: lhs, rhs: rhs)
}

public func && (lhs: SQLExpression, rhs: SQLExpression) -> SQLExpression {
    return SQLBinaryExpression(.and, lhs: lhs, rhs: rhs)
}

public func || (lhs: SQLExpression, rhs: SQLExpression) -> SQLExpression {
    return SQLBinaryExpression(.or, lhs: lhs, rhs: rhs)
}

public func == (lhs: SQLExpression, rhs: SQLExpression?) -> SQLExpression {
    if rhs == nil {
        return SQLBinaryExpression(.is, lhs: lhs, rhs: rhs)
    } else {
        return SQLBinaryExpression(.equal, lhs: lhs, rhs: rhs)
    }
}

public func != (lhs: SQLExpression, rhs: SQLExpression?) -> SQLExpression {
    if rhs == nil {
        return SQLBinaryExpression(.isNot, lhs: lhs, rhs: rhs)
    } else {
        return SQLBinaryExpression(.notEqual, lhs: lhs, rhs: rhs)
    }
}

public func < (lhs: SQLExpression, rhs: SQLExpression) -> SQLExpression {
    return SQLBinaryExpression(.lessThan, lhs: lhs, rhs: rhs)
}

public func <= (lhs: SQLExpression, rhs: SQLExpression) -> SQLExpression {
    return SQLBinaryExpression(.lessThanOrEqual, lhs: lhs, rhs: rhs)
}

public func > (lhs: SQLExpression, rhs: SQLExpression) -> SQLExpression {
    return SQLBinaryExpression(.greaterThan, lhs: lhs, rhs: rhs)
}

public func >= (lhs: SQLExpression, rhs: SQLExpression) -> SQLExpression {
    return SQLBinaryExpression(.greaterThanOrEqual, lhs: lhs, rhs: rhs)
}

