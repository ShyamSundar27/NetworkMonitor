//
//  TableMapping.swift
//  VTDB
//
//  Created by Dal Bahadur Thapa on 18/12/17.
//  Copyright © 2017 Zoho Corp. All rights reserved.
//

import Foundation

public protocol TableMapping {
    static var databaseTableName: String { get }
}

extension TableMapping {
    static func all() -> Query {
        return Query(query: QueryDefinition(source: .table(name: databaseTableName, alias: nil)))
    }
    
    // MARK: QueryInterface
    public static func filter(_ criteria: SQLExpression) -> Query  {
        return all().filter(criteria)
    }
    
    public static func filter(_ criteria: [String: DatabaseValueConvertible?]) -> Query {
        return all().filter(criteria)
    }
    
    public static func order(_ columns: SQLExpression...) -> Query {
        return order(columns)
    }
    
    public static func order(_ columns: [SQLExpression]) -> Query {
        return all().order(columns)
    }
    
    public static func limit(_ limit: Int, offset: Int) -> Query  {
        return all().limit(limit, offset: offset)
    }
    
    public static func offset(_ offset: Int) -> Query {
        return all().offset(offset)
    }
    
    public static func limit(_ limit: Int) -> Query {
        return all().limit(limit)
    }
    
    // MARK: UpdateQuery
    @discardableResult
    public static func set(column: String, with expressions: SQLExpression) -> UpdateQuery {
        return all().set(column: column, with: expressions)
    }
    
    @discardableResult
    public static func set(_ columns: [String: DatabaseValueConvertible?]) -> UpdateQuery {
        return all().set(columns)
    }
    
    @discardableResult
    public static func set(_ columns: [String: SQLExpression]) -> UpdateQuery {
        return all().set(columns)
    }
    
    // MARK: Delete
    public static func deleteAll(_ db: Database, criteria: SQLExpression) throws {
        try all().filter(criteria).delete(db)
    }
    
    public static func deleteAll(_ db: Database) throws {
        try all().delete(db)
    }

    // MARK: SelectQueryInterface
    public static func select(_ columns: SQLExpression...) -> SelectQuery {
        return select(columns)
    }
    
    public static func select(_ columns: [SQLExpression]) -> SelectQuery {
        return all().select(columns)
    }
    
    public static func group(_ columns: String...) -> SelectQuery {
        return group(columns)
    }
    
    public static func group(_ columns: [String]) -> SelectQuery {
        return all().group(columns)
    }
    
    public static func having(_ criteria: SQLExpression) -> SelectQuery {
        return all().having(criteria)
    }
    
    public static func join(_ type: JoinType = .inner, to nestedQuery: SelectQuery, criteria: SQLExpression) -> SelectQuery {
        return all().join(type, to: nestedQuery, criteria: criteria)
    }
    
    public static func join(_ type: JoinType = .inner, to table: String, criteria: SQLExpression) -> SelectQuery {
        return all().join(type, to: table, criteria: criteria)
    }
    
    public static func fetchCount(_ db: Database) throws -> Int {
        return try all().fetchCount(db)
    }
}

extension TableMapping where Self: RowConvertible {
    public static func fetchOne(_ db: Database) throws -> Self? {
        return try all().fetchOne(db)
    }
    
    public static func fetchAll(_ db: Database) throws -> [Self] {
        return try all().fetchAll(db)
    }
}
