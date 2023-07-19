//
//  ZUserDefaults.swift
//  ZohoMail
//
//  Created by Rahul T on 24/07/17.
//  Copyright © 2017 Zoho Corporation. All rights reserved.
//

import Foundation

public class ZUserDefaults {
    
    private static var sharedAppList: [String]?
    
    public class func setSharedApp(list: [String]) {
        sharedAppList = list
    }

    public class func setSecureString(value: String, key: String, service: String, group: String? = nil) {
        do {
            let item = KeychainPasswordItem(service: service, account: generateKey(key: key, group: group), accessGroup: nil)
            try item.savePassword(value)
        } catch {
            #if DEBUG
                print("couldn't save \(error)")
            #endif
        }
    }

    public class func secureString(key: String, service: String, group: String? = nil) -> String? {
        do {
            let item = KeychainPasswordItem(service: service, account: generateKey(key: key, group: group), accessGroup: nil)
            return try item.readPassword()
        } catch {
            #if DEBUG
                print("couldn't read \(error)")
            #endif
            return nil
        }
    }

    public class func registerDefaults(_ defaults: [String: Any], group: String? = nil, userDefaults: UserDefaults? = nil) {
        var dict: [String: Any] = [:]
        for (key, value) in defaults {
            dict[generateKey(key: key, group: group)] = value
        }
        getUserDefaults(userDefaults: userDefaults).register(defaults: dict)
    }

    public class func setString(value: String, key: String, group: String? = nil, userDefaults: UserDefaults? = nil) {
        getUserDefaults(userDefaults: userDefaults).set(value, forKey: generateKey(key: key, group: group))
        synchronize()
    }

    public class func string(key: String, group: String? = nil, userDefaults: UserDefaults? = nil) -> String? {
        return getUserDefaults(userDefaults: userDefaults).value(forKey: generateKey(key: key, group: group)) as? String
    }

    public class func setInteger(value: Int, key: String, group: String? = nil, userDefaults: UserDefaults? = nil) {
        getUserDefaults(userDefaults: userDefaults).set(value, forKey: generateKey(key: key, group: group))
        synchronize()
    }

    public class func integer(key: String, group: String? = nil, userDefaults: UserDefaults? = nil) -> Int {
        return getUserDefaults(userDefaults: userDefaults).integer(forKey: generateKey(key: key, group: group)) as Int
    }

    public class func setFloat(value: Float, key: String, group: String? = nil, userDefaults: UserDefaults? = nil) {
        getUserDefaults(userDefaults: userDefaults).set(value, forKey: generateKey(key: key, group: group))
        synchronize()
    }

    public class func float(key: String, group: String? = nil, userDefaults: UserDefaults? = nil) -> Float {
        return getUserDefaults(userDefaults: userDefaults).float(forKey: generateKey(key: key, group: group)) as Float
    }

    public class func setDouble(value: Double, key: String, group: String? = nil, userDefaults: UserDefaults? = nil) {
        getUserDefaults(userDefaults: userDefaults).set(value, forKey: generateKey(key: key, group: group))
        synchronize()
    }

    public class func double(key: String, group: String? = nil, userDefaults: UserDefaults? = nil) -> Double {
        return getUserDefaults(userDefaults: userDefaults).double(forKey: generateKey(key: key, group: group)) as Double
    }

    public class func setBool(value: Bool, key: String, group: String? = nil, userDefaults: UserDefaults? = nil) {
        getUserDefaults(userDefaults: userDefaults).set(value, forKey: generateKey(key: key, group: group))
        synchronize()
    }

    public class func bool(key: String, group: String? = nil, userDefaults: UserDefaults? = nil) -> Bool {
        return getUserDefaults(userDefaults: userDefaults).bool(forKey: generateKey(key: key, group: group)) as Bool
    }

    public class func setArray(key: String, array: [Any], group: String? = nil, userDefaults: UserDefaults? = nil) {
        getUserDefaults(userDefaults: userDefaults).set(array, forKey: generateKey(key: key, group: group))
        synchronize()
    }

    public class func appendToArray(key: String, value: Any, group: String? = nil, userDefaults: UserDefaults? = nil) {
        var tempArray = ZUserDefaults.array(key: key, group: group) ?? [Any]()
        tempArray.append(value)
        ZUserDefaults.setArray(key: key, array: tempArray, group: group)
    }

    public class func array(key: String, group: String? = nil, userDefaults: UserDefaults? = nil) -> [Any]? {
        return getUserDefaults(userDefaults: userDefaults).array(forKey: generateKey(key: key, group: group))
    }

    public class func setObject(value: Any, key: String, group: String? = nil, userDefaults: UserDefaults? = nil) {
        getUserDefaults(userDefaults: userDefaults).set(value, forKey: generateKey(key: key, group: group))
        synchronize()
    }

    public class func object(key: String, group: String? = nil, userDefaults: UserDefaults? = nil) -> Any {
        return getUserDefaults(userDefaults: userDefaults).object(forKey: generateKey(key: key, group: group)) as Any
    }

    public class func remove(key: String, group: String? = nil, userDefaults: UserDefaults? = nil) {
        getUserDefaults(userDefaults: userDefaults).removeObject(forKey: generateKey(key: key, group: group))
        synchronize()
    }

    public class func removeSecure(service: String, key: String, group: String? = nil) {
        do {
            let item = KeychainPasswordItem(service: service, account: generateKey(key: key, group: group), accessGroup: nil)
            try item.deleteItem()
        } catch {
            #if DEBUG
                print("Unable to delete \(key)-\(String(describing: group))")
            #endif
        }
    }

    public class func removeAll(userDefaults: UserDefaults? = nil) {
        if let identifier = Bundle.main.bundleIdentifier {
            getUserDefaults(userDefaults: userDefaults).removePersistentDomain(forName: identifier)
        }
    }

    public class func synchronize(userDefaults: UserDefaults? = nil) {
        getUserDefaults(userDefaults: userDefaults).synchronize()
    }

    private class func generateKey(key: String, group: String?) -> String {
        if group != nil {
            return group!+"#"+key
        }
        return key
    }

    private class func getUserDefaults(userDefaults: UserDefaults?) -> UserDefaults {
        return userDefaults ?? UserDefaults.standard
    }
}
