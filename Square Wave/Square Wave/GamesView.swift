//
//  GamesView.swift
//  Square Wave
//
//  Created by Alex Busman on 2/13/20.
//  Copyright © 2020 Alex Busman. All rights reserved.
//

import SwiftUI
import CoreData

struct GamesView: View {
    @FetchRequest(entity: Game.entity(), sortDescriptors: []) var games: FetchedResults<Game>

    var body: some View {
        UIListView(rows: Binding(get: {
            Array(self.games)
        }, set: { _ in
            
        }),
        sortType: Binding(get: {
            SortType.title.rawValue
        }, set: { _ in
            
        }), isEditing: .constant(false), rowType: Game.self, keypaths: UIListViewCellKeypaths(art: \Game.system?.name, title: \Game.name, desc: \Game.system?.name))
            .navigationBarTitle(Text("Games"), displayMode: .inline)
        .edgesIgnoringSafeArea(.vertical)
    }
}

struct GamesView_Previews: PreviewProvider {
    static var previews: some View {
        GamesView()
    }
}
