//
//  Constants.swift
//  VTDB
//
//  Created by Dal Bahadur Thapa on 31/05/18.
//  Copyright © 2018 Zoho Corp. All rights reserved.
//

import Foundation

public enum VTDBConstants {
    public static let primaryDatabase = "main"
    public static let regexSplit = "*VTDB*"
    public enum Table {
        public enum ColumnMap {
            public static let tableName = "VTDB_MAP_COLUMN"
            public enum Columns {
                public static let tableName = "table_name"
                public static let columnName = "column_name"
                public static let columnType = "column_type"
            }
        }
        public enum Encryption {
            public static let tableName = "VTDB_ENCRYPTION"
            public enum Columns {
                public static let tableName = "table_name"
                public static let columnName = "column_name"
            }
        }
    }
    public enum Encryption {
        public static let groupIdentifier = "VTDB.Encryption.Key"
        public static let customKeyServiceIdentifer = "VTDB.Encryption.CustomKey"
        public static let keyIdentifier = "key"
        public static let saltRoundsIdentifier = "saltRounds"
        public static let keyRoundsIdentifier = "keyRounds"
    }
    public enum AES {
        public static let ivLength = 16
        public static let saltLength = 64
        public static let pbkdf2MaxRound: UInt32 = 50000
    }
}
