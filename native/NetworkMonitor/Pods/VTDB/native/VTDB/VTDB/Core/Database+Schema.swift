//
//  Database+Schema.swift
//  VTDB
//
//  Created by Dal Bahadur Thapa on 20/12/17.
//  Copyright © 2017 Zoho Corp. All rights reserved.
//

import Foundation

extension Database {
    public func columns(in table: String) throws -> [ColumnInfo] {
        if let columnInfos = schemaCache.columnInfos(table) {
            return columnInfos
        } else {
            let columnInfos = try ColumnInfo.fetchAll(self, sql: "PRAGMA table_info(\(table))")
            schemaCache.set(columnInfos: columnInfos, forTable: table)
            return columnInfos
        }
    }
    
    public func tableExists(_ tableName: String) throws -> Bool {
        let sql = "SELECT 1 FROM (SELECT type, name FROM sqlite_master UNION ALL SELECT type, name FROM sqlite_temp_master) WHERE type='table' AND name = ? COLLATE NOCASE"
        return try query(sql, tableName).isEmpty
    }
    
    public func drop(table name: String, ifExists: Bool = false) throws {
        if ifExists {
            try execute("DROP TABLE IF EXISTS \(name.quotedDatabaseIdentifier)")
        } else {
            try execute("DROP TABLE \(name.quotedDatabaseIdentifier)")
        }
    }
    
    public func rename(table name: String, to newName: String) throws {
        try execute("ALTER TABLE \(name.quotedDatabaseIdentifier) RENAME TO \(newName.quotedDatabaseIdentifier)")
    }
    
    public func primaryKey(of table: String) throws -> [String]? {
        if let primaryKey = schemaCache.primaryKey(table) {
            return primaryKey
        }
        
        let columnInfos = try columns(in: table)
        let primaryKeys = columnInfos.filter { $0.primaryKeyIndex != 0 }.map { $0.name }
        schemaCache.set(primaryKey: primaryKeys, forTable: table)
        return primaryKeys
    }
    
    public func create(table name: String, columns: [String: ColumnType], primaryKey: [String] = [],
                       uniqueKeys: [[String]] = [], ifNotExists: Bool = true, mapColumn: Bool = false) throws {
        try create(table: name, ifNotExists: ifNotExists, mapColumn: mapColumn) { t in
            for (name, type) in columns {
                t.column(name, type)
            }
            if !primaryKey.isEmpty {
                t.primaryKey(primaryKey)
            }
            uniqueKeys.forEach { t.uniqueKey($0) }
        }
    }
    
    
    #if SQLEncrypted
    /// Encrypts the specified columns in table. Encryption must be set in Configuration. Call this method from write or writeInTransaction closure.
    ///
    /// - Parameters:
    ///   - name: table name
    ///   - columns: columns to be encrypted
    /// - Throws: DatabaseError
    public func encrypt(table name: String, columns: [String]) throws {
        var columnsToEncrypt: [String] = []
        if let encryptedColumns = try self.encryptedColumns(in: name) {
            columnsToEncrypt = columns.filter { !encryptedColumns.contains($0.lowercased()) }
        } else {
            columnsToEncrypt = columns
        }
        if columnsToEncrypt.isEmpty {
            return
        }
        let encryption = VTDBConstants.Table.Encryption.self
        let values = columnsToEncrypt.map { [encryption.Columns.tableName: name, encryption.Columns.columnName: $0.lowercased()] }
        try insert(intoTable: encryption.tableName, values: values, onConflict: .ignore)
        let query = "UPDATE \(name) SET " + columnsToEncrypt.map { "\($0) = encrypt(\($0))"}.joined(separator: ", ")
        try execute(query)
        schemaCache.set(encryptedColumns: nil, forTable: name)
    }
    
    
    /// Decrypts the specified columns in table. Encryption must be set in Configuration. Call this method write or writeInTransaction closure.
    ///
    /// - Parameters:
    ///   - name: table name
    ///   - columns: columns to be decrypted
    /// - Throws: DatabaseError
    public func decrypt(table name: String, columns: [String]) throws {
        guard let encryptedColumns = try self.encryptedColumns(in: name) else {
            return
        }
        let columnsToDecrypt = columns.filter { encryptedColumns.contains($0.lowercased()) }
        if columnsToDecrypt.isEmpty {
            return
        }
        let encryption = VTDBConstants.Table.Encryption.self
        let deleteQuery = DeleteQuery(table: encryption.tableName).filter(Column(encryption.Columns.tableName) == name && encryption.Columns.columnName.contains(columnsToDecrypt))
        let query = "UPDATE \(name) SET " + columnsToDecrypt.map { "\($0) = decrypt(\($0))"}.joined(separator: ", ")
        try execute(query)
        try execute(deleteQuery)
        schemaCache.set(encryptedColumns: nil, forTable: name)
    }
    
    public func encryptedColumns(in table: String) throws -> Set<String>? {
        if let columns = schemaCache.encryptedColumns(table) {
            return columns
        }
        let Encryption = VTDBConstants.Table.Encryption.self
        let records: [String] = try query("SELECT \(Encryption.Columns.columnName) FROM \(Encryption.tableName) WHERE \(Encryption.Columns.tableName) = ?", table)
        if records.isEmpty {
            return nil
        }
        let columns: Set<String> = Set(records)
        schemaCache.set(encryptedColumns: columns, forTable: table)
        return columns
    }
    #endif
    
