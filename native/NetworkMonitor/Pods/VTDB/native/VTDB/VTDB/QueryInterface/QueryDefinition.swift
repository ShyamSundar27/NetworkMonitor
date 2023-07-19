//
//  Query.swift
//  VTDB
//
//  Created by Dal Bahadur Thapa on 19/12/17.
//  Copyright © 2017 Zoho Corp. All rights reserved.
//

import Foundation

public enum JoinType: String {
    case cross = "CROSS JOIN"
    case inner = "JOIN"
    case left = "LEFT OUTER JOIN"
}

public enum BindTemplate: String {
    case `default` = "?" //?
    case colon = ":" //:VVVV
    case at = "@" //@VVV
    case dollar = "$" //$VVV
}

public protocol QueryDefinitionProtocol: AnyObject {
    var source: SQLSource { get }
    var filter: [SQLExpression] { get }
    var orderBy: [SQLExpression] { get }
    var limit: Int? { get }
    var offset: Int? { get }
    #if SQLEncrypted
    func sql(_ db: Database) -> String
    #else
    func sql() -> String
    #endif
    func parameters() -> [DatabaseValueConvertible?]
}

public class QueryDefinition: QueryDefinitionProtocol {
    public private(set) var source: SQLSource
    public private(set) var filter: [SQLExpression] = []
    public private(set) var orderBy: [SQLExpression] = []
    public private(set) var limit: Int?
    public private(set) var offset: Int? {
        didSet {
            if limit == nil {
                limit = -1
            }
        }
    }
    
    init(source: SQLSource) {
        self.source = source
    }
    
    init(table name: String) {
        self.source = .table(name: name, alias: nil)
    }
    
    init(queryDefinition: QueryDefinition) {
        self.source = queryDefinition.source
        self.filter = queryDefinition.filter
        self.orderBy = queryDefinition.orderBy
        self.limit = queryDefinition.limit
        self.offset = queryDefinition.offset
    }
    
    #if SQLEncrypted
    public func sql(_ db: Database) -> String {
        var encryptedColumns: Set<String> = []
        var columnInfos: [ColumnInfo] = []
        if case .table(let tableName, _) = source, let _ = db.encryption {
            encryptedColumns = try! db.encryptedColumns(in: tableName) ?? []
            columnInfos = try! db.columns(in: tableName)
        }
        var query = "SELECT "
        if !encryptedColumns.isEmpty {
            query += columnInfos.map {
                if encryptedColumns.contains($0.name.lowercased()) {
                    return "decrypt(" + $0.name + ") " + $0.name
                } else {
                    return $0.name
                }
            }.joined(separator: ", ")
        } else {
            query += "*"
        }
        
        query += " FROM " + source.expressionSQL(db, encryptedColumns: [])
        if !filter.isEmpty {
            query += " WHERE " + filter.map { $0.expressionSQL(db, encryptedColumns: encryptedColumns) }.joined(separator: " AND ")
        }
        if !orderBy.isEmpty {
            query += " ORDER BY " + orderBy.map { $0.expressionSQL(db, encryptedColumns: encryptedColumns) }.joined(separator: ", ")
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
    public func sql() -> String {
        var query = "SELECT * FROM " + source.expressionSQL
        if !filter.isEmpty {
            query += " WHERE " + filter.map { $0.expressionSQL }.joined(separator: " AND ")
        }
        if !orderBy.isEmpty {
            query += " ORDER BY " + orderBy.map { $0.expressionSQL }.joined(separator: ", ")
        }
        if limit != nil {
            query += " LIMIT ?"
            if offset != nil {
                query += " OFFSET ?"
            }
        }
        return query
    }
    #endif
    
    public func parameters() -> [DatabaseValueConvertible?] {
        var parameters: [DatabaseValueConvertible?] = []
        add(expressions: filter, to: &parameters)
        add(expressions: orderBy, to: &parameters)
        if let limit = limit {
            parameters.append(limit)
            if let offset = offset {
                parameters.append(offset)
            }
        }
        return parameters
    }
    
    func filter(_ criteria: SQLExpression) {
        filter.append(criteria)
    }
    
    func filter(_ criteria: [String: DatabaseValueConvertible?]) {
        for (key, value) in criteria {
            filter.append(key == value)
        }
    }
    
    func filter(sql: String, parameters: [DatabaseValueConvertible?]) {
        let customSQL = CustomSQLExpression(rawExpression: sql, parameters: parameters)
        filter.append(customSQL)
    }
    
    func order(_ columns: [SQLExpression]) {
        orderBy.append(contentsOf: columns)
    }
    
    func limit(_ limit: Int, offset: Int) {
        self.limit = limit
        self.offset = offset
    }
    
    func limit(_ limit: Int) {
        self.limit = limit
    }
    
    func offset(_ offset: Int) {
        self.offset = offset
    }
    
    func add(expressions: [SQLExpression], to parameters: inout [DatabaseValueConvertible?]) {
        expressions.forEach {
            if let _ = $0 as? SQLSubExpression {
                parameters.append(contentsOf: $0.parameters)
            }
        }
    }
}
