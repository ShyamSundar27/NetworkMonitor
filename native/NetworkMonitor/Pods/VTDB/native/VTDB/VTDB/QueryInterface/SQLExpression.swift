//
//  SQLExpression.swift
//  VTDB
//
//  Created by Dal Bahadur Thapa on 19/12/17.
//  Copyright © 2017 Zoho Corp. All rights reserved.
//

import Foundation

public protocol SQLExpression {
    var parameters: [DatabaseValueConvertible?] { get }
    #if SQLEncrypted
    func expressionSQL(_ db: Database, encryptedColumns: Set<String>) -> String
    #else
    var expressionSQL: String { get }
    #endif
}

public protocol SQLRawExpression {
    var rawExpression: String { get }
}

extension SQLExpression {
    /*
    public var sql: String {
        let chunks = expressionSQL.components(separatedBy: "?")
        var merged: [String] = zip(chunks, parameters).map { p1, p2 in
            var rhs: String
            if let p2 = p2 {
                switch p2.databaseValue {
                case .integer, .real:
                    rhs = p2.expressionSQL
                default:
                    rhs = "'\(p2.expressionSQL)'"
                }
            } else {
                rhs = "NULL"
            }
            return p1 + rhs
        }
        if merged.count < chunks.count {
            merged += Array(chunks.dropFirst(merged.count))
        }
        return merged.joined()
    }
    */
    
    public func sql(_ db: Database) -> String {
        var query: String
        #if SQLEncrypted
        query = expressionSQL(db, encryptedColumns: [])
        #else
        query = expressionSQL
        #endif
        let chunks = query.components(separatedBy: "?")
        var merged: [String] = zip(chunks, parameters).map { p1, p2 in
            var rhs: String
            if let p2 = p2 {
                switch p2.databaseValue {
                case .integer, .real:
                    rhs = p2.rawExpression
                default:
                    rhs = "'\(p2.rawExpression)'"
                }
            } else {
                rhs = "NULL"
            }
            return p1 + rhs
        }
        if merged.count < chunks.count {
            merged += Array(chunks.dropFirst(merged.count))
        }
        return merged.joined()
    }
    
    #if SQLEncrypted
    func getDecryptedExpressionSQL(_ db: Database, encryptedColumns: Set<String>) -> String {
        if let expression = self as? SQLRawExpression {
            if encryptedColumns.contains(expression.rawExpression.lowercased()) {
                return "decrypt(\(expression.rawExpression))"
            } else {
                return expression.rawExpression
            }
        } else {
            return self.expressionSQL(db, encryptedColumns: encryptedColumns)
        }
    }
    #endif
}

public protocol SQLSubExpression: SQLExpression { }

public enum SQLCastType: String {
    case integer = "INTEGER"
    case text = "TEXT"
    case real = "REAL"
    case numeric = "NUMERIC"
    case none = ""
}

public enum SQLCollation {
    case binary
    case rtrim
    case nocase
    case custom(String)
}

extension SQLCollation {
    var collationName: String {
        switch self {
        case .binary: return "BINARY"
        case .rtrim: return "RTRIM"
        case .nocase: return "NOCASE"
        case .custom(let string):
            return string
        }
    }
}

extension SQLExpression {

    public func aliased(_ alias: String) -> SQLExpression {
        return SQLAliasedExpression(expression: self, alias: alias)
    }
    
    public func like(_ pattern: String) -> SQLExpression {
        return SQLBinaryExpression(.like, lhs: self, rhs: pattern)
    }
    
    public func collate(_ collation: SQLCollation = .nocase) -> SQLExpression {
        return SQLCollationExpression(collation, expression: self)
    }
    
    public func cast(_ type: SQLCastType) -> SQLExpression {
        switch type {
        case .none:
            return SQLFunctionExpression(.cast, arguments: self)
        default:
            return SQLFunctionExpression(.cast, arguments: self.aliased(type.rawValue))
        }
    }
    
    public var asc: SQLExpression {
        return SQLOrderExpression(.asc, expression: self)
    }
    
    public var desc: SQLExpression {
        return SQLOrderExpression(.desc, expression: self)
    }
    
    public func contains<T: DatabaseValueConvertible>(_ range: Range<T>) -> SQLExpression {
        return SQLRangeExpression(expression: self, range: .range, lowerBound: range.lowerBound, upperBound: range.upperBound)
    }
    
