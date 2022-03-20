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
    static var instance = GoogleDrive()
    let service = GTLRDriveService()
    let signInConfig = GIDConfiguration.init(clientID: CLIENT_ID)
    var authorizer: GTMFetcherAuthorizationProtocol?
    var queue = DispatchQueue(label: "GoogleDrive")

    var songsFolder = "1cE63ZqcSU8cY6nnZ7RPG4Z5EPV0nwuMz"
    var moviesFolder = "1vbYHlO5bQbym9g8wSg8GYlF42-LMIv2W"

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
    
    func silentSignIn() {
        GIDSignIn.sharedInstance.restorePreviousSignIn() { user, error in 
            self.setupAuthorizer()
        }
    }
    
    func signIn(uiDelegate: UIViewController) {
        if !isAuthenticated {
            GIDSignIn.sharedInstance.signIn(with: signInConfig, presenting: uiDelegate)
            
            GIDSignIn.sharedInstance.addScopes([kGTLRAuthScopeDriveReadonly], presenting: uiDelegate) { user, error in
                guard let user = user else {
                    print("Error missing user at Google signin")
                    return
                }
                
                guard error == nil else {
                    print("Error signing in as \(user): \(String(describing: error))")
                    return
                }

                self.setupAuthorizer()
            }
        }
    }
    
    func setupAuthorizer() {
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

//extension GoogleDrive: GIDSignInDelegate {
//    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
//
//        if let error = error {
//          if (error as NSError).code == GIDSignInErrorCode.hasNoAuthInKeychain.rawValue {
//            print("The user has not signed in before or they have since signed out.")
//          } else {
//            print("\(error.localizedDescription)")
//          }
//          return
//        }
//
//        GoogleDrive.instance.service.authorizer = user.authentication.fetcherAuthorizer()
//    }
//}
