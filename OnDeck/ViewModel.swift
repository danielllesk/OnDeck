//
//  ViewModel.swift
//  OnDeck
//
//  Created by Danny Eskandar on 2025-10-12.
//
import SwiftUI

@MainActor
class SettingsViewModel: ObservableObject {
    @AppStorage("trackedTeams") private var trackedTeamsString: String = ""

    var trackedTeams: [String] {
        get { trackedTeamsString.split(separator: ",").map(String.init) }
        set { trackedTeamsString = newValue.joined(separator: ",") }
    }

    func update(team: String, selected: Bool) {
        var updated = trackedTeams
        if selected {
            if !updated.contains(team) { updated.append(team) }
        } else {
            updated.removeAll { $0 == team }
        }
        trackedTeams = updated
    }
}

