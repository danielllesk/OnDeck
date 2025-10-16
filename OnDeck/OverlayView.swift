//
//  OverlayView.swift
//  OnDeck
//
//  Created by Danny Eskandar on 2025-10-12.
//
import SwiftUI
import SVGView

struct OverlayView: View {
    @ObservedObject var service: MLBStatsService
    let gameID: String
    let closeAction: () -> Void

    private var game: GameState? {
        service.currentGames.first(where: { $0.id == gameID })
    }

    var body: some View {
        Group {
            if let game = game {
                content(for: game)
            } else {
                VStack(spacing: 8) {
                    HStack {
                        Text("Loading game...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Button(action: closeAction) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(12)
                .frame(width: 340, height: 180)
            }
        }
    }

    @ViewBuilder
    private func content(for game: GameState) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                TeamLogoView(teamName: game.away)
                    .frame(width: 26, height: 26)

                VStack(alignment: .leading, spacing: 1) {
                    Text(game.away)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                    Text("\(game.awayScore)")
                        .font(.title3)
                        .fontWeight(.bold)
                }

                Text("@")
                    .foregroundColor(.secondary)
                    .font(.caption)

                VStack(alignment: .leading, spacing: 1) {
                    Text(game.home)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                    Text("\(game.homeScore)")
                        .font(.title3)
                        .fontWeight(.bold)
                }

                TeamLogoView(teamName: game.home)
                    .frame(width: 26, height: 26)

                Spacer()
            }

            Divider()

            HStack(spacing: 12) {
                Label {
                    Text("Inn \(game.inning) \(game.isTopInning ? "▲" : "▼")")
                        .font(.caption)
                } icon: {
                    Image(systemName: "clock.fill")
                        .font(.caption2)
                }
                .foregroundColor(.secondary)

                Spacer()

                HStack(spacing: 4) {
                    Text("Count:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(game.batterBalls)-\(game.batterStrikes)")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
            }

            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("AT BAT")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)

                        if let batter = game.batter {
                            Text("\(batter.name) \(formattedAverage(batter.average))")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .lineLimit(1)
                            Text("Tonight: \(batter.hits)-\(batter.atBats)")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        } else {
                            Text("Loading...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 4) {
                        Text("PITCHER")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)

                        Text(game.pitcher)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .lineLimit(1)

                        Text("\(game.pitchCount) pitches")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: 6) {
                    Text("BASES")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                    BasesView(bases: game.bases)
                    OutsView(outs: game.outs)
                }
            }
        }
        .padding(12)
        .frame(width: 340, height: 200)
    }

    private func formattedAverage(_ avg: Double) -> String {
        if avg <= 0 { return ".000" }
        return String(format: ".%03d", Int((avg * 1000).rounded()))
    }
}


struct BasesView: View {
    let bases: [Bool]

    var body: some View {
        ZStack {
            Base(isOccupied: bases.count > 1 && bases[1])
                .offset(y: -18)
            Base(isOccupied: bases.count > 2 && bases[2])
                .offset(x: -18)
            Base(isOccupied: bases.count > 0 && bases[0])
                .offset(x: 18)
        }
        .frame(width: 60, height: 60)
    }
}

struct Base: View {
    let isOccupied: Bool
    var body: some View {
        Rectangle()
            .fill(isOccupied ? Color.yellow : Color.white)
            .frame(width: 14, height: 14)
            .rotationEffect(.degrees(45))
            .overlay(
                Rectangle()
                    .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                    .rotationEffect(.degrees(45))
            )
    }
}

struct OutsView: View {
    let outs: Int
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<3) { idx in
                if idx < max(0, min(outs, 3)) {
                    Circle()
                        .fill(Color.primary)
                        .frame(width: 8, height: 8)
                } else {
                    Circle()
                        .stroke(Color.primary.opacity(0.6), lineWidth: 1)
                        .frame(width: 8, height: 8)
                }
            }
        }
        .padding(.top, 6)
    }
}

struct TeamLogoView: View {
    let teamName: String
    let size: CGFloat

    init(teamName: String, size: CGFloat = 30) {
        self.teamName = teamName
        self.size = size
    }

    var body: some View {
        let urlString = logoURL(for: teamName)
        if let url = URL(string: urlString) {
            SVGView(contentsOf: url)
                .frame(width: size, height: size)
                .clipShape(Circle())
        } else {
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: size, height: size)
        }
    }
}



