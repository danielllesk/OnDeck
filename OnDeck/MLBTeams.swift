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
    MLBTeam(id: "NYY", name: "Yankees", logoURL: "https://a.espncdn.com/i/teamlogos/mlb/500/nyy.png"),
    MLBTeam(id: "TOR", name: "Blue Jays", logoURL: "https://a.espncdn.com/i/teamlogos/mlb/500/tor.png"),
    MLBTeam(id: "BOS", name: "Red Sox", logoURL: "https://a.espncdn.com/i/teamlogos/mlb/500/bos.png"),
    MLBTeam(id: "BAL", name: "Orioles", logoURL: "https://a.espncdn.com/i/teamlogos/mlb/500/bal.png"),
    MLBTeam(id: "TB", name: "Rays", logoURL: "https://a.espncdn.com/i/teamlogos/mlb/500/tb.png"),
    MLBTeam(id: "HOU", name: "Astros", logoURL: "https://a.espncdn.com/i/teamlogos/mlb/500/hou.png"),
    MLBTeam(id: "TEX", name: "Rangers", logoURL: "https://a.espncdn.com/i/teamlogos/mlb/500/tex.png"),
    MLBTeam(id: "SEA", name: "Mariners", logoURL: "https://a.espncdn.com/i/teamlogos/mlb/500/sea.png"),
    MLBTeam(id: "LAA", name: "Angels", logoURL: "https://a.espncdn.com/i/teamlogos/mlb/500/laa.png"),
    MLBTeam(id: "LVA", name: "Athletics", logoURL: "https://a.espncdn.com/i/teamlogos/mlb/500/oak.png"),
    MLBTeam(id: "LAD", name: "Dodgers", logoURL: "https://a.espncdn.com/i/teamlogos/mlb/500/lad.png"),
    MLBTeam(id: "SF", name: "Giants", logoURL: "https://a.espncdn.com/i/teamlogos/mlb/500/sf.png"),
    MLBTeam(id: "CHC", name: "Cubs", logoURL: "https://a.espncdn.com/i/teamlogos/mlb/500/chc.png"),
    MLBTeam(id: "STL", name: "Cardinals", logoURL: "https://a.espncdn.com/i/teamlogos/mlb/500/stl.png"),
    MLBTeam(id: "ATL", name: "Braves", logoURL: "https://a.espncdn.com/i/teamlogos/mlb/500/atl.png"),
    MLBTeam(id: "NYM", name: "Mets", logoURL: "https://a.espncdn.com/i/teamlogos/mlb/500/nym.png"),
    MLBTeam(id: "PHI",name: "Phillies", logoURL: "https://a.espncdn.com/i/teamlogos/mlb/500/phi.png"),
    MLBTeam(id: "WAS", name: "Nationals", logoURL: "https://a.espncdn.com/i/teamlogos/mlb/500/wsh.png"),
    MLBTeam(id: "CLE", name: "Guardians", logoURL: "https://a.espncdn.com/i/teamlogos/mlb/500/cle.png"),
    MLBTeam(id: "DET", name: "Tigers", logoURL: "https://a.espncdn.com/i/teamlogos/mlb/500/det.png"),
    MLBTeam(id: "MIN", name: "Twins", logoURL: "https://a.espncdn.com/i/teamlogos/mlb/500/min.png"),
    MLBTeam(id: "CWS", name: "White Sox", logoURL: "https://a.espncdn.com/i/teamlogos/mlb/500/chw.png"),
    MLBTeam(id: "KC", name: "Royals", logoURL: "https://a.espncdn.com/i/teamlogos/mlb/500/kc.png"),
    MLBTeam(id: "ARI", name: "Diamondbacks", logoURL: "https://a.espncdn.com/i/teamlogos/mlb/500/ari.png"),
    MLBTeam(id: "SD", name: "Padres", logoURL: "https://a.espncdn.com/i/teamlogos/mlb/500/sd.png"),
    MLBTeam(id: "COL", name: "Rockies", logoURL: "https://a.espncdn.com/i/teamlogos/mlb/500/col.png"),
    MLBTeam(id: "FLA", name: "Marlins", logoURL: "https://a.espncdn.com/i/teamlogos/mlb/500/mia.png"),
    MLBTeam(id: "PIT", name: "Pirates", logoURL: "https://a.espncdn.com/i/teamlogos/mlb/500/pit.png"),
    MLBTeam(id : "CIN", name: "Reds", logoURL: "https://a.espncdn.com/i/teamlogos/mlb/500/cin.png"),
    MLBTeam(id: "MIL", name: "Brewers", logoURL: "https://a.espncdn.com/i/teamlogos/mlb/500/mil.png")
]

func logoURL(for team: String) -> String? {
    allTeams.first(where: { team.localizedCaseInsensitiveContains($0.name) })?.logoURL
}


