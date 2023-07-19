//
//  QueryInterface.swift
//  VTDB
//
//  Created by Dal Bahadur Thapa on 18/12/17.
//  Copyright © 2017 Zoho Corp. All rights reserved.
//

import Foundation

public protocol QueryInterfaceProtocol: AnyObject, SQLSubExpression {
    var queryDefinition: QueryDefinition { get }
    func filter(_ criteria: SQLExpression) -> Self
    func filter(_ critiera: [String: DatabaseValueConvertible?]) -> Self
    func filter(sql: String, parameters: DatabaseValueConvertible?...) -> Self
    func filter(sql: String, parameters: [DatabaseValueConvertible?]) -> Self
    func order(_ columns: SQLExpression...) -> Self
    func order(_ columns: [SQLExpression]) -> Self
    func limit(_ limit: Int, offset: Int) -> Self
    func limit(_ limit: Int) -> Self
    func offset(_ offset: Int) -> Self
}

extension QueryInterfaceProtocol {
    public var parameters: [DatabaseValueConvertible?] {
        return queryDefinition.parameters()
    }
    
    #if SQLEncrypted
    public func expressionSQL(_ db: Database, encryptedColumns: Set<String>) -> String {
        return queryDefinition.sql(db)
    }
    #else
    public var expressionSQL: String {
        return queryDefinition.sql()
    }
    #endif
}

extension QueryInterfaceProtocol {
    @discardableResult
    public func filter(_ criteria: SQLExpression) -> Self {
        queryDefinition.filter(criteria)
        return self
    }
    
    @discardableResult
    public func filter(_ critiera: [String: DatabaseValueConvertible?]) -> Self {
        queryDefinition.filter(critiera)
        return self
    }
    
    @discardableResult
    public func filter(sql: String, parameters: DatabaseValueConvertible?...) -> Self {
        queryDefinition.filter(sql: sql, parameters: parameters)
        return self
    }
    
    @discardableResult
    public func filter(sql: String, parameters: [DatabaseValueConvertible?]) -> Self {
        queryDefinition.filter(sql: sql, parameters: parameters)
        return self
    }
    
    @discardableResult
    public func order(_ columns: SQLExpression...) -> Self {
        queryDefinition.order(columns)
        return self
    }
    
    @discardableResult
    public func order(_ columns: [SQLExpression]) -> Self {
        queryDefinition.order(columns)
        return self
    }
    
    @discardableResult
    public func limit(_ limit: Int, offset: Int) -> Self {
        queryDefinition.limit(limit, offset: offset)
        return self
    }
    
    @discardableResult
    public func offset(_ offset: Int) -> Self {
        queryDefinition.offset(offset)
        return self
    }
    
    @discardableResult
    public func limit(_ limit: Int) -> Self {
        queryDefinition.limit(limit)
        return self
    }
}

public protocol SelectQueryProtocol: QueryInterfaceProtocol {}

public class Query: SelectQueryProtocol {
    var query: QueryDefinition
    public var queryDefinition: QueryDefinition {
        return query
    }
    
    public var queryDefintion: QueryDefinitionProtocol {
        return query
    }
    
    init(query: QueryDefinition) {
        self.query = query
    }
    
    public convenience init(table name: String) {
        self.init(query: QueryDefinition(source: .table(name: name, alias: nil)))
    }
    
    // MARK: SelectQueryInterface
    func all() -> SelectQuery {
        return SelectQuery(queryDefinition: query)
    }
    
    @discardableResult
    public func select(_ columns: SQLExpression...) -> SelectQuery {
        return select(columns)
    }
    
    @discardableResult
    public func select(_ columns: [SQLExpression]) -> SelectQuery {
        return all().select(columns)
    }
    
    @discardableResult
    public func group(_ columns: String...) -> SelectQuery {
        return group(columns)
    }
    
    @discardableResult
    public func group(_ columns: [String]) -> SelectQuery {
        return all().group(columns)
    }
    
    @discardableResult
    public func having(_ criteria: SQLExpression) -> SelectQuery {
        return all().having(criteria)
    }
    
    @discardableResult
    public func join(_ type: JoinType = .inner, to nestedQuery: SelectQuery, criteria: SQLExpression) -> SelectQuery {
        return join(type, to: "(\(nestedQuery.expressionSQL))", criteria: criteria)
    }
    
    @discardableResult
    public func join(_ type: JoinType = .inner, to table: String, criteria: SQLExpression) -> SelectQuery {
        return all().join(type, to: table, criteria: criteria)
    }
    
    public func fetchCount(_ db: Database) throws -> Int {
        return try all().fetchCount(db)
    }
    
    public func fetchAll(_ db: Database) throws -> [[String: Any]] {
        return try all().fetchAll(db)
    }
    
    // MARK: Update Query
    @discardableResult
    public func set(column: String, with expressions: SQLExpression) -> UpdateQuery {
        return UpdateQuery(queryDefinition: query).set(column: column, with: expressions)
    }
    
    @discardableResult
    public func set(_ columns: [String: DatabaseValueConvertible?]) -> UpdateQuery {
        return UpdateQuery(queryDefinition: query).set(columns)
    }
    
    @discardableResult
    public func set(_ columns: [String: SQLExpression]) -> UpdateQuery {
        return UpdateQuery(queryDefinition: query).set(columns)
    }
    
    @discardableResult
    public func set(sql: String, parameters: DatabaseValueConvertible?...) -> UpdateQuery {
        return UpdateQuery(queryDefinition: query).set(sql: sql, parameters: parameters)
    }
    
    @discardableResult
    public func set(sql: String, parameters: [DatabaseValueConvertible?]) -> UpdateQuery {
        return UpdateQuery(queryDefinition: query).set(sql: sql, parameters: parameters)
    }
    
    public func update(_ db: Database) throws {
        let updateQuery = UpdateQuery(queryDefinition: query)
        try updateQuery.execute(db)
    }
    
    // MARK: Delete Query
    public func delete(_ db: Database) throws {
        let deleteQuery = DeleteQuery(queryDefinition: query)
        try deleteQuery.execute(db)
    }
}

extension Query {

    public func fetchOne<T: RowConvertible>(_ db: Database) throws -> T? {
        return try all().fetchOne(db)
    }
    
    public func fetchAll<T: RowConvertible>(_ db: Database) throws -> [T] {
        return try all().fetchAll(db)
    }
}
