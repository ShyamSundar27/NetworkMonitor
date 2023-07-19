//
//  UpdateQuery.swift
//  VTDB
//
//  Created by Dal Bahadur Thapa on 17/04/18.
//  Copyright © 2018 Zoho Corp. All rights reserved.
//

import Foundation

public class UpdateQuery: QueryInterfaceProtocol {
    var query: UpdateQueryDefintion
    
    public var queryDefinition: QueryDefinition {
        return query
    }
    
    init(query: UpdateQueryDefintion) {
        self.query = query
    }
    
    convenience init(queryDefinition: QueryDefinition) {
        self.init(query: UpdateQueryDefintion(queryDefinition: queryDefinition))
    }
    
    public convenience init(table: String) {
        self.init(query: UpdateQueryDefintion(table: table))
    }
    
    @discardableResult
    public func onConflict(_ conflictResolution: Database.ConflictResolution) -> UpdateQuery {
        query.conflictResolution = conflictResolution
        return self
    }
    
    @discardableResult
    public func set(column: String, with expressions: SQLExpression) -> UpdateQuery {
        query.set(column: column, with: expressions)
        return self
    }
    
    @discardableResult
    public func set(_ columns: [String: DatabaseValueConvertible?]) -> UpdateQuery {
        query.set(columns)
        return self
    }
    
    @discardableResult
    public func set(_ columns: [String: SQLExpression]) -> UpdateQuery {
        query.set(columns)
        return self
    }
    
    @discardableResult
    public func set(sql: String, parameters: DatabaseValueConvertible?...) -> UpdateQuery {
        query.set(sql: sql, parameters: parameters)
        return self
    }
    
    @discardableResult
    public func set(sql: String, parameters: [DatabaseValueConvertible?]) -> UpdateQuery {
        query.set(sql: sql, parameters: parameters)
        return self
    }
    
    public func execute(_ db: Database) throws {
        try db.execute(self)
    }
}