    public func contains<T: DatabaseValueConvertible>(_ range: ClosedRange<T>) -> SQLExpression {
        return SQLRangeExpression(expression: self, range: .closedRange, lowerBound: range.lowerBound, upperBound: range.upperBound)
    }
    
    public func contains(_ array: DatabaseValueConvertible...) -> SQLExpression {
        return SQLInExpression(expression: self, type: .array(array))
    }

    public func contains(_ array: [DatabaseValueConvertible]) -> SQLExpression {
        return SQLInExpression(expression: self, type: .array(array))
    }

    public func contains(_ query: SelectQueryProtocol) -> SQLExpression {
        return SQLInExpression(expression: self, type: .subquery(query))
    }
    
    public func except<T: DatabaseValueConvertible>(_ range: Range<T>) -> SQLExpression {
        return SQLRangeExpression(expression: self, range: .range, lowerBound: range.lowerBound, upperBound: range.upperBound, negated: true)
    }
    
    public func except<T: DatabaseValueConvertible>(_ range: ClosedRange<T>) -> SQLExpression {
        return SQLRangeExpression(expression: self, range: .closedRange, lowerBound: range.lowerBound, upperBound: range.upperBound, negated: true)
    }
    
    public func except(_ array: DatabaseValueConvertible...) -> SQLExpression {
        return SQLInExpression(expression: self, type: .array(array), negated: true)
    }
    
    public func except(_ array: [DatabaseValueConvertible]) -> SQLExpression {
        return SQLInExpression(expression: self, type: .array(array), negated: true)
    }
    
    public func except(_ query: SelectQueryProtocol) -> SQLExpression {
        return SQLInExpression(expression: self, type: .subquery(query), negated: true)
    }
}

public struct CustomSQLExpression: SQLSubExpression {
    public var rawExpression: String
    public var parameters: [DatabaseValueConvertible?]
    
    public init(rawExpression: String, parameters: [DatabaseValueConvertible?]) {
        self.rawExpression = rawExpression
        self.parameters = parameters
    }
    
    #if SQLEncrypted
    public func expressionSQL(_ db: Database, encryptedColumns: Set<String>) -> String {
        return rawExpression
    }
    #else
    public var expressionSQL: String {
        return rawExpression
    }
    #endif
}

public struct SQLBinaryExpression: SQLSubExpression {
    var op: SQLBinaryOperator
    var lhs: SQLExpression
    var rhs: SQLExpression?
    
    public init(_ op: SQLBinaryOperator, lhs: SQLExpression, rhs: SQLExpression?) {
        self.op = op
        if let string = lhs as? String {
            self.lhs = Column(string)
        } else {
            self.lhs = lhs
        }
        self.rhs = rhs
    }
    
    public var parameters: [DatabaseValueConvertible?] {
        return lhs.parameters + (rhs?.parameters ?? [nil])
    }
    
    #if SQLEncrypted
    public func expressionSQL(_ db: Database, encryptedColumns: Set<String>) -> String {
        var sql = "("
        if lhs is SQLSubExpression {
            sql += lhs.expressionSQL(db, encryptedColumns: encryptedColumns)
        } else {
            sql += "?"
        }
        sql += " \(op.rawValue) "
        if let rhs = rhs as? SQLSubExpression {
            sql += rhs.expressionSQL(db, encryptedColumns: encryptedColumns)
        } else {
            sql += "?"
        }
        sql += ")"
        return sql
    }
    #else
    public var expressionSQL: String {
        var sql = "("
        if lhs is SQLSubExpression {
            sql += lhs.expressionSQL
        } else {
            sql += "?"
        }
        sql += " \(op.rawValue) "
        if let rhs = rhs as? SQLSubExpression {
            sql += rhs.expressionSQL
        } else {
            sql += "?"
        }
        sql += ")"
        return sql
    }
    #endif
}

public struct SQLOrderExpression: SQLSubExpression {
    var expression: SQLExpression
    var order: SQLOrder
    
    public init(_ order: SQLOrder, expression: SQLExpression) {
        self.order = order
        self.expression = expression
    }
    
    public var parameters: [DatabaseValueConvertible?] {
        if let _ = expression as? SQLSubExpression {
            return expression.parameters
        }
        return []
    }
    
