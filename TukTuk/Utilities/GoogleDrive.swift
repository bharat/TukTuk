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

let CLIENT_ID = "519173767662-ca9oluprutan3a2s0n619no01mlnla3a.apps.googleusercontent.com"

class GoogleDrive: NSObject, CloudProvider {
    static var instance = GoogleDrive()
    let service = GTLRDriveService()

    var songsFolder = "1cE63ZqcSU8cY6nnZ7RPG4Z5EPV0nwuMz"
    var moviesFolder = "1vbYHlO5bQbym9g8wSg8GYlF42-LMIv2W"

    var isAuthenticated: Bool {
        return GIDSignIn.sharedInstance().currentUser != nil
    }

    override init() {
        super.init()
        
        GIDSignIn.sharedInstance().clientID = CLIENT_ID
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().scopes = [kGTLRAuthScopeDriveReadonly]
    }

    func signIn(uiDelegate: GIDSignInUIDelegate? = nil) {
        if let uiDelegate = uiDelegate {
            GIDSignIn.sharedInstance().uiDelegate = uiDelegate
            GIDSignIn.sharedInstance().signIn()
        } else {
            GIDSignIn.sharedInstance().signInSilently()
        }
    }

    func signOut() {
        GIDSignIn.sharedInstance().signOut()
    }

    func list(folder id: String) -> [CloudFile]? {
        var files: [CloudFile]?
        let query = GTLRDriveQuery_FilesList.query()
        query.pageSize = 1000
        query.q = "\"\(id)\" in parents"
        query.fields = "files/name,files/id,files/size"

        let ticket = service.executeQuery(query) { (ticket, results, error) in
            files = (results as? GTLRDrive_FileList)?.files?.map { file in
                CloudFile(name: file.name!, id: file.identifier!, size: file.size!)
            }
        }
        service.wait(for: ticket, timeout: 300)

        return files
    }

    func get(file id: String) -> Data? {
        let data = get(files: [id])
        return data[id]!
    }

    func get(files ids: [String]) -> [String:Data?] {
        var data: [String:Data?] = [:]
        var tickets = [GTLRServiceTicket]()

        ids.forEach { id in
            let query = GTLRDriveQuery_FilesGet.queryForMedia(withFileId: id)

            data[id] = nil
            let ticket = service.executeQuery(query) { (ticket, file, error) in
                data[id] = (file as? GTLRDataObject)?.data
            }
            tickets.append(ticket)
        }

        tickets.forEach { ticket in
            service.wait(for: ticket, timeout: 300)
        }

        return data
    }
}

extension GoogleDrive: GIDSignInDelegate {
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if let _ = error {
            GoogleDrive.instance.service.authorizer = nil
        } else {
            GoogleDrive.instance.service.authorizer = user.authentication.fetcherAuthorizer()
        }
    }
}
