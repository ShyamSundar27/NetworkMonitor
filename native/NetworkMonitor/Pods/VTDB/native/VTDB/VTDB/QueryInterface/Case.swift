//
//  Case.swift
//  VTDB
//
//  Created by Dal Bahadur Thapa on 21/12/17.
//  Copyright © 2017 Zoho Corp. All rights reserved.
//

import Foundation

public final class Case: SQLSubExpression {
    var column: String?
    var conditions: [(when: SQLExpression, do: SQLExpression)] = []
    var otherwise: SQLExpression?
    public private(set) var parameters: [DatabaseValueConvertible?] = []
    
    public init(_ column: String? = nil) {
        self.column = column
    }
    
    @discardableResult
    public func when(_ criteria: SQLExpression, then: SQLExpression) -> Case {
        parameters.append(contentsOf: criteria.parameters)
        parameters.append(contentsOf: then.parameters)
        conditions.append((when: criteria, do: then))
        return self
    }
    
    @discardableResult
    public func otherwise(_ expression: SQLExpression) -> Case {
        parameters.append(contentsOf: expression.parameters)
        otherwise = expression
        return self
    }
    
    
    #if SQLEncrypted
    public func expressionSQL(_ db: Database, encryptedColumns: Set<String>) -> String {
        var chunks: [String] = []
        chunks.append("CASE")
        if let column = column {
            if encryptedColumns.contains(column.lowercased()) {
                chunks.append("decrypt(\(column))")
            } else {
                chunks.append(column)
            }
        }
        for condition in conditions {
            chunks.append("WHEN")
            if condition.when is SQLSubExpression {
                chunks.append(condition.when.expressionSQL(db, encryptedColumns: encryptedColumns))
            } else {
                chunks.append("?")
            }
            chunks.append("THEN")
            if condition.do is SQLSubExpression {
                chunks.append(condition.do.expressionSQL(db, encryptedColumns: encryptedColumns))
            } else {
                chunks.append("?")
            }
        }
        if let otherwise = otherwise {
            chunks.append("ELSE")
            if otherwise is SQLSubExpression {
                chunks.append(otherwise.expressionSQL(db, encryptedColumns: encryptedColumns))
            } else {
                chunks.append("?")
            }
        }
        chunks.append("END")
        return chunks.joined(separator: " ")
    }
    #else
    public var expressionSQL: String {
        var chunks: [String] = []
        chunks.append("CASE")
        if let column = column {
            chunks.append(column)
        }
        for condition in conditions {
            chunks.append("WHEN")
            if condition.when is SQLSubExpression {
                chunks.append(condition.when.expressionSQL)
            } else {
                chunks.append("?")
            }
            chunks.append("THEN")
            if condition.do is SQLSubExpression {
                chunks.append(condition.do.expressionSQL)
            } else {
                chunks.append("?")
            }
        }
        if let otherwise = otherwise {
            chunks.append("ELSE")
            if otherwise is SQLSubExpression {
                chunks.append(otherwise.expressionSQL)
            } else {
                chunks.append("?")
            }
        }
        chunks.append("END")
        return chunks.joined(separator: " ")
    }
    #endif
}
