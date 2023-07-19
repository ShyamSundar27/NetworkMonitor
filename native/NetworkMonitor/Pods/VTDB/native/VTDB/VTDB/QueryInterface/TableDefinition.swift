//
//  TableDefinition.swift
//  VTDB
//
//  Created by Dal Bahadur Thapa on 22/12/17.
//  Copyright © 2017 Zoho Corp. All rights reserved.
//

import Foundation

public extension Database {
    func create(table name: String, temporary: Bool = false, ifNotExists: Bool = false, mapColumn: Bool = false, block: (TableDefinition) -> Void) throws {
        let tableDefinition = TableDefinition(name: name, temporary: temporary, ifNotExists: ifNotExists, withoutRowID: false)
        block(tableDefinition)
        let sql = try tableDefinition.sql(self)
        
        try execute(sql)
        if mapColumn {
            var columnMap: [String: ColumnType] = [:]
            for column in tableDefinition.columns where column.type != nil {
                columnMap[column.name] = column.type
            }
            try self.mapColumn(of: name, with: columnMap)
        }
        #if SQLEncrypted
        if let _ = encryption {
            var columns = Set(tableDefinition.encryptedColumns)
            tableDefinition.columns.forEach {
                if $0.encrypt && !columns.contains($0.name) {
                    columns.insert($0.name)
                }
            }
            try encrypt(table: name, columns: Array(columns))
        }
        #endif
    }
    
    @available(iOS 8.2, OSX 10.10, *)
    func create(table name: String, temporary: Bool = false, ifNotExists: Bool = false, mapColumn: Bool = false, withoutRowID: Bool, body: (TableDefinition) -> Void) throws {
        let tableDefinition = TableDefinition(name: name, temporary: temporary, ifNotExists: ifNotExists, withoutRowID: withoutRowID)
        body(tableDefinition)
        let sql = try tableDefinition.sql(self)
        try execute(sql)
        if mapColumn {
            var columnMap: [String: ColumnType] = [:]
            for column in tableDefinition.columns where column.type != nil {
                columnMap[column.name] = column.type
            }
            try self.mapColumn(of: name, with: columnMap)
        }
        #if SQLEncrypted
        if let _ = encryption {
            var columns = Set(tableDefinition.encryptedColumns)
            tableDefinition.columns.forEach {
                if $0.encrypt && !columns.contains($0.name) {
                    columns.insert($0.name)
                }
            }
            try encrypt(table: name, columns: Array(columns))
        }
        #endif
    }
    
    func create(index name: String, on table: String, columns: [String], unique: Bool = false, ifNotExists: Bool = false) throws {
        let defintion = IndexDefinition(name: name, table: table, columns: columns, unique: unique, ifNotExists: ifNotExists, condition: nil)
        try execute(defintion.sql(self))
    }
    
    @available(iOS 8.2, OSX 10.10, *)
    func create(index name: String, on table: String, columns: [String], unique: Bool = false, ifNotExists: Bool = false, condition: SQLSubExpression?) throws {
        let defintion = IndexDefinition(name: name, table: table, columns: columns, unique: unique, ifNotExists: ifNotExists, condition: condition)
        try execute(defintion.sql(self))
    }
    
    func drop(index name: String, ifExists: Bool = false) throws {
        if ifExists {
            try execute("DROP INDEX IF EXISTS \(name.quotedDatabaseIdentifier)")
        } else {
            try execute("DROP INDEX \(name.quotedDatabaseIdentifier)")
        }
    }
}

public final class TableDefinition {
    private typealias KeyConstraint = (columns: [String], conflictResolution: Database.ConflictResolution?)
    
    private let name: String
    private let temporary: Bool
    private let ifNotExists: Bool
    private let withoutRowID: Bool
    fileprivate var columns: [ColumnDefinition] = []
    #if SQLEncrypted
    fileprivate var encryptedColumns: [String] = []
    #endif
    private var primaryKeyConstraint: KeyConstraint?
    private var uniqueKeyConstraints: [KeyConstraint] = []
    private var foreignKeyConstraints: [(columns: [String], table: String, destinationColumns: [String]?, deleteAction: Database.ForeignKeyAction?, updateAction: Database.ForeignKeyAction?, deferred: Bool)] = []
    private var checkConstraints: [SQLExpression] = []
    
