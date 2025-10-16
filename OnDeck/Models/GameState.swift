//
//  GameState.swift
//  OnDeck
//
//  Created by Danny Eskandar on 2025-10-12.
//
import Foundation

struct Batter {
    let name: String
    let average: Double
    let hits: Int
    let atBats: Int
}

struct GameState: Identifiable {
    let id: String
    let home: String
    let away: String
    let homeScore: Int
    let awayScore: Int
    let inning: Int
    let isTopInning: Bool
    let pitcher: String
    let pitchCount: Int
    let batterBalls: Int
    let batterStrikes: Int
    let bases: [Bool]
    let batter: Batter?
    let status: String 
}

