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
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                TeamLogoView(teamName: game.away)
                    .frame(width: 28, height: 28)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(game.away)
                        .font(.headline)
                        .lineLimit(1)
                    Text("\(game.awayScore)")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                Text("@")
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(game.home)
                        .font(.headline)
                        .lineLimit(1)
                    Text("\(game.homeScore)")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                TeamLogoView(teamName: game.home)
                    .frame(width: 28, height: 28)

                Spacer()

                Button(action: closeAction) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }

            Divider()

            HStack(spacing: 16) {
                Label("Inning \(game.inning) \(game.isTopInning ? "▲" : "▼")", systemImage: "clock.fill")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Text("Count:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("\(game.batterBalls)-\(game.batterStrikes)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }

            HStack(alignment: .top, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("At Bat")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                        
                        if let batter = game.batter {
                            Text(batter.name)
                                .font(.callout)
                                .fontWeight(.semibold)
                                .lineLimit(1)
                            HStack(spacing: 6) {
                                Text(String(format: ".%.0f", batter.average * 1000))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("•")
                                    .foregroundColor(.secondary)
                                    .font(.caption2)
                                Text("\(batter.hits)-\(batter.atBats)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            Text("Loading...")
                                .font(.callout)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Divider()
                        .padding(.vertical, 3)
                    
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Pitcher")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                        
                        Text(game.pitcher)
                            .font(.callout)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                        
                        if game.pitchCount > 0 {
                            Text("\(game.pitchCount) pitches")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: 6) {
                    Text("Bases")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    
                    BasesView(bases: game.bases)
                }
            }
        }
        .padding(14)
        .frame(width: 380, height: 200)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(NSColor.windowBackgroundColor))
                .shadow(color: Color.black.opacity(0.3), radius: 12, x: 0, y: 4)
        )
    }
}

struct BasesView: View {
    let bases: [Bool]

    var body: some View {
        ZStack {
            Base(isOccupied: bases.count > 1 && bases[1])
                .offset(y: -20)
            
            Base(isOccupied: bases.count > 2 && bases[2])
                .offset(x: -20, y: 0)
            
            Base(isOccupied: bases.count > 0 && bases[0])
                .offset(x: 20, y: 0)
            
            Base(isOccupied: false)
                .offset(y: 20)
        }
        .frame(width: 65, height: 65)
    }
}

struct Base: View {
    let isOccupied: Bool
    var body: some View {
        Rectangle()
            .fill(isOccupied ? Color.green : Color.gray.opacity(0.3))
            .frame(width: 15, height: 15)
            .rotationEffect(.degrees(45))
            .overlay(
                Rectangle()
                    .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                    .rotationEffect(.degrees(45))
            )
    }
}

struct TeamLogoView: View {
    let teamName: String

    var body: some View {
        if let url = URL(string: logoURL(for: teamName)) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                case .failure(_):
                    placeholderView
                case .empty:
                    ProgressView()
                @unknown default:
                    placeholderView
                }
            }
        } else {
            placeholderView
        }
    }
    
    private var placeholderView: some View {
        Circle()
            .fill(Color.gray.opacity(0.3))
            .overlay(
                Image(systemName: "baseball.fill")
                    .foregroundColor(.white)
                    .font(.caption)
            )
    }
}
