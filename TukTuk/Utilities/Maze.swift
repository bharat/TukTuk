//
//  Maze.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 4/9/19.
//  Copyright © 2019 Menalto. All rights reserved.
//

import Foundation

//  Adapted from: https://rosettacode.org/wiki/Maze_generation#Swift
class Maze {
    let columns: Int
    let rows: Int
    var maze: [[Int]]

    struct Coord: Equatable, Hashable {
        var row: Int
        var col: Int
    }
    typealias Path = [Coord]

    enum Direction: Int, CaseIterable {
        case up      =  1
        case down    =  2
        case left    =  4
        case right   =  8

        var opposite: Direction {
            switch self {
            case .up:    return .down
            case .down:  return .up
            case .left:  return .right
            case .right: return .left
            }
        }

        var diff: (y: Int, x: Int) {
            switch self {
            case .up:    return ( 1,  0)
            case .down:  return (-1,  0)
            case .right: return ( 0,  1)
            case .left:  return ( 0, -1)
            }
        }
    }

    init(columns: Int, rows: Int) {
        self.columns = columns
        self.rows = rows
        self.maze = Array(repeating: Array(repeating: 0, count: columns), count: rows)
        generate(Coord(row: 0, col: 0))
    }

    private func generate(_ coord: Coord) {
        for direction in Direction.allCases.shuffled() {
            let diff = direction.diff
            let new = Coord(row: coord.row + diff.y, col: coord.col + diff.x)
            if inBounds(new) && maze[new.row][new.col] == 0 {
                maze[coord.row][coord.col] |= direction.rawValue
                maze[new.row][new.col] |= direction.opposite.rawValue
                generate(new)
            }
        }
    }

    func solve(from src: Coord, to dst: Coord, path: Path = []) -> Path {
        if src == dst {
            return path
        }

        var paths: [Path] = []
        for dir in Direction.allCases {
            let diff = dir.diff
            let coord = Coord(row: src.row + diff.y, col: src.col + diff.x)
            if legalMove(from: src, direction: dir) && inBounds(coord) && !path.contains(coord) {
                paths += [solve(from: coord, to: dst, path: path + [coord])]
            }
        }
        return paths.sorted { $0.count < $1.count }.first!
    }

    private func legalMove(from src: Coord, direction: Direction) -> Bool {
        return maze[src.row][src.col] & direction.rawValue > 0
    }

    private func inBounds(_ coord: Coord) -> Bool {
        return inBounds(value: coord.col, upper: columns) && inBounds(value: coord.row, upper: rows)
    }

    private func inBounds(value: Int, upper: Int) -> Bool {
        return (value >= 0) && (value < upper)
    }
}
