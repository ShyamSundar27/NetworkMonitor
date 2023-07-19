//
//  StringExtension.swift
//  NetworkTesting
//
//  Created by Rahul T on 10/01/17.
//  Copyright © 2017 Zoho Corporation. All rights reserved.
//

import Foundation

extension String
{
    public func encodeValue() -> String
    {
        //Altered characterSet to encode additional invalid characters (Narayanan U)
        
        let charSet: CharacterSet = CharacterSet(charactersIn: "=+&:,'\"#%/<>?@\\^`{|} ")//CharacterSet.urlQueryAllowed // or use inverted set of "=+&:,'\"#%/<>?@\\^`{|}"
        let result: String = self.addingPercentEncoding(withAllowedCharacters: charSet.inverted)!
        return result
    }
    
    public func encodeURL() -> String {
        return addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
    }
}
