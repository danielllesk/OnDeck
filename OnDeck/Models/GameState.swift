//
//  GameState.swift
//  OnDeck
//
//  Created by Danny Eskandar on 2025-10-12.
//

import Foundation

struct GameState {
    var home: String
    var away: String
    var homeScore: Int
    var awayScore: Int
    var inning: Int
    var isTopInning: Bool
    var bases: [Bool]
    var pitcher: String
    var pitchCount: Int
    var batter: String
    var batterBalls: Int
    var batterStrikes: Int
    var batterRecord: String
}
