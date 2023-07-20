//
//  AppDelegate.swift
//  NetworkMonitor
//
//  Created by shyam-15059 on 19/07/23.
//

import UIKit
import ZNetworkManager
import VTComponents
import ZSqliteHelper
@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    
    func applicationDidFinishLaunching(_ application: UIApplication) {
        createDB()
        sendRequests()
        createWindow()
    }
    
    private func createWindow() {
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = NetworkCallListVC()
        window?.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        window?.makeKeyAndVisible()
        
        
//        view.translatesAutoresizingMaskIntoConstraints = false
    
    }
    
    
    func createDB() {
        
        if let userPath =  NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).last {

            let fileURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("act.db")
            let configuration = ZSqliteConfiguration(connectionMode: ZSqliteConnectionMode.pool, dbPath: fileURL.absoluteString)
            ZSqliteHelper.getShared().registerDB(configuration: configuration)
            ZSqliteHelper.getShared().createDB()
        }
        
    }
    
    func sendRequests() {
        ZActivityDataManager.shared.startTracking()
        let metaData = ZNetworkMetaData()
//        metaData.moduleName = "Contacts"
        metaData.groupId = "189587487587_getMail"
        metaData.groupActionName = "Get Mail"
        metaData.moduleName = "Contacts"
        
        ZNetworkManager.sharedInstance.sendRequestURL(method: ZHTTPMethod.GET, url: "https://connect.zoho.com/pulse/nativeapi/v1/singlream", authorization: "Zoho-oauthtoken 1002.90650ec7263c63aa54f8c6bb0c4ea6f9.5f35cfacadd15826c09e4e21c1f1a52", params: ["needAllComments": true, "streamId": 91069000000293042, "scopeID" : "91069000000002002"], delegate: nil, metadata: metaData, identifier: nil) { (data, response, _, error, _) in
            
        }
        ZNetworkManager.sharedInstance.sendRequestURL(method: ZHTTPMethod.GET, url: "https://contacts.zoho.com/syncapi/contact/photo", authorization: "Zoho-oauthtoken 1002.90650ec7263c63aa54f8c6bb0c4ea6f9.5f3cfafcadd15826c09e4e21c1f1a52", headerParams: nil, params: ["isOrg": true, "contactId": "471374000000540010", "photosize":"normal"], delegate: nil, metadata: metaData, identifier: nil, requestRedirectionHandler: nil, completionHandler: nil)
        
        ZNetworkManager.sharedInstance.sendRequestURL(method: ZHTTPMethod.GET, url: "https://contacts.zoho.com/syncapi/contact/photo", authorization: "Zoho-oauthtoken 1002.90650ec7263c63aa54f8c6bb0c4ea6f9.5f35fafcadd15826c09e4e21c1f1a52", headerParams: nil, params: ["isOrg": true, "contactId": "471374000000540010", "photosize":"normal"], delegate: nil, identifier: nil, requestRedirectionHandler: nil, completionHandler: nil)
            for _ in 0...20 {
            ZNetworkManager.sharedInstance.sendRequestURL(method: ZHTTPMethod.GET, url: "https://contacts.zoho.com/syncapi/contact/photo", authorization: "Zoho-oauthtoken 1002.90650ec7263c63aa54f8c6bb0c4ea6f9.5f35cfafadd15826c09e4e21c1f1a52", headerParams: nil, params: ["isOrg": true, "contactId": "471374000000540010", "photosize":"normal"], delegate: nil, identifier: nil, requestRedirectionHandler: nil, completionHandler: nil)
            }
        
        ZNetworkManager.sharedInstance.sendRequestURL(method: ZHTTPMethod.GET, url: "https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_10mb.mp4", params: nil, delegate: nil, identifier: nil, completionHandler: nil)
        
        let metaData2 = ZNetworkMetaData()
//        metaData2.moduleName = "Mail"
        metaData2.groupId = "mailList_28747498747848"
        metaData2.groupActionName = "Send Mail"
//        metaData2.apiName = "Test"
//        metaData2.isUserInitiated = true
        
        if #available(OSX 10.12, *) {
            Timer.init(timeInterval: 5, repeats: true, block: { (Timer) in
                ZNetworkManager.sharedInstance.sendRequestURL(method: ZHTTPMethod.GET, url: "https://contacts.zoho.com/syncapi/contact/photo", authorization: "Zoho-oauthtoken 1002.8298bd9e8b1a82851fd0d273612b5779.1c0b1873331f61f4fc00dec16968751", headerParams: nil, params: ["isOrg": true, "contactId": "471374000000540010", "photosize":"normal"], delegate: nil, metadata: metaData2, identifier: nil, requestRedirectionHandler: nil, completionHandler: nil)
            })
        } else {
            // Fallback on earlier versions
        }
            
        
        for _ in 0...50 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            ZNetworkManager.sharedInstance.sendRequestURL(method: ZHTTPMethod.GET, url: "https://contacts.zoho.com/syncapi/contact/photo", authorization: "Zoho-oauthtoken 1002.8298bd9e8b1a82851fd0d273612b5779.1c0b1873331f61fafc00dec16968751", headerParams: nil, params: ["isOrg": true, "contactId": "471374000000540010", "photosize":"normal"], delegate: nil, metadata: metaData2, identifier: nil, requestRedirectionHandler: nil, completionHandler: nil)
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
            ZNetworkManager.sharedInstance.sendRequestURL(method: ZHTTPMethod.GET, url: "https://contacts.zoho.com/syncapi/contact/photo", authorization: "Zoho-oauthtoken 1002.8298bd9e8b1a82851fd0d273612b5779.1c0b1873331f61a4fc00dec16968751", headerParams: nil, params: ["isOrg": true, "contactId": "471374000000540010", "photosize":"normal"], delegate: nil, metadata: metaData, identifier: nil, requestRedirectionHandler: nil, completionHandler: nil)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 15.0) {
            ZNetworkManager.sharedInstance.sendRequestURL(method: ZHTTPMethod.GET, url: "https://contacts.zoho.com/syncapi/contact/photo", authorization: "Zoho-oauthtoken 1002.8298bd9e8b1a82851fd0d273612b5779.1c0b1873331f6fa4fc00dec16968751", headerParams: nil, params: ["isOrg": true, "contactId": "471374000000540010", "photosize":"normal"], delegate: nil, identifier: nil, requestRedirectionHandler: nil, completionHandler: nil)
        }
        
    }


}

