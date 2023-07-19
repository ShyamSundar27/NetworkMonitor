//
//  ZDatabaseMigrator.swift
//  VTComponents-iOS
//
//  Created by Imthath M on 07/03/19.
//

import Foundation

public protocol ZDatabaseMigrationDataMaperProtocol {

    func getTableName() -> String

    func getTextColumns() -> [String]?
    func getIntegerColumns() -> [String]?
    func getBoolColumns() -> [String]?
    func getBlobColumns() -> [String]?

    func getPrimaryKeyColumns() -> [String]?
    func getUniqueColumns() -> [String]?
}