    #if SQLEncrypted
    public func expressionSQL(_ db: Database, encryptedColumns: Set<String>) -> String {
        let column = expression.getDecryptedExpressionSQL(db, encryptedColumns: encryptedColumns)
        return column + " " + order.rawValue
    }
    #else
    public var expressionSQL: String {
        return expression.expressionSQL + " " + order.rawValue
    }
    #endif
}

public struct SQLCollationExpression: SQLSubExpression {
    var expression: SQLExpression
    var collation: SQLCollation
    
    public init(_ collation: SQLCollation, expression: SQLExpression) {
        self.collation = collation
        self.expression = expression
    }
    
    public var parameters: [DatabaseValueConvertible?] {
        return expression.parameters
    }
    
    #if SQLEncrypted
    public func expressionSQL(_ db: Database, encryptedColumns: Set<String>) -> String {
        let column = expression.getDecryptedExpressionSQL(db, encryptedColumns: encryptedColumns)
        return column + " COLLATE " + collation.collationName
    }
    #else
    public var expressionSQL: String {
        return expression.expressionSQL + " COLLATE " + collation.collationName
    }
    #endif
}

public struct SQLFunctionExpression: SQLSubExpression {
    var function: SQLFunction
    var arguments: SQLExpression
    
    public init(_ function: SQLFunction, arguments: SQLExpression) {
        self.function = function
        self.arguments = arguments
    }
    
    public var parameters: [DatabaseValueConvertible?] {
        return arguments is SQLSubExpression ? arguments.parameters : []
    }
    
    #if SQLEncrypted
    public func expressionSQL(_ db: Database, encryptedColumns: Set<String>) -> String {
        let column = arguments.getDecryptedExpressionSQL(db, encryptedColumns: encryptedColumns)
        return function.rawValue + "(" + column + ")"
    }
    #else
    public var expressionSQL: String {
        return function.rawValue + "(" + arguments.expressionSQL + ")"
    }
    #endif
}

public enum SQLRange {
    case range
    case closedRange
}

public struct SQLRangeExpression: SQLSubExpression {
    var expression: SQLExpression
    var range: SQLRange
    var lowerBound: DatabaseValueConvertible
    var upperBound: DatabaseValueConvertible
    var negated: Bool
    
    public init(expression: SQLExpression, range: SQLRange, lowerBound: DatabaseValueConvertible, upperBound: DatabaseValueConvertible, negated: Bool = false) {
        self.expression = expression
        self.range = range
        self.lowerBound = lowerBound
        self.upperBound = upperBound
        self.negated = negated
    }
    
    public var parameters: [DatabaseValueConvertible?] {
        return [lowerBound, upperBound]
    }
    
    #if SQLEncrypted
    public func expressionSQL(_ db: Database, encryptedColumns: Set<String>) -> String {
        let column = expression.getDecryptedExpressionSQL(db, encryptedColumns: encryptedColumns)
        switch range {
        case .range:
            if negated {
                return column + " < ? AND " + column + " >= ?"
            } else {
                return column + " >= ? AND " + column + " < ?"
            }
        case .closedRange:
            return column + (negated ? " NOT": "") + " BETWEEN ? AND ?"
        }
    }
    #else
    public var expressionSQL: String {
        switch range {
        case .range:
            if negated {
                return expression.expressionSQL + " < ? AND \(expression.expressionSQL) >= ?"
            } else {
                return expression.expressionSQL + " >= ? AND \(expression.expressionSQL) < ?"
            }
        case .closedRange:
            return expression.expressionSQL + "\(negated ? " NOT": "") BETWEEN ? AND ?"
        }
    }
    #endif
}

public enum SQLInType {
    case array([DatabaseValueConvertible])
    case subquery(SelectQueryProtocol)
}

public struct SQLInExpression: SQLSubExpression {
    var expression: SQLExpression
    var type: SQLInType
    var negated: Bool
    
    public init(expression: SQLExpression, type: SQLInType, negated: Bool = false) {
        self.expression = expression
        self.type = type
        self.negated = negated
    }
    
    public var parameters: [DatabaseValueConvertible?] {
        switch type {
        case .array(let array):
            return array
        case .subquery(let query):
            return query.parameters
        }
    }
    
