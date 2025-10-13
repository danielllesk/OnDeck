//
//  OverlayView.swift
//  OnDeck
//
//  Created by Danny Eskandar on 2025-10-12.
//
import SwiftUI

struct OverlayView: View {
    var game: GameState
    var closeAction: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(game.away)
                                .fontWeight(.bold)
                            Spacer()
                            Text("\(game.awayScore)")
                                .fontWeight(.bold)
                        }
                        HStack {
                            Text(game.home)
                                .fontWeight(.bold)
                            Spacer()
                            Text("\(game.homeScore)")
                                .fontWeight(.bold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    VStack(spacing: 2) {
                        Image(systemName: "chevron.up")
                            .opacity(game.isTopInning ? 1 : 0.2)
                            .foregroundColor(.yellow)
                        Text("\(game.inning)")
                            .font(.headline)
                        Image(systemName: "chevron.down")
                            .opacity(game.isTopInning ? 0.2 : 1)
                            .foregroundColor(.yellow)
                    }
                }

                Divider().background(Color.gray)

                // BASES logic EDIT BRO
                HStack(spacing: 10) {
                    BaseDiamond(
                        first: game.bases[0],
                        second: game.bases[1],
                        third: game.bases[2]
                    )
                    Spacer()
                    VStack(alignment: .trailing, spacing: 3) {
                        Text("P: \(game.pitcher)")
                        Text("PC: \(game.pitchCount)")
                        Text("Batter: \(game.batter)")
                        Text("\(game.batterBalls)-\(game.batterStrikes)")
                        Text(game.batterRecord)
                    }
                    .font(.system(size: 10))
                    .foregroundColor(.white)
                }

            }
            .padding(10)
            .frame(width: 260)
            .background(
                LinearGradient(colors: [.black, .gray.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .cornerRadius(14)
            .shadow(radius: 6)

            Button(action: closeAction) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
                    .font(.title3)
                    .padding(6)
            }
        }
    }
}

struct BaseDiamond: View {
    var first: Bool
    var second: Bool
    var third: Bool

    var body: some View {
        ZStack {
            // diamond drawing
            Rectangle()
                .fill(Color.clear)
                .frame(width: 40, height: 40)
            ZStack {
                Base(filled: second)
                    .offset(y: -15)
                Base(filled: third)
                    .offset(x: -15)
                Base(filled: first)
                    .offset(x: 15)
                Base(filled: false)
            }
        }
    }
}

struct Base: View {
    var filled: Bool

    var body: some View {
        Rectangle()
            .fill(filled ? Color.yellow : Color.white)
            .frame(width: 10, height: 10)
            .rotationEffect(.degrees(45))
            .shadow(radius: 1)
    }
}
