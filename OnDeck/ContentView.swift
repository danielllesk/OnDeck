//
//  ContentView.swift
//  OnDeck
//
//  Created by Danny Eskandar on 2025-10-12.
//
import SwiftUI

struct ContentView: View {
    @StateObject private var mlbService = MLBStatsService()
    
    @AppStorage("trackedTeams") private var trackedTeamsData: String = "[]"
    
    @State private var selectedTeams: Set<MLBTeam> = []
    @State private var availableTeams: [MLBTeam] = allTeams
    
    private var trackedTeamsArray: [MLBTeam] {
        if let data = trackedTeamsData.data(using: .utf8),
           let array = try? JSONDecoder().decode([MLBTeam].self, from: data) {
            return array
        }
        return []
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Select Teams to Track")
                .font(.headline)
                .padding(.bottom, 5)
            
            List {
                ForEach(availableTeams) { team in
                    HStack(spacing: 10) {
                        AsyncImage(url: URL(string: team.logoURL)) { img in
                            img.resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                                .clipShape(Circle())
                        } placeholder: {
                            Circle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 24, height: 24)
                        }

                        Text(team.name)
                            .font(.body)

                        Spacer()

                        if selectedTeams.contains(team) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if selectedTeams.contains(team) {
                            selectedTeams.remove(team)
                        } else {
                            selectedTeams.insert(team)
                        }
                    }
                }
            }
            .frame(width: 260, height: 300)
            .listStyle(.plain)
            .cornerRadius(8)

            Button("💾 Save & Start Tracking") {
                if let data = try? JSONEncoder().encode(Array(selectedTeams)) {
                    trackedTeamsData = String(data: data, encoding: .utf8) ?? "[]"
                }
                mlbService.startTracking(teams: Array(selectedTeams.map { $0.name }))
            }
            .buttonStyle(.borderedProminent)
            .padding(.vertical, 10)

            Divider()

            if let game = mlbService.currentGame {
                Button(action: {
                    mlbService.showOverlayIfNotVisible()
                }) {
                    VStack(alignment: .leading, spacing: 5) {
                        HStack(spacing: 5) {
                            if let homeLogo = logoURL(for: game.home),
                               let homeURL = URL(string: homeLogo) {
                                AsyncImage(url: homeURL) { img in
                                    img.resizable()
                                        .scaledToFit()
                                        .frame(width: 20, height: 20)
                                } placeholder: {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: 20, height: 20)
                                }
                            }

                            Text("\(game.home) vs \(game.away)")
                                .font(.subheadline)
                                .fontWeight(.semibold)

                            if let awayLogo = logoURL(for: game.away),
                               let awayURL = URL(string: awayLogo) {
                                AsyncImage(url: awayURL) { img in
                                    img.resizable()
                                        .scaledToFit()
                                        .frame(width: 20, height: 20)
                                } placeholder: {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: 20, height: 20)
                                }
                            }
                        }

                        Text("Score: \(game.homeScore) - \(game.awayScore)")
                            .foregroundColor(.secondary)

                        Text("Inning: \(game.inning) \(game.isTopInning ? "▲" : "▼")")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.1))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2))
                    )
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
                .padding(.top, 10)
            } else {
                Text("No live games right now.")
                    .foregroundColor(.gray)
                    .padding(.top, 10)
            }
        }
        .padding(20)
        .frame(width: 300, height: 450)
        .onAppear {
            selectedTeams = Set(trackedTeamsArray)
        }
    }
}