    #if SQLEncrypted
    public func expressionSQL(_ db: Database, encryptedColumns: Set<String>) -> String {
        let column = expression.getDecryptedExpressionSQL(db, encryptedColumns: encryptedColumns)
        switch type {
        case .array(let array):
            var string = String(repeating: "?,", count: array.count)
            string.removeLast()
            return column + (negated ? " NOT IN " : " IN ") + "(\(string))"
        case .subquery(let query):
            return column + (negated ? " NOT IN " : " IN ") + "(\(query.expressionSQL(db, encryptedColumns: encryptedColumns)))"
        }
    }
    #else
    public var expressionSQL: String {
        switch type {
        case .array(let array):
            var string = String(repeating: "?,", count: array.count)
            string.removeLast()
            return expression.expressionSQL + (negated ? " NOT IN " : " IN ") + "(\(string))"
        case .subquery(let query):
            return expression.expressionSQL + (negated ? " NOT IN " : " IN ") + "(\(query.expressionSQL))"
        }
    }
    #endif
}

public struct SQLAliasedExpression: SQLSubExpression {
    var expression: SQLExpression
    var alias: String
    
    public init(expression: SQLExpression, alias: String) {
        self.expression = expression
        self.alias = alias
    }
    
    public var parameters: [DatabaseValueConvertible?] {
        if let _ = expression as? SQLSubExpression {
            return expression.parameters
        }
        return []
    }
    
    #if SQLEncrypted
    public func expressionSQL(_ db: Database, encryptedColumns: Set<String>) -> String {
        let column = expression.getDecryptedExpressionSQL(db, encryptedColumns: encryptedColumns)
        return column + " AS " + alias.quotedDatabaseIdentifier
    }
    #else
    public var expressionSQL: String {
        return expression.expressionSQL + " AS " + alias.quotedDatabaseIdentifier
    }
    #endif
}


public struct JoinDefinition {
    var type: JoinType
    var source: SQLSource
    var criteria: SQLExpression
    
    init(type: JoinType, source: SQLSource, criteria: SQLExpression) {
        self.type = type
        self.source = source
        self.criteria = criteria
    }
}

extension JoinDefinition: SQLSubExpression {
    
    public var parameters: [DatabaseValueConvertible?] {
        return criteria is SQLSubExpression ? criteria.parameters : []
    }
    
    #if SQLEncrypted
    public func expressionSQL(_ db: Database, encryptedColumns: Set<String>) -> String {
        var sourceTable: String
        switch source {
        case .query(let query, _):
            sourceTable = "(" + query.expressionSQL(db, encryptedColumns: []) + ")"
        case .table(let name, _):
            sourceTable = name
        }
        return type.rawValue + " " + sourceTable + " ON " + criteria.expressionSQL(db, encryptedColumns: encryptedColumns)
    }
    #else
    public var expressionSQL: String {
        var sourceTable: String
        switch source {
        case .query(let query, _):
            sourceTable = "(" + query.expressionSQL + ")"
        case .table(let name, _):
            sourceTable = name
        }
        return type.rawValue + " " + sourceTable + " ON " + criteria.expressionSQL
    }
    #endif
}

public enum SQLSource {
    case table(name: String, alias: String?)
    case query(query: SelectQueryProtocol, alias: String?)
}

extension SQLSource: SQLSubExpression {
    public var parameters: [DatabaseValueConvertible?] {
        switch self {
        case .table: return []
        case .query(let query, _): return query.parameters
        }
    }
    
    #if SQLEncrypted
    public func expressionSQL(_ db: Database, encryptedColumns: Set<String>) -> String {
        switch self {
        case .table(let name, let alias):
            if let alias = alias {
                return name.aliased(alias).expressionSQL(db, encryptedColumns: encryptedColumns)
            }
            return name
        case .query(let query, let alias):
            if let alias = alias {
                return query.aliased(alias).expressionSQL(db, encryptedColumns: encryptedColumns)
            }
            return query.expressionSQL(db, encryptedColumns: encryptedColumns)
        }
    }
    #else
    public var expressionSQL: String {
        switch self {
        case .table(let name, let alias):
            if let alias = alias {
                return name.aliased(alias).expressionSQL
            }
            return name
        case .query(let query, let alias):
            if let alias = alias {
                return query.aliased(alias).expressionSQL
            }
            return query.expressionSQL
        }
    }
    #endif
}