    init(name: String, temporary: Bool, ifNotExists: Bool, withoutRowID: Bool) {
        self.name = name
        self.temporary = temporary
        self.ifNotExists = ifNotExists
        self.withoutRowID = withoutRowID
    }
    
    @discardableResult
    public func column(_ name: String, _ type: Database.ColumnType? = nil) -> ColumnDefinition {
        let column = ColumnDefinition(name: name, type: type)
        columns.append(column)
        return column
    }
    
    public func primaryKey(_ columns: String..., onConflict conflictResolution: Database.ConflictResolution? = nil) {
        primaryKey(columns, onConflict: conflictResolution)
    }
    
    public func primaryKey(_ columns: [String], onConflict conflictResolution: Database.ConflictResolution? = nil) {
        guard primaryKeyConstraint == nil else {
            // Programmer error
            debugPrint("can't define several primary keys")
            return
        }
        primaryKeyConstraint = (columns: columns, conflictResolution: conflictResolution)
    }
    
    #if SQLEncrypted
    public func encrypt(_ columns: [String]) {
        encryptedColumns = columns
    }
    #endif
    
    public func uniqueKey(_ columns: [String], onConflict conflictResolution: Database.ConflictResolution? = nil) {
        uniqueKeyConstraints.append((columns: columns, conflictResolution: conflictResolution))
    }
    
    public func foreignKey(_ columns: [String], references table: String, columns destinationColumns: [String]? = nil, onDelete deleteAction: Database.ForeignKeyAction? = nil, onUpdate updateAction: Database.ForeignKeyAction? = nil, deferred: Bool = false) {
        foreignKeyConstraints.append((columns: columns, table: table, destinationColumns: destinationColumns, deleteAction: deleteAction, updateAction: updateAction, deferred: deferred))
    }
    
    public func check(_ condition: SQLExpression) {
        checkConstraints.append(condition)
    }
    
    public func check(sql: String) {
        checkConstraints.append(sql)
    }
    
    fileprivate func sql(_ db: Database) throws -> String {
        var statements: [String] = []
        
        do {
            var chunks: [String] = []
            chunks.append("CREATE")
            if temporary {
                chunks.append("TEMPORARY")
            }
            chunks.append("TABLE")
            if ifNotExists {
                chunks.append("IF NOT EXISTS")
            }
            chunks.append(name.quotedDatabaseIdentifier)
            
            let primaryKeyColumns: [String]
            if let (columns, _) = primaryKeyConstraint {
                primaryKeyColumns = columns
            } else if let index = columns.firstIndex(where: { $0.primaryKey != nil }) {
                primaryKeyColumns = [columns[index].name]
            } else {
                // WITHOUT ROWID optimization requires a primary key. If the
                // user sets withoutRowID, but does not define a primary key,
                // this is undefined behavior.
                //
                // We thus can use the rowId column even when the withoutRowID
                // flag is set ;-)
                primaryKeyColumns = ["rowid"]
            }
            
            do {
                var items: [String] = []
                try items.append(contentsOf: columns.map { try $0.sql(db, tableName: name, primaryKeyColumns: primaryKeyColumns) })
                
                if let (columns, conflictResolution) = primaryKeyConstraint {
                    var chunks: [String] = []
                    chunks.append("PRIMARY KEY")
                    chunks.append("(\((columns.map { $0.quotedDatabaseIdentifier }).joined(separator: ", ")))")
                    if let conflictResolution = conflictResolution {
                        chunks.append("ON CONFLICT")
                        chunks.append(conflictResolution.rawValue)
                    }
                    items.append(chunks.joined(separator: " "))
                }
                
                for (columns, conflictResolution) in uniqueKeyConstraints {
                    var chunks: [String] = []
                    chunks.append("UNIQUE")
                    chunks.append("(\((columns.map { $0.quotedDatabaseIdentifier }).joined(separator: ", ")))")
                    if let conflictResolution = conflictResolution {
                        chunks.append("ON CONFLICT")
                        chunks.append(conflictResolution.rawValue)
                    }
                    items.append(chunks.joined(separator: " "))
                }
                
                for (columns, table, destinationColumns, deleteAction, updateAction, deferred) in foreignKeyConstraints {
                    var chunks: [String] = []
                    chunks.append("FOREIGN KEY")
                    chunks.append("(\((columns.map { $0 } as [String]).joined(separator: ", ")))")
                    chunks.append("REFERENCES")
                    if let destinationColumns = destinationColumns {
                        chunks.append("\(table)(\((destinationColumns.map { $0.quotedDatabaseIdentifier }).joined(separator: ", ")))")
                    } else if table == name {
                        chunks.append("\(table)(\((primaryKeyColumns.map { $0.quotedDatabaseIdentifier }).joined(separator: ", ")))")
                    } else {
                        let primaryKey = try db.primaryKey(of: table)!
                        chunks.append("\(table)(\((primaryKey.map { $0.quotedDatabaseIdentifier }).joined(separator: ", ")))")
                    }
                    if let deleteAction = deleteAction {
                        chunks.append("ON DELETE")
                        chunks.append(deleteAction.rawValue)
                    }
                    if let updateAction = updateAction {
                        chunks.append("ON UPDATE")
                        chunks.append(updateAction.rawValue)
                    }
                    if deferred {
                        chunks.append("DEFERRABLE INITIALLY DEFERRED")
                    }
                    items.append(chunks.joined(separator: " "))
                }
                
                for checkExpression in checkConstraints {
                    var chunks: [String] = []
                    chunks.append("CHECK")
                    chunks.append("(" + checkExpression.sql(db) + ")")
                    items.append(chunks.joined(separator: " "))
                }
                
                chunks.append("(\(items.joined(separator: ", ")))")
            }
            
            if withoutRowID {
                chunks.append("WITHOUT ROWID")
            }
            statements.append(chunks.joined(separator: " "))
        }
        
        let indexStatements = columns
            .compactMap { $0.indexDefinition(in: name) }
            .map { $0.sql(db) }
        statements.append(contentsOf: indexStatements)
        return statements.joined(separator: "; ")
    }
}

