//
//  GoogleDrive.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 6/4/19.
//  Copyright © 2019 Menalto. All rights reserved.
//

import Foundation
import GoogleSignIn
import GoogleAPIClientForREST
import GTMSessionFetcher
import UIKit

let CLIENT_ID = "519173767662-ca9oluprutan3a2s0n619no01mlnla3a.apps.googleusercontent.com"

extension GTLRServiceTicket: Canceler { }

class GoogleDrive: NSObject, CloudProvider {
    var songsFolder: String {
        get {
            return UserDefaults.standard.child!.songsFolderId
        }
    }

    var moviesFolder: String {
        get {
            return UserDefaults.standard.child!.moviesFolderId
        }
    }

    var imagesFolder: String {
        get {
            return UserDefaults.standard.child!.imagesFolderId
        }
    }

    var name = "Google"
    
    static var instance = GoogleDrive()
    let service = GTLRDriveService()
    let signInConfig = GIDConfiguration.init(clientID: CLIENT_ID)
    var authorizer: GTMFetcherAuthorizationProtocol?
    var queue = DispatchQueue(label: "GoogleDrive")

    var isAuthenticated: Bool {
        guard let user = GIDSignIn.sharedInstance.currentUser else { return false }
        return user.grantedScopes?.contains(kGTLRAuthScopeDriveReadonly) ?? false
    }

    override init() {
        super.init()
    }
        
    func handle(_ url: URL) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
    
    func silentSignIn(callback: @escaping (Bool) -> ()) {
        if GIDSignIn.sharedInstance.hasPreviousSignIn() {
            GIDSignIn.sharedInstance.restorePreviousSignIn() { user, error in
                if error != nil {
                    callback(false)
                }
                
                self.finishSignIn() {
                    callback(true)
                }
            }
        } else {
            callback(false)
        }
    }
    
    func signIn(uiDelegate: UIViewController, callback: @escaping () -> ()) {
        if isAuthenticated {
            finishSignIn() {
                callback()
            }
        } else if GIDSignIn.sharedInstance.hasPreviousSignIn() {
            GIDSignIn.sharedInstance.restorePreviousSignIn() { user, error in
                guard error == nil else {
                    print("Error restoring previous signin: \(String(describing: error))")
                    return
                }

                self.finishSignIn() {
                    callback()
                }
            }
        } else {
            GIDSignIn.sharedInstance.signIn(with: signInConfig, presenting: uiDelegate, hint: nil, additionalScopes: [kGTLRAuthScopeDriveReadonly]) { user, error in
                guard error == nil else {
                    print("Error \(String(describing: error)) signing in with scopes")
                    return
                }

                self.finishSignIn {
                    callback()
                }
            }
        }
    }
    
    func finishSignIn(callback: @escaping () -> ()) {
        GIDSignIn.sharedInstance.currentUser?.authentication.do { authentication, error in
            guard error == nil else {
                print("Error authenticating: \(String(describing: error))")
                return
            }
            guard let authentication = authentication else {
                print("Missing authentication")
                return
            }
            self.service.authorizer = authentication.fetcherAuthorizer()
            callback()
        }
    }
    
    func signOut() {
        GIDSignIn.sharedInstance.signOut()
    }

    func list(folder id: String, callback: @escaping ([CloudFile])->()) {
        let query = GTLRDriveQuery_FilesList.query()
        query.pageSize = 1000
        query.q = "\"\(id)\" in parents and trashed=false"
        query.fields = "files/name,files/id,files/size"

        service.executeQuery(query) { (ticket, results, error) in
            if error != nil {
                print("Error executing query: \(query) with ticket \(ticket) and results \(String(describing: results)), error is \(String(describing: error))")
            }

            let cloudFiles = (results as? GTLRDrive_FileList)?.files?.map { file in
                CloudFile(name: file.name!, id: file.identifier!, size: file.size!.uint64Value)
            } ?? []
            callback(cloudFiles)
        }
    }

    func get(file id: String, callback: @escaping (Data?) -> ()) -> Canceler {
        let query = GTLRDriveQuery_FilesGet.queryForMedia(withFileId: id)
        return service.executeQuery(query) { (ticket, file, error) in
            callback((file as? GTLRDataObject)?.data)
        }
    }
}
