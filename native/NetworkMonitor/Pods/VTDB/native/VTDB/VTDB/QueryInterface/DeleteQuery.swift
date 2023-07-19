//
//  DeleteQueryInterface.swift
//  VTDB
//
//  Created by Dal Bahadur Thapa on 17/04/18.
//  Copyright © 2018 Zoho Corp. All rights reserved.
//

import Foundation

public class DeleteQuery: QueryInterfaceProtocol {
    var query: DeleteQueryDefinition
    public var queryDefinition: QueryDefinition {
        return query
    }
    
    init(query: DeleteQueryDefinition) {
        self.query = query
    }
    
    convenience init(queryDefinition: QueryDefinition) {
        self.init(query: DeleteQueryDefinition(queryDefinition: queryDefinition))
    }
    
    public convenience init(table: String) {
        self.init(query: DeleteQueryDefinition(table: table))
    }

    public func execute(_ db: Database) throws {
        try db.execute(self)
    }
}
