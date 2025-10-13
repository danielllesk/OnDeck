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
    
    @State private var selectedTeams: Set<String> = []
    
    @State private var availableTeams = ["Yankees", "Blue Jays", "Dodgers", "Red Sox", "Giants", "Cubs"]
    
    private var trackedTeamsArray: [String] {
        if let data = trackedTeamsData.data(using: .utf8),
           let array = try? JSONDecoder().decode([String].self, from: data) {
            return array
        }
        return []
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Select Teams to Track")
                .font(.headline)
                .padding(.bottom, 5)

            List(selection: $selectedTeams) {
                ForEach(availableTeams, id: \.self) { team in
                    Text(team)
                        .tag(team)
                }
            }
            .frame(width: 260, height: 200)
            .listStyle(SidebarListStyle())
            .cornerRadius(8)
            .border(Color.gray.opacity(0.3))

            Button("💾 Save & Start Tracking") {
                if let data = try? JSONEncoder().encode(Array(selectedTeams)) {
                    trackedTeamsData = String(data: data, encoding: .utf8) ?? "[]"
                }
                
                mlbService.startTracking(teams: Array(selectedTeams))
            }
            .buttonStyle(.borderedProminent)
            .padding(.vertical, 10)

            Divider()

            if let game = mlbService.currentGame {
                VStack(alignment: .leading, spacing: 5) {
                    Text("📺 Game Live!")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)

                    Text("\(game.home) vs \(game.away)")
                        .font(.subheadline)

                    Text("Score: \(game.homeScore) - \(game.awayScore)")
                        .foregroundColor(.secondary)

                    Text("Inning: \(game.inning) \(game.isTopInning ? "▲" : "▼")")
                        .foregroundColor(.secondary)
                }
                .padding(.top, 10)
            } else {
                Text("No live games right now.")
                    .foregroundColor(.gray)
                    .padding(.top, 10)
            }
        }
        .padding(20)
        .frame(width: 300, height: 400)
        .onAppear {
            selectedTeams = Set(trackedTeamsArray)
        }
    }
}

