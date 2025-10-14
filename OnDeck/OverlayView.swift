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
                        .font(.body)
                }
                .buttonStyle(.borderless)
            }

            Divider()

            HStack(spacing: 12) {
                Label("Inn \(game.inning) \(game.isTopInning ? "▲" : "▼")", systemImage: "clock.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                HStack(spacing: 3) {
                    Text("Count:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(game.batterBalls)-\(game.batterStrikes)")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
            }

            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("AT BAT")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                        
                        if let batter = game.batter {
                            Text(batter.name)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .lineLimit(1)
                            HStack(spacing: 4) {
                                Text(String(format: ".%.0f", batter.average * 1000))
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                                Text("•")
                                    .foregroundColor(.secondary)
                                    .font(.system(size: 8))
                                Text("\(batter.hits)-\(batter.atBats)")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            Text("Loading...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 2) {
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
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.windowBackgroundColor))
                .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 2)
        )
    }
}

struct BasesView: View {
    let bases: [Bool]

    var body: some View {
        ZStack {
            Base(isOccupied: bases.count > 1 && bases[1])
                .offset(y: -16)
            
            Base(isOccupied: bases.count > 2 && bases[2])
                .offset(x: -16, y: 0)
            
            Base(isOccupied: bases.count > 0 && bases[0])
                .offset(x: 16, y: 0)
            
            Base(isOccupied: false)
                .offset(y: 16)
        }
        .frame(width: 55, height: 55)
    }
}

struct Base: View {
    let isOccupied: Bool
    var body: some View {
        Rectangle()
            .fill(isOccupied ? Color.green : Color.gray.opacity(0.3))
            .frame(width: 12, height: 12)
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
        AsyncImage(url: URL(string: logoURL(for: teamName))) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFit()
            case .failure(_):
                placeholderView
            case .empty:
                ProgressView()
                    .scaleEffect(0.5)
            @unknown default:
                placeholderView
            }
        }
    }
    
    private var placeholderView: some View {
        Circle()
            .fill(Color.gray.opacity(0.3))
            .overlay(
                Image(systemName: "baseball.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 10))
            )
    }
}
