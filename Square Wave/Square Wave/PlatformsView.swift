//
//  PlatformsView.swift
//  Square Wave
//
//  Created by Alex Busman on 2/13/20.
//  Copyright © 2020 Alex Busman. All rights reserved.
//

import SwiftUI
import CoreData

struct PlatformsView: View {
    @FetchRequest(entity: System.entity(), sortDescriptors: []) var platforms: FetchedResults<System>
    var body: some View {
        UIListView(rows: Binding(get: {
            Array(self.platforms)
        }, set: { _ in
            
        }),
        sortType: Binding(get: {
            SortType.title.rawValue
        }, set: { _ in
            
        }), isEditing: .constant(false), rowType: System.self, keypaths: UIListViewCellKeypaths(art: \System.name, title: \System.name, desc: nil), showSections: false)
            .navigationBarTitle(Text(NSLocalizedString("Platforms", comment: "Platforms")))
            .edgesIgnoringSafeArea(.vertical)
    }
}

struct PlatformsView_Previews: PreviewProvider {
    static var previews: some View {
        PlatformsView()
    }
}
