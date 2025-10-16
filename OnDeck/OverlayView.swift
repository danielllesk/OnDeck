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
        service.currentGames.first { $0.id == gameID }
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
                    .frame(width: 24, height: 24)

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
                    .frame(width: 24, height: 24)

                Spacer()

                Button(action: closeAction) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }

            Divider()

            // Inning + count
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

                        if game.pitchCount > 0 {
                            Text("\(game.pitchCount) pitches")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Right column: Bases drawing
                VStack(spacing: 4) {
                    Text("BASES")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                    BasesView(bases: game.bases)
                }
            }
        }
        .padding(12)
        .frame(width: 340, height: 180)
    }

    private func formattedAverage(_ avg: Double) -> String {

        String(format: "%.3f", avg).hasPrefix("0") ?
            String(format: ".%03d", Int((avg * 1000).rounded())) :
            String(format: "%.3f", avg)
    }
}



struct BasesView: View {
    let bases: [Bool]

    var body: some View {
        ZStack {
            Base(isOccupied: bases.count > 1 && bases[1])
                .offset(y: -18)

            Base(isOccupied: bases.count > 2 && bases[2])
                .offset(x: -18, y: 0)
            Base(isOccupied: bases.count > 0 && bases[0])
                .offset(x: 18, y: 0)
        }
        .frame(width: 60, height: 60)
    }
}

struct Base: View {
    let isOccupied: Bool
    var body: some View {
        Rectangle()
            .fill(isOccupied ? Color.yellow : Color.white.opacity(0.6))
            .frame(width: 14, height: 14)
            .rotationEffect(.degrees(45))
            .overlay(
                Rectangle()
                    .stroke(Color.primary.opacity(0.15), lineWidth: 1)
                    .rotationEffect(.degrees(45))
            )
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


