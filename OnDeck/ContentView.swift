//
//  ContentView.swift
//  OnDeck
//
//  Created by Danny Eskandar on 2025-10-12.
//
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var statsService: MLBStatsService
    @StateObject private var viewModel = SettingsViewModel()

    private let allTeams = ["TOR", "NYY", "BOS", "LAD", "HOU", "ATL", "CHC", "SF", "PHI"]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("⚾ OnDeck")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Select teams to track:")
                .font(.headline)

            ForEach(allTeams, id: \.self) { team in
                Toggle(team, isOn: Binding(
                    get: { viewModel.trackedTeams.contains(team) },
                    set: { value in viewModel.update(team: team, selected: value) }
                ))
            }
            .toggleStyle(.checkbox)

            Spacer()

            Button("Check for Live Games") {
                statsService.checkForLiveGames(trackedTeams: viewModel.trackedTeams)
            }
            .buttonStyle(.borderedProminent)

            if let game = statsService.currentGame {
                Text("Game Live: \(game.home) vs \(game.away)")
                    .foregroundColor(.green)
            } else {
                Text("No live games right now.")
                    .foregroundColor(.gray)
            }
        }
        .padding(20)
        .frame(width: 300, height: 400)
    }
}

