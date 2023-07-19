
//
//  SelectQueryInterface.swift
//  VTDB
//
//  Created by Dal Bahadur Thapa on 17/04/18.
//  Copyright © 2018 Zoho Corp. All rights reserved.
//

import Foundation

public class SelectQuery: SelectQueryProtocol {
    var query: SelectQueryDefinition
    public var queryDefinition: QueryDefinition {
        return query
    }
    
    init(query: SelectQueryDefinition) {
        self.query = query
    }
    
    convenience init(queryDefinition: QueryDefinition) {
        self.init(query: SelectQueryDefinition(queryDefinition: queryDefinition))
    }
    
    public convenience init(table name: String, alias: String? = nil) {
        self.init(query: SelectQueryDefinition(source: .table(name: name, alias: alias)))
    }
    
    public convenience init(query: SelectQueryProtocol, alias: String? = nil) {
        self.init(query: SelectQueryDefinition(source: .query(query: query, alias: alias)))
    }
    
    @discardableResult
    public func select(_ columns: SQLExpression...) -> SelectQuery {
        return select(columns)
    }
    
    @discardableResult
    public func select(_ columns: [SQLExpression]) -> SelectQuery {
        query.select = columns
        return self
    }
    
    @discardableResult
    public func group(_ columns: String...) -> SelectQuery {
        return group(columns)
    }
    
    @discardableResult
    public func group(_ columns: [String]) -> SelectQuery {
        query.groupBy = columns
        return self
    }
    
    @discardableResult
    public func having(_ criteria: SQLExpression) -> SelectQuery {
        query.having.append(criteria)
        return self
    }
    
    @discardableResult
    func count() -> SelectQuery {
        query.select = ["COUNT(1)"]
        return self
    }
    
    @discardableResult
    public func join(_ type: JoinType = .inner, to nestedQuery: SelectQueryProtocol, criteria: SQLExpression) -> SelectQuery {
        query.joins.append(JoinDefinition(type: type, source: .query(query: nestedQuery, alias: nil), criteria: criteria))
        return self
    }
    
    @discardableResult
    public func join(_ type: JoinType = .inner, to table: String, criteria: SQLExpression) -> SelectQuery {
        query.joins.append(JoinDefinition(type: type, source: .table(name: table, alias: nil), criteria: criteria))
        return self
    }
    
    public func fetchCount(_ db: Database) throws -> Int {
        count()
        return try db.query(self)
    }
    
    public func fetchAll(_ db: Database) throws -> [[String: Any]] {
        return try db.query(self)
    }
}

extension SelectQuery {
    public func fetchOne<T: RowConvertible>(_ db: Database) throws -> T {
        limit(1)
        return try db.query(self) as T
    }
    
    public func fetchAll<T: RowConvertible>(_ db: Database) throws -> [T] {
        return try db.query(self) as [T]
    }
}
