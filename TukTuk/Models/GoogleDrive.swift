//
//  GoogleDRive.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 6/4/19.
//  Copyright © 2019 Menalto. All rights reserved.
//

import Foundation
import GoogleSignIn
import GoogleAPIClientForREST

let CLIENT_ID = "519173767662-ca9oluprutan3a2s0n619no01mlnla3a.apps.googleusercontent.com"
let SONGS_FOLDER_ID = "1cE63ZqcSU8cY6nnZ7RPG4Z5EPV0nwuMz"

struct CloudSong {
    var title: String
    var audioId: String
    var imageId: String
}
typealias CloudSongDict = [String:CloudSong]

class GoogleDrive: NSObject {
    static var instance = GoogleDrive()
    let service = GTLRDriveService()

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

    func getFile(id: String, completion: @escaping (Data?) -> ()) {
        let query = GTLRDriveQuery_FilesGet.queryForMedia(withFileId: id)
        service.executeQuery(query) { (ticket, file, error) in
            print("FILE \(file.debugDescription)")
            completion((file as? GTLRDataObject)?.data)
        }
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

extension GoogleDrive: GIDSignInUIDelegate {
}

extension GoogleDrive {
    func getSongs(done: @escaping (CloudSongDict) -> ()) {
        let query = GTLRDriveQuery_FilesList.query()
        query.pageSize = 1000
        query.q = "\"\(SONGS_FOLDER_ID)\" in parents"

        service.executeQuery(query) { (ticket, results, error) in
            var songs = CloudSongDict()
            if let files = (results as? GTLRDrive_FileList)?.files {
                var audio: [String:String] = [:]
                var image: [String:String] = [:]
                files.forEach { file in
                    let title = NSString(string: file.name!).deletingPathExtension
                    if file.mimeType == "audio/mp3" {
                        audio[title] = file.identifier
                    } else {
                        image[title] = file.identifier
                    }
                }
                Set(audio.keys).intersection(Set(image.keys)).forEach { title in
                    songs[title] = CloudSong(title: title, audioId: audio[title]!, imageId: image[title]!)
                }
            }
            done(songs)
        }
    }

    func download(song: CloudSong) -> TempSong? {
        var tempSong: TempSong?
        let group = DispatchGroup()
        group.enter()
        getFile(id: song.audioId) { audioData in
            self.getFile(id: song.imageId) { imageData in
                if let audioData = audioData, let imageData = imageData {
                    tempSong = TempSong(title: song.title, audioData: audioData, imageData: imageData)
                }
                group.leave()
            }
        }
        group.wait()

        return tempSong
    }
}

