//
//  CloudProvider.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 6/9/19.
//  Copyright © 2019 Menalto. All rights reserved.
//

import Foundation

protocol CloudProvider {
    var isAuthenticated: Bool { get }

    func getSongs(done: @escaping (Song.CloudDict) -> ())
    func download(_ song: Song.Cloud) -> Song.Temporary?

    func getMovies(done: @escaping (Movie.CloudDict) -> ())
    func download(_ movie: Movie.Cloud) -> Movie.Temporary?
}
