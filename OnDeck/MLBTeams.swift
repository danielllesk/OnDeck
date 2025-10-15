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
    let teamLower = team.lowercased()
    
    let teamMap: [String: String] = [
        "yankees": "147",
        "new york yankees": "147",
        "blue jays": "141",
        "toronto blue jays": "141",
        "red sox": "111",
        "boston red sox": "111",
        "orioles": "110",
        "baltimore orioles": "110",
        "rays": "139",
        "tampa bay rays": "139",
        "astros": "117",
        "houston astros": "117",
        "rangers": "140",
        "texas rangers": "140",
        "mariners": "136",
        "seattle mariners": "136",
        "angels": "108",
        "los angeles angels": "108",
        "athletics": "133",
        "oakland athletics": "133",
        "dodgers": "119",
        "los angeles dodgers": "119",
        "giants": "137",
        "san francisco giants": "137",
        "cubs": "112",
        "chicago cubs": "112",
        "cardinals": "138",
        "st. louis cardinals": "138",
        "braves": "144",
        "atlanta braves": "144",
        "mets": "121",
        "new york mets": "121",
        "phillies": "143",
        "philadelphia phillies": "143",
        "nationals": "120",
        "washington nationals": "120",
        "guardians": "114",
        "cleveland guardians": "114",
        "tigers": "116",
        "detroit tigers": "116",
        "twins": "142",
        "minnesota twins": "142",
        "white sox": "145",
        "chicago white sox": "145",
        "royals": "118",
        "kansas city royals": "118",
        "diamondbacks": "109",
        "arizona diamondbacks": "109",
        "padres": "135",
        "san diego padres": "135",
        "rockies": "115",
        "colorado rockies": "115",
        "marlins": "146",
        "miami marlins": "146",
        "pirates": "134",
        "pittsburgh pirates": "134",
        "reds": "113",
        "cincinnati reds": "113",
        "brewers": "158",
        "milwaukee brewers": "158"
    ]
    
    if let teamID = teamMap[teamLower] {
        return "https://www.mlbstatic.com/team-logos/\(teamID).svg"
    }
    
    for (key, value) in teamMap {
        if teamLower.contains(key) || key.contains(teamLower) {
            return "https://www.mlbstatic.com/team-logos/\(value).svg"
        }
    }
    
    return "https://www.mlbstatic.com/team-logos/1.svg"
}