public final class ColumnDefinition {
    enum Index {
        case none
        case index
        case unique(Database.ConflictResolution)
    }
    fileprivate let name: String
    fileprivate let type: Database.ColumnType?
    #if SQLEncrypted
    fileprivate var encrypt: Bool = false
    #endif
    fileprivate var primaryKey: (conflictResolution: Database.ConflictResolution?, autoincrement: Bool)?
    private var index: Index = .none
    private var notNullConflictResolution: Database.ConflictResolution?
    private var checkConstraints: [SQLExpression] = []
    private var foreignKeyConstraints: [(table: String, column: String?, deleteAction: Database.ForeignKeyAction?, updateAction: Database.ForeignKeyAction?, deferred: Bool)] = []
    private var defaultExpression: SQLExpression?
    private var collationName: String?
    
    init(name: String, type: Database.ColumnType?) {
        self.name = name
        self.type = type
    }
    
    
    @discardableResult
    public func primaryKey(onConflict conflictResolution: Database.ConflictResolution, autoincrement: Bool = false) -> Self {
        primaryKey = (conflictResolution: conflictResolution, autoincrement: autoincrement)
        return self
    }
    
    @discardableResult
    public func primaryKey(autoincrement: Bool = false) -> Self {
        primaryKey = (conflictResolution: nil, autoincrement: autoincrement)
        return self
    }
    
    @discardableResult
    public func notNull(onConflict conflictResolution: Database.ConflictResolution? = nil) -> Self {
        notNullConflictResolution = conflictResolution ?? .abort
        return self
    }
    
    @discardableResult
    public func unique(onConflict conflictResolution: Database.ConflictResolution? = nil) -> Self {
        index = .unique(conflictResolution ?? .abort)
        return self
    }
    
    #if SQLEncrypted
    @discardableResult
    public func encrypted() -> Self {
        encrypt = true
        return self
    }
    #endif
    
    @discardableResult
    public func indexed() -> Self {
        if case .none = index {
            self.index = .index
        }
        return self
    }
    
    @discardableResult
    public func check(_ condition: (Column) -> SQLExpression) -> Self {
        checkConstraints.append(condition(Column(name)))
        return self
    }
    
    @discardableResult
    public func check(sql: String) -> Self {
        checkConstraints.append(sql)
        return self
    }
    
    @discardableResult
    public func defaults(to value: DatabaseValueConvertible) -> Self {
        defaultExpression = value.rawExpression
        return self
    }
    
    @discardableResult
    public func defaults(sql: String) -> Self {
        defaultExpression = sql
        return self
    }
    
    @discardableResult
    public func collate(_ collation: Database.Collation) -> Self {
        collationName = collation.rawValue
        return self
    }
    
