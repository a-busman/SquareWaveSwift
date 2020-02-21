//
//  GamesView.swift
//  Square Wave
//
//  Created by Alex Busman on 2/13/20.
//  Copyright © 2020 Alex Busman. All rights reserved.
//

import SwiftUI

struct GamesView: View {
    @FetchRequest(entity: Game.entity(), sortDescriptors: []) var games: FetchedResults<Game>

    var body: some View {
        List {
            Section(footer: Text("Total Games: \(games.count)")
                .foregroundColor(Color(.tertiaryLabel))) {
                if games.count > 0 {
                    ForEach(games, id: \.self) { (game: Game) in
                        NavigationLink(destination: SongsView(title: game.name ?? "Songs", predicate: NSPredicate(format: "game.id == %@", game.id! as CVarArg))) {
                            HStack {
                                ListArtView(animationSettings: AnimationSettings(), albumArt: game.system?.name ?? "")
                                .frame(width: 34.0, height: 34.0)
                                VStack(alignment: .leading) {
                                    Text("\(game.name ?? "")")
                                    if game.system != nil {
                                        Text("\(game.system?.name ?? "")")
                                            .foregroundColor(Color(.secondaryLabel))
                                            .font(.subheadline)
                                    }
                                }
                            }
                            
                        }
                    }
                } else {
                    Text("Add games to your Library")
                }
            }
            Section(footer: Rectangle().foregroundColor(.clear)
                .background(Color(.systemBackground))) {
                    EmptyView()
            }.padding(.horizontal, -15)
        }.navigationBarTitle(Text("Games"))
    }
}

struct GamesView_Previews: PreviewProvider {
    static var previews: some View {
        GamesView()
    }
}
