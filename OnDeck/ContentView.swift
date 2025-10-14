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
        VStack(alignment: .leading, spacing: 20) {
            Text("Select Teams to Track")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.bottom, 5)
            
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(availableTeams) { team in
                        HStack(spacing: 12) {
                            AsyncImage(url: URL(string: team.logoURL)) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 32, height: 32)
                                case .failure(_), .empty:
                                    Circle()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: 32, height: 32)
                                        .overlay(
                                            ProgressView()
                                                .scaleEffect(0.5)
                                        )
                                @unknown default:
                                    Circle()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: 32, height: 32)
                                }
                            }

                            Text(team.name)
                                .font(.body)

                            Spacer()

                            if selectedTeams.contains(team) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.title3)
                            }
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if selectedTeams.contains(team) {
                                selectedTeams.remove(team)
                            } else {
                                selectedTeams.insert(team)
                            }
                        }
                        
                        if team.id != availableTeams.last?.id {
                            Divider()
                                .padding(.leading, 60)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: 400)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(10)

            Button(action: {
                if let data = try? JSONEncoder().encode(Array(selectedTeams)) {
                    trackedTeamsData = String(data: data, encoding: .utf8) ?? "[]"
                }
                mlbService.startTracking(teams: Array(selectedTeams.map { $0.name }))
            }) {
                Label("Save & Start Tracking", systemImage: "baseball.fill")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Divider()
                .padding(.vertical, 5)

            VStack(alignment: .leading, spacing: 10) {
                Text("Live Games (\(mlbService.currentGames.count))")
                    .font(.headline)
                
                if mlbService.currentGames.isEmpty {
                    HStack {
                        Image(systemName: "moon.stars.fill")
                            .foregroundColor(.secondary)
                        Text("No live games right now.")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
                } else {
                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(mlbService.currentGames, id: \.id) { game in
                                Button(action: {
                                    mlbService.showOverlay(for: game)
                                }) {
                                    VStack(alignment: .leading, spacing: 10) {
                                        HStack(spacing: 12) {
                                            TeamLogoView(teamName: game.away)
                                                .frame(width: 32, height: 32)

                                            Text(game.away)
                                                .font(.body)
                                                .fontWeight(.semibold)
                                                .lineLimit(1)

                                            Text("@")
                                                .foregroundColor(.secondary)
                                                .font(.subheadline)

                                            Text(game.home)
                                                .font(.body)
                                                .fontWeight(.semibold)
                                                .lineLimit(1)

                                            TeamLogoView(teamName: game.home)
                                                .frame(width: 32, height: 32)
                                        }

                                        HStack(spacing: 20) {
                                            Label("\(game.awayScore) - \(game.homeScore)", systemImage: "sportscourt.fill")
                                                .font(.subheadline)
                                            
                                            Label("Inning \(game.inning) \(game.isTopInning ? "▲" : "▼")", systemImage: "clock.fill")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color.accentColor.opacity(0.1))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .frame(maxHeight: 150)
                }
            }
        }
        .padding(24)
        .frame(width: 450, height: 700)
        .onAppear {
            selectedTeams = Set(trackedTeamsArray)
        }
    }
}
