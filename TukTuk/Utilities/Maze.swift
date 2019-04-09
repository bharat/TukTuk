//
//  Maze.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 4/9/19.
//  Copyright © 2019 Menalto. All rights reserved.
//

import Foundation

func +(_ pos: Maze.Position, _ delta: Maze.Delta) -> Maze.Position {
    return Maze.Position(row: pos.row + delta.row, col: pos.col + delta.col)
}

//  Adapted from: https://rosettacode.org/wiki/Maze_generation#Swift
class Maze {
    let cols: Int
    let rows: Int
    var maze: [[Int]]

    struct Position: Equatable, Hashable {
        var row: Int
        var col: Int

    }
    typealias Path = [Position]
    typealias Delta = Position

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

        var delta: Delta {
            switch self {
            case .up:    return Delta(row:  1, col:  0)
            case .down:  return Delta(row: -1, col:  0)
            case .right: return Delta(row:  0, col:  1)
            case .left:  return Delta(row:  0, col: -1)
            }
        }
    }

    init(cols: Int, rows: Int) {
        self.cols = cols
        self.rows = rows
        self.maze = Array(repeating: Array(repeating: 0, count: cols), count: rows)
        generate(Position(row: 0, col: 0))
    }

    private func generate(_ coord: Position) {
        for direction in Direction.allCases.shuffled() {
            let new = coord + direction.delta
            if inBounds(new) && maze[new.row][new.col] == 0 {
                maze[coord.row][coord.col] |= direction.rawValue
                maze[new.row][new.col] |= direction.opposite.rawValue
                generate(new)
            }
        }
    }

    func solve(from src: Position, to dst: Position, path: Path = []) -> Path? {
        if src == dst {
            return path
        }

        var paths: [Path?] = []
        for dir in Direction.allCases {
            let candidate = src + dir.delta
            if legalMove(from: src, direction: dir) && inBounds(candidate) && !path.contains(candidate) {
                paths += [solve(from: candidate, to: dst, path: path + [candidate])]
            }
        }
        return paths.compactMap { $0 }.sorted { $0.count < $1.count }.first
    }

    private func legalMove(from src: Position, direction: Direction) -> Bool {
        return maze[src.row][src.col] & direction.rawValue > 0
    }

    private func inBounds(_ coord: Position) -> Bool {
        return inBounds(value: coord.col, upper: cols) && inBounds(value: coord.row, upper: rows)
    }

    private func inBounds(value: Int, upper: Int) -> Bool {
        return (value >= 0) && (value < upper)
    }
}