    public func mapColumn(of table: String, with columnMap: [String: ColumnType]) throws {
        if columnMap.isEmpty { return }
        let columnMaps: [[DatabaseValueConvertible]] = columnMap.map { [table, $0.key, $0.value] }
        try insert(intoTable: VTDBConstants.Table.ColumnMap.tableName, values: columnMaps, onConflict: .replace)
    }
    
    public func delete(columnMap table: String) throws {
        try execute("DELETE FROM \(VTDBConstants.Table.ColumnMap.tableName) WHERE \(VTDBConstants.Table.ColumnMap.Columns.tableName) = ?", table)
    }
    
    public func columnTypes(of table: String) throws -> [String: ColumnType] {
        if let columnTypes = schemaCache.columnTypes(table: table) {
            return columnTypes
        }
        let ColumnMap = VTDBConstants.Table.ColumnMap.self
        let records: [[String]] = try query("SELECT \(ColumnMap.Columns.columnName), \(ColumnMap.Columns.columnType) FROM \(ColumnMap.tableName) WHERE \(ColumnMap.Columns.tableName) = ?", table)
        var columnTypes: [String: ColumnType] = [:]
        for record in records {
            if let columnType = ColumnType(rawValue: record[1]) {
                columnTypes[record[0]] = columnType
            }
        }
        schemaCache.set(columnTypes: columnTypes, forTable: table)
        return columnTypes
        
    }
    
    public func columnTypes(fromSQL sql: String) throws -> [String: ColumnType] {
        if let columnTypes = schemaCache.columnTypes(sql: sql) {
            return columnTypes
        }
        var query = sql
        // MARK: Regex
        let columnConstant = ColumnMapConstant.sharedInstance
        // Replacing newlines and double space with single space and making query into single line
        query.replace(regex: columnConstant.singleLine, with: " ")
        // Replacing nested queries with ($)
        query.replace(regex: columnConstant.nestedQuery, with: "($)")
        
        // MARK: Table Mapping
        // [Alias: TableName]
        var tableAliasMapping: [String: String] = [:]
        var tableExpressions = query.matchingStrings(regex: columnConstant.table)
        if let lastTable = query.split(regex: columnConstant.lastTable).last {
            if let last = tableExpressions.last, lastTable.hasPrefix(last) {
                // do nothing
            } else {
                tableExpressions.append(String(lastTable))
            }
        }
        
        for expression in tableExpressions {
            for table in expression.split(regex: columnConstant.commaSplit) {
                let tableName = table.split(regex: columnConstant.aliasSplit).map { $0.trimmingCharacters(in: columnConstant.characterSet) }
                // [TableName, Alias] or [TableName, TableName]
                tableAliasMapping[tableName.last!.lowercased()] = tableName.first!
            }
        }
        // MARK: Column Mapping
        // Getting selected columns from query
        let selectedColumns = query.replacingOccurrences(regex: columnConstant.keepOnlySelectColumn, with: "")
        if selectedColumns == "*" {
            var queryColumnTypes: [String: ColumnType] = [:]
            // Todo: Prioritize base table
            for table in tableAliasMapping.allValues {
                let mappedColumns = try columnTypes(of: table)
                queryColumnTypes.merge(mappedColumns) { current, _ in current }
            }
            schemaCache.set(columnTypes: queryColumnTypes, forSQL: sql)
            return queryColumnTypes
        }
        var columns: [Column] = []
        for columnExpression in selectedColumns.split(regex: columnConstant.commaSplit) {
            // Splitting column and alias names
            let expression = columnExpression.split(regex: columnConstant.aliasSplit).map { $0.trimmingCharacters(in: columnConstant.characterSet) }
            // Splitting schema, table amd column names
            let tableName = expression.first!.split(regex: columnConstant.schemaSplit)
            let column = Column(tableName.last!)
            if tableName.count > 1 {
                column.tableName = tableAliasMapping[tableName[tableName.count - 2].lowercased()]
            }
            if tableName.count > 2 {
                column.schema = tableName[tableName.count - 3]
            }
            if expression.count == 2 {
                column.alias = expression.last
            }
            columns.append(column)
        }
        
        // Fetch table column type
        var tableColumnMap: [String: [String: ColumnType]] = [:]
        try tableAliasMapping.allValues.forEach {
            tableColumnMap[$0] = try columnTypes(of: $0)
        }
        
        var queryColumnType: [String: ColumnType] = [:]
        for column in columns {
            if let tableName = column.tableName {
                if let columnMap = tableColumnMap[tableName], let type = columnMap[column.columnName.lowercased()] {
                    queryColumnType[column.alias ?? column.columnName] = type
                }
                continue
            }
            for (_, columnMap) in tableColumnMap {
                if let type = columnMap[column.columnName.lowercased()] {
                    queryColumnType[column.alias?.lowercased() ?? column.columnName.lowercased()] = type
                    continue
                }
            }
        }
        schemaCache.set(columnTypes: queryColumnType, forSQL: sql)
        return queryColumnType
    }
}

public struct ColumnInfo: RowConvertible {
    public var name: String
    public var type: String
    public var notNull: Bool
    // var defaultValue: String?
    public var primaryKeyIndex: Int
    
    public init(row: Row) throws {
        name = row["name"]
        type = row["type"]
        notNull = row["notnull"]
        primaryKeyIndex = row["pk"]
        // defaultValue = row["dflt_value"]
    }
}

extension ColumnInfo: CustomStringConvertible {
    public var description: String {
        return "<name: \(name) type: \(type) notNull: \(notNull) pkIndex: \(primaryKeyIndex)>"
    }
}
