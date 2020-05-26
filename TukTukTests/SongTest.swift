//
//  SongTest.swift
//  TukTukTests
//
//  Created by Bharat Mediratta on 5/24/20.
//  Copyright © 2020 Menalto. All rights reserved.
//

import Foundation
import XCTest

class MockLocalFile: LocalFileProtocol {
    var url: URL
    var exists: Bool
    var size: UInt64?

    internal init(exists: Bool, size: UInt64) {
        self.url = URL(fileURLWithPath: "")
        self.exists = exists
        self.size = size
    }
    
    func delete() {
    }
}

class MockCloudFile: CloudFileProtocol {
    var name: String
    var id: String
    var size: UInt64
    var title: String
    var ext: String

    internal init(size: UInt64) {
        self.name = ""
        self.id = ""
        self.size = size
        self.title = ""
        self.ext = ""
    }
}

class SongTest: XCTestCase {
    var song = Song(title: "[title]", displayTitle: "[displayTitle]", displayArtist: "[displayArtist]")
    var localImage: LocalFileProtocol = MockLocalFile(exists: true, size: 1)
    var cloudImage: CloudFileProtocol = MockCloudFile(size: 1)
    var localVideo: LocalFileProtocol = MockLocalFile(exists: true, size: 2)
    var cloudVideo: CloudFileProtocol = MockCloudFile(size: 2)
    var localAudio: LocalFileProtocol = MockLocalFile(exists: true, size: 3)
    var cloudAudio: CloudFileProtocol = MockCloudFile(size: 3)
    
    override func setUp() {
        song.image = nil
        song.audio = nil
        song.video = nil
        song.cloudImage = nil
        song.cloudAudio = nil
        song.cloudVideo = nil
    }
}

extension SongTest {
    func testMalformedCloudDiagnosis_MissingImage() {
        XCTAssertEqual(Optional<String>("Missing image for \"[title]\""), song.malformedCloudDiagnosis)
    }

    func testMalformedCloudDiagnosis_MissingAudioAndVideo() {
        song.cloudImage = cloudImage

        XCTAssertEqual(Optional<String>("Missing audio and video for \"[title]\""), song.malformedCloudDiagnosis)
    }

    func testMalformedCloudDiagnosis_MissingVideo() {
        song.cloudImage = cloudImage
        song.cloudAudio = cloudAudio

        XCTAssertEqual(nil, song.malformedCloudDiagnosis)
    }

    func testMalformedCloudDiagnosis_MissingAudio() {
        song.cloudImage = cloudImage
        song.cloudAudio = cloudAudio
        
        XCTAssertEqual(nil, song.malformedCloudDiagnosis)
    }

    func testMalformedCloudDiagnosis_MissingNothing() {
        song.cloudImage = cloudImage
        song.cloudAudio = cloudAudio
        song.cloudVideo = cloudVideo
        
        XCTAssertEqual(nil, song.malformedCloudDiagnosis)
    }
}

extension SongTest {
    func testHasWellFormedCloud_MissingImage() {
        XCTAssertEqual(false, song.hasWellFormedCloud)
    }

    func testHasWellFormedCloud_MissingVideoAndAudio() {
        song.cloudImage = cloudImage
        XCTAssertEqual(false, song.hasWellFormedCloud)
    }

    func testHasWellFormedCloud_HasImageAndAudio() {
        song.cloudImage = cloudImage
        song.cloudAudio = cloudAudio
        
        XCTAssertEqual(true, song.hasWellFormedCloud)
    }

    func testHasWellFormedCloud_HasImageAndVideo() {
        song.cloudImage = cloudImage
        song.cloudVideo = cloudVideo
        
        XCTAssertEqual(true, song.hasWellFormedCloud)
    }

    func testHasWellFormedCloud_HasAll() {
        song.cloudImage = cloudImage
        song.cloudVideo = cloudVideo
        song.cloudAudio = cloudAudio
        
        XCTAssertEqual(true, song.hasWellFormedCloud)
    }
}

extension SongTest {
    func testSyncAction_Delete_NoCloudImage_NoLocalImage_NoLocalAudio_NoLocalVideo() {
        XCTAssertEqual(.Delete, song.syncAction)
    }

    func testSyncAction_Delete_NoCloudImage_LocalImage_LocalAudio_LocalVideo() {
        song.image = localImage
        song.audio = localAudio
        song.video = localVideo
        
        XCTAssertEqual(.Delete, song.syncAction)
    }

    func testSyncAction_Download_HasWellFormedCloudImage_MissingLocalImage() {
        song.cloudImage = cloudImage
        song.cloudAudio = cloudAudio

        XCTAssertEqual(.Download, song.syncAction)
    }

    func testSyncAction_Download_HasWellFormedCloudImage_LocalImageDifferent() {
        song.cloudImage = cloudImage
        song.cloudAudio = cloudAudio
        song.image = localImage
        (song.image as! MockLocalFile).size = 0

        XCTAssertEqual(.Download, song.syncAction)
    }

    func testSyncAction_Delete_MatchingImage_MissingBothCloudAudioAndCloudVideo() {
        song.cloudImage = cloudImage
        song.image = localImage
        
        XCTAssertEqual(.Delete, song.syncAction)
    }

    func testSyncAction_Download_MatchingImage_HasWellFormedCloudVideo_MissingLocalVideo() {
        song.cloudImage = cloudImage
        song.image = localImage
        song.cloudVideo = cloudVideo
        
        XCTAssertEqual(.Download, song.syncAction)
    }

    func testSyncAction_Download_MatchingImage_HasWellFormedCloudVideo_LocalVideoDifferent() {
        song.cloudImage = cloudImage
        song.image = localImage
        song.cloudVideo = cloudVideo
        song.video = localVideo
        (song.video as! MockLocalFile).size = 0
        
        XCTAssertEqual(.Download, song.syncAction)
    }

    func testSyncAction_None_MatchingImage_MatchingVideo() {
        song.cloudImage = cloudImage
        song.image = localImage
        song.cloudVideo = cloudVideo
        song.video = localVideo

        XCTAssertEqual(.None, song.syncAction)
    }
    
    func testSyncAction_Download_MatchingImage_HasWellFormedCloudAudio_MissingLocalAudio() {
        song.cloudImage = cloudImage
        song.image = localImage
        song.cloudAudio = cloudAudio
        
        XCTAssertEqual(.Download, song.syncAction)
    }

    func testSyncAction_Download_MatchingImage_HasWellFormedCloudAudio_LocalAudioDifferent() {
        song.cloudImage = cloudImage
        song.image = localImage
        song.cloudAudio = cloudAudio
        song.audio = localAudio
        (song.audio as! MockLocalFile).size = 0
        
        XCTAssertEqual(.Download, song.syncAction)
    }
    
    func testSyncAction_None_MatchingImage_MatchingAudio() {
        song.cloudImage = cloudImage
        song.image = localImage
        song.cloudAudio = cloudAudio
        song.audio = localAudio

        XCTAssertEqual(.None, song.syncAction)
    }
    
    func testSyncAction_None_MatchingImage_MatchingAudio_MatchingVideo() {
        song.cloudImage = cloudImage
        song.image = localImage
        song.cloudAudio = cloudAudio
        song.audio = localAudio
        song.cloudVideo = cloudVideo
        song.video = localVideo

        XCTAssertEqual(.None, song.syncAction)
    }
}
