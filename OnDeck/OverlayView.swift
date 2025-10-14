//
//  OverlayView.swift
//  OnDeck
//
//  Created by Danny Eskandar on 2025-10-12.
//
import SwiftUI

struct OverlayView: View {
    let game: GameState
    let closeAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {

            HStack(spacing: 6) {
                TeamLogoView(teamName: game.away)
                Text(game.away)
                    .font(.headline)
                Text("vs")
                    .foregroundColor(.secondary)
                Text(game.home)
                    .font(.headline)
                TeamLogoView(teamName: game.home)

                Spacer()

                Button(action: closeAction) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }

            Divider()

            HStack {
                Text("Score: \(game.homeScore) - \(game.awayScore)")
                    .font(.subheadline)
                Spacer()
                Text("Inning: \(game.inning) \(game.isTopInning ? "▲" : "▼")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            HStack(alignment: .center, spacing: 16) {

                VStack(alignment: .leading, spacing: 2) {
                    let battingAverage = Double.random(in: 0.200...0.350)
                    Text("Batter: \(String(game.batter)) (\(game.batterRecord)), \(String(format: "%.3f", battingAverage))")
                    Text("Pitcher: \(game.pitcher)")
                    Text("Pitch Count: \(game.pitchCount)")
                    Text("Count: \(game.batterBalls)-\(game.batterStrikes)")
                }
                .font(.caption)
                .foregroundColor(.secondary)

                BasesView(bases: game.bases)
            }
        }
        .padding(10)
        .frame(width: 240)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(NSColor.windowBackgroundColor))
                .shadow(radius: 6)
        )
    }
}

// MARK: - Bases View
struct BasesView: View {
    let bases: [Bool]

    var body: some View {
        ZStack {
            Base(isOccupied: bases.count > 1 && bases[1])
                .offset(y: -12)
            Base(isOccupied: bases.count > 0 && bases[0])
                .offset(x: 12)
            Base(isOccupied: bases.count > 2 && bases[2])
                .offset(x: -12)
            Base(isOccupied: false)
                .offset(y: 12)
        }
        .frame(width: 50, height: 50)
    }
}

struct Base: View {
    let isOccupied: Bool
    var body: some View {
        Rectangle()
            .fill(isOccupied ? Color.green : Color.gray.opacity(0.3))
            .frame(width: 12, height: 12)
            .rotationEffect(.degrees(45))
    }
}

struct TeamLogoView: View {
    let teamName: String

    var body: some View {
        if let logoURL = logoURL(for: teamName), let url = URL(string: logoURL) {
            AsyncImage(url: url) { img in
                img.resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .clipShape(Circle())
            } placeholder: {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 22, height: 22)
            }
        }
    }
}
