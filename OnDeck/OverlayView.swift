//
//  OverlayView.swift
//  OnDeck
//
//  Created by Danny Eskandar on 2025-10-12.
//

import SwiftUI

struct OverlayView: View {
    var game: GameState
    var closeAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(game.away).bold()
                Spacer()
                Text("\(game.awayScore)")
            }
            HStack {
                Text(game.home).bold()
                Spacer()
                Text("\(game.homeScore)")
            }
            Divider()
            Text("Inning \(game.inning)")
                .font(.footnote)
                .foregroundColor(.secondary)
            
            HStack {
                Spacer()
                Button("X") {
                    closeAction()
                }
                .buttonStyle(.plain)
                .foregroundColor(.red)
            }
        }
        .padding(10)
        .frame(width: 240)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .shadow(radius: 6)
    }
}

