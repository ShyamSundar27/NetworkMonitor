//
//  CGFloatExtension.swift
//  ZohoMail
//
//  Created by Robin Rajasekaran on 01/10/19.
//  Copyright © 2019 Zoho Corporation. All rights reserved.
//

import Foundation
import CoreGraphics // NOTE: imported for support of CGFloat in watchOS


extension CGFloat {
    
    public func evenCeiled() -> CGFloat {
        let value = ceil(self)
        if value.truncatingRemainder(dividingBy: 2) == 0 {
            return value
        } else {
            return value + 1
        }
    }
}


