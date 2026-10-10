//
//  MLBTeams.swift
//  OnDeck
//
//  Created by Danny Eskandar on 2025-10-13.
//

import Foundation

struct MLBTeam: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let logoURL: String
}

let allTeams: [MLBTeam] = [
    MLBTeam(id: "NYY", name: "Yankees", logoURL: "https://www.mlbstatic.com/team-logos/147.svg"),
    MLBTeam(id: "TOR", name: "Blue Jays", logoURL: "https://www.mlbstatic.com/team-logos/141.svg"),
    MLBTeam(id: "BOS", name: "Red Sox", logoURL: "https://www.mlbstatic.com/team-logos/111.svg"),
    MLBTeam(id: "BAL", name: "Orioles", logoURL: "https://www.mlbstatic.com/team-logos/110.svg"),
    MLBTeam(id: "TB", name: "Rays", logoURL: "https://www.mlbstatic.com/team-logos/139.svg"),
    MLBTeam(id: "HOU", name: "Astros", logoURL: "https://www.mlbstatic.com/team-logos/117.svg"),
    MLBTeam(id: "TEX", name: "Rangers", logoURL: "https://www.mlbstatic.com/team-logos/140.svg"),
    MLBTeam(id: "SEA", name: "Mariners", logoURL: "https://www.mlbstatic.com/team-logos/136.svg"),
    MLBTeam(id: "LAA", name: "Angels", logoURL: "https://www.mlbstatic.com/team-logos/108.svg"),
    MLBTeam(id: "LVA", name: "Athletics", logoURL: "https://www.mlbstatic.com/team-logos/133.svg"),
    MLBTeam(id: "LAD", name: "Dodgers", logoURL: "https://www.mlbstatic.com/team-logos/119.svg"),
    MLBTeam(id: "SF", name: "Giants", logoURL: "https://www.mlbstatic.com/team-logos/137.svg"),
    MLBTeam(id: "CHC", name: "Cubs", logoURL: "https://www.mlbstatic.com/team-logos/112.svg"),
    MLBTeam(id: "STL", name: "Cardinals", logoURL: "https://www.mlbstatic.com/team-logos/138.svg"),
    MLBTeam(id: "ATL", name: "Braves", logoURL: "https://www.mlbstatic.com/team-logos/144.svg"),
    MLBTeam(id: "NYM", name: "Mets", logoURL: "https://www.mlbstatic.com/team-logos/121.svg"),
    MLBTeam(id: "PHI", name: "Phillies", logoURL: "https://www.mlbstatic.com/team-logos/143.svg"),
    MLBTeam(id: "WAS", name: "Nationals", logoURL: "https://www.mlbstatic.com/team-logos/120.svg"),
    MLBTeam(id: "CLE", name: "Guardians", logoURL: "https://www.mlbstatic.com/team-logos/114.svg"),
    MLBTeam(id: "DET", name: "Tigers", logoURL: "https://www.mlbstatic.com/team-logos/116.svg"),
    MLBTeam(id: "MIN", name: "Twins", logoURL: "https://www.mlbstatic.com/team-logos/142.svg"),
    MLBTeam(id: "CWS", name: "White Sox", logoURL: "https://www.mlbstatic.com/team-logos/145.svg"),
    MLBTeam(id: "KC", name: "Royals", logoURL: "https://www.mlbstatic.com/team-logos/118.svg"),
    MLBTeam(id: "ARI", name: "Diamondbacks", logoURL: "https://www.mlbstatic.com/team-logos/109.svg"),
    MLBTeam(id: "SD", name: "Padres", logoURL: "https://www.mlbstatic.com/team-logos/135.svg"),
    MLBTeam(id: "COL", name: "Rockies", logoURL: "https://www.mlbstatic.com/team-logos/115.svg"),
    MLBTeam(id: "FLA", name: "Marlins", logoURL: "https://www.mlbstatic.com/team-logos/146.svg"),
    MLBTeam(id: "PIT", name: "Pirates", logoURL: "https://www.mlbstatic.com/team-logos/134.svg"),
    MLBTeam(id: "CIN", name: "Reds", logoURL: "https://www.mlbstatic.com/team-logos/113.svg"),
    MLBTeam(id: "MIL", name: "Brewers", logoURL: "https://www.mlbstatic.com/team-logos/158.svg")
]

func logoURL(for team: String) -> String {
    let needle = team.lowercased()
    let matches = allTeams.filter { entry in
        let name = entry.name.lowercased()
        return needle == name || needle.contains(name) || name.contains(needle)
    }
    if let best = matches.max(by: { $0.name.count < $1.name.count }) {
        return best.logoURL
    }
    return "https://www.mlbstatic.com/team-logos/1.svg"
}
