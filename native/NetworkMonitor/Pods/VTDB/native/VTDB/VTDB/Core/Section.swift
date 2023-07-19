//
//  Section.swift
//  VTDB iOS
//
//  Created by Dal Bahadur Thapa on 28/02/19.
//  Copyright © 2019 Zoho Corp. All rights reserved.
//

import Foundation

public struct Section<U> {
    public var group: U?
    public var items: [[String: Any]]
}