    @discardableResult
    public func references(_ table: String, column: String? = nil, onDelete deleteAction: Database.ForeignKeyAction? = nil, onUpdate updateAction: Database.ForeignKeyAction? = nil, deferred: Bool = false) -> Self {
        foreignKeyConstraints.append((table: table, column: column, deleteAction: deleteAction, updateAction: updateAction, deferred: deferred))
        return self
    }
    
    fileprivate func sql(_ db: Database, tableName: String, primaryKeyColumns: [String]?) throws -> String {
        var chunks: [String] = []
        chunks.append(name.quotedDatabaseIdentifier)
        if let type = type {
            chunks.append(type.getDatabaseDatatype())
        }
        
        if let (conflictResolution, autoincrement) = primaryKey {
            chunks.append("PRIMARY KEY")
            if let conflictResolution = conflictResolution {
                chunks.append("ON CONFLICT")
                chunks.append(conflictResolution.rawValue)
            }
            if autoincrement {
                chunks.append("AUTOINCREMENT")
            }
        }
        
        switch notNullConflictResolution {
        case .none:
            break
        case .abort?:
            chunks.append("NOT NULL")
        case let conflictResolution?:
            chunks.append("NOT NULL ON CONFLICT")
            chunks.append(conflictResolution.rawValue)
        }
        
        switch index {
        case .none:
            break
        case .unique(let conflictResolution):
            switch conflictResolution {
            case .abort:
                chunks.append("UNIQUE")
            default:
                chunks.append("UNIQUE ON CONFLICT")
                chunks.append(conflictResolution.rawValue)
            }
        case .index:
            break
        }
        
        for checkConstraint in checkConstraints {
            chunks.append("CHECK")
            chunks.append("(" + checkConstraint.sql(db) + ")")
        }
        
        if let defaultExpression = defaultExpression {
            chunks.append("DEFAULT")
            chunks.append(defaultExpression.sql(db))
        }
        
        if let collationName = collationName {
            chunks.append("COLLATE")
            chunks.append(collationName)
        }
        
        for (table, column, deleteAction, updateAction, deferred) in foreignKeyConstraints {
            chunks.append("REFERENCES")
            if let column = column {
                // explicit reference
                chunks.append("\(table)(\(column))")
            } else if table.lowercased() == tableName.lowercased() {
                // implicit autoreference
                let primaryKeyColumns = try primaryKeyColumns ?? db.primaryKey(of: table)!
                chunks.append("\(table)(\((primaryKeyColumns.map { $0.quotedDatabaseIdentifier }).joined(separator: ", ")))")
            } else {
                // implicit external reference
                let primaryKeyColumns = try db.primaryKey(of: table)!
                chunks.append("\(table)(\((primaryKeyColumns.map { $0.quotedDatabaseIdentifier }).joined(separator: ", ")))")
            }
            if let deleteAction = deleteAction {
                chunks.append("ON DELETE")
                chunks.append(deleteAction.rawValue)
            }
            if let updateAction = updateAction {
                chunks.append("ON UPDATE")
                chunks.append(updateAction.rawValue)
            }
            if deferred {
                chunks.append("DEFERRABLE INITIALLY DEFERRED")
            }
        }
        
        return chunks.joined(separator: " ")
    }
    
    fileprivate func indexDefinition(in table: String) -> IndexDefinition? {
        switch index {
        case .none: return nil
        case .unique: return nil
        case .index:
            return IndexDefinition(
                name: "\(table)_on_\(name)",
                table: table,
                columns: [name],
                unique: false,
                ifNotExists: false,
                condition: nil)
        }
    }
}

private struct IndexDefinition {
    let name: String
    let table: String
    let columns: [String]
    let unique: Bool
    let ifNotExists: Bool
    let condition: SQLExpression?

    func sql(_ db: Database) -> String {
        var chunks: [String] = []
        chunks.append("CREATE")
        if unique {
            chunks.append("UNIQUE")
        }
        chunks.append("INDEX")
        if ifNotExists {
            chunks.append("IF NOT EXISTS")
        }
        chunks.append(name.quotedDatabaseIdentifier)
        chunks.append("ON")
        chunks.append("\(table.quotedDatabaseIdentifier)(\((columns.map { $0.quotedDatabaseIdentifier }).joined(separator: ", ")))")
        if let condition = condition {
            chunks.append("WHERE")
            chunks.append(condition.sql(db))
        }
        return chunks.joined(separator: " ")
    }
}
