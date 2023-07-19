//
//  SelectQueryDefinition.swift
//  VTDB
//
//  Created by Dal Bahadur Thapa on 17/04/18.
//  Copyright © 2018 Zoho Corp. All rights reserved.
//

import Foundation

final class SelectQueryDefinition: QueryDefinition {
    var select: [SQLExpression] = []
    var groupBy: [String] = []
    var having: [SQLExpression] = []
    var joins: [JoinDefinition] = []
    var isDistinct: Bool = false
    
    #if SQLEncrypted
    override func sql(_ db: Database) -> String {
        var encryptedColumns: Set<String> = []
        var columnInfos: [ColumnInfo] = []
        if case .table(let tableName, _) = source, let _ = db.encryption {
            encryptedColumns = try! db.encryptedColumns(in: tableName) ?? []
            columnInfos = try! db.columns(in: tableName)
        }
        var query = "SELECT "
        if isDistinct {
            query += "DISTINCT "
        }
        if select.count > 0 {
            query += select.map {
                if let exp = $0 as? SQLRawExpression {
                    if encryptedColumns.contains(exp.rawExpression.lowercased()) {
                        return "decrypt(" + exp.rawExpression + ") " + exp.rawExpression
                    } else {
                        return exp.rawExpression
                    }
                } else if let column = $0 as? Column {
                    let sql = column.expressionSQL(db, encryptedColumns: encryptedColumns)
                    if sql == column.name {
                        return sql
                    } else {
                        return sql + column.name
                    }
                } else {
                    return $0.expressionSQL(db, encryptedColumns: encryptedColumns)
                }
            }.joined(separator: ", ")
        } else {
            if encryptedColumns.isEmpty {
                query.append("*")
            } else {
                query += columnInfos.map {
                    if encryptedColumns.contains($0.name.lowercased()) {
                        return "decrypt(" + $0.name + ") " + $0.name
                    } else {
                        return $0.name
                    }
                }.joined(separator: ", ")
            }
        }
        query += " FROM " + source.expressionSQL(db, encryptedColumns: encryptedColumns)
        if !joins.isEmpty {
            query += " " + joins.map { $0.expressionSQL(db, encryptedColumns: encryptedColumns) }.joined(separator: " ")
        }
        if !filter.isEmpty {
            query += " WHERE " + filter.map {
                $0.expressionSQL(db, encryptedColumns: encryptedColumns)
                }.joined(separator: " AND ")
        }
        if !groupBy.isEmpty {
            query += " GROUP BY " + groupBy.map {
                if encryptedColumns.contains($0.lowercased()) {
                    return "decrypt(" + $0 + ")"
                }
                return $0
                }.joined(separator: ", ")
        }
        if !having.isEmpty {
            query += " HAVING " + having.map {
                $0.expressionSQL(db, encryptedColumns: encryptedColumns)
                }.joined(separator: " AND ")
        }
        if !orderBy.isEmpty {
            query += " ORDER BY " + orderBy.map {
                $0.getDecryptedExpressionSQL(db, encryptedColumns: encryptedColumns)
                
                }.joined(separator: ", ")
        }
        if limit != nil {
            query += " LIMIT ?"
        }
        if offset != nil {
            query += " OFFSET ?"
        }
        return query
    }
    #else
    override func sql() -> String {
        var query = "SELECT "
        if isDistinct {
            query += "DISTINCT "
        }
        if select.count > 0 {
            query += select.map { $0.expressionSQL }.joined(separator: ", ")
        } else {
            query += "*"
        }
        query += " FROM " + source.expressionSQL
        if !joins.isEmpty {
            query += " " + joins.map { $0.expressionSQL }.joined(separator: " ")
        }
        if !filter.isEmpty {
            query += " WHERE " + filter.map { $0.expressionSQL }.joined(separator: " AND ")
        }
        if !groupBy.isEmpty {
            query += " GROUP BY " + groupBy.map { $0 }.joined(separator: ", ")
        }
        if !having.isEmpty {
            query += " HAVING " + having.map { $0.expressionSQL }.joined(separator: " AND ")
        }
        if !orderBy.isEmpty {
            query += " ORDER BY " + orderBy.map { return $0.expressionSQL }.joined(separator: ", ")
        }
        if limit != nil {
            query += " LIMIT ?"
        }
        if offset != nil {
            query += " OFFSET ?"
        }
        return query
    }
    #endif
    
    override func parameters() -> [DatabaseValueConvertible?] {
        var parameters: [DatabaseValueConvertible?] = []
        
        add(expressions: select, to: &parameters)
        parameters.append(contentsOf: source.parameters)
//        add(expressions: source, to: &parameters)
        add(expressions: joins, to: &parameters)
        add(expressions: filter, to: &parameters)
        add(expressions: having, to: &parameters)
        add(expressions: orderBy, to: &parameters)
        if let limit = limit {
            parameters.append(limit)
            if let offset = offset {
                parameters.append(offset)
            }
        }
        return parameters
    }
}
