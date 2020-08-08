//
//  ArtistsView.swift
//  Square Waves
//
//  Created by Alex Busman on 8/8/20.
//  Copyright © 2020 Alex Busman. All rights reserved.
//

import SwiftUI

struct ArtistsView: View {
    @FetchRequest(entity: Artist.entity(), sortDescriptors: []) var artists: FetchedResults<Artist>

    var body: some View {
        UIListView(rows: Binding(get: {
            Array(self.artists)
        }, set: { _ in
            
        }),
        sortType: Binding(get: {
            SortType.title.rawValue
        }, set: { _ in
            
        }), isEditing: .constant(false), rowType: Artist.self, keypaths: UIListViewCellKeypaths(title: \Artist.name), showSearch: false, showsHeader: false)
            .navigationBarTitle(Text(NSLocalizedString("Artists", comment: "Artists")), displayMode: .inline)
        .edgesIgnoringSafeArea(.vertical)
    }
}

struct ArtistsView_Previews: PreviewProvider {
    static var previews: some View {
        ArtistsView()
    }
}

