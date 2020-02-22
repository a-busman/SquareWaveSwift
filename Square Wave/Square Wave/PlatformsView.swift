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
        List {
            Section(footer: Text("Total Platforms: \(platforms.count)")
                .foregroundColor(Color(.tertiaryLabel))) {
                    if self.platforms.count > 0 {
                        ForEach(self.platforms, id: \.self) { (platform: System) in
                        NavigationLink(destination: SongsView(title: platform.name ?? "Songs", predicate: NSPredicate(format: "system.id == %@", platform.id! as CVarArg))) {
                            HStack {
                                ListArtView(animationSettings: AnimationSettings(), albumArt: platform.name ?? "")
                                .frame(width: 34.0, height: 34.0)
                                Text("\(platform.name ?? "")")
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
        }.navigationBarTitle(Text("Platforms"))
    }
}

struct PlatformsView_Previews: PreviewProvider {
    static var previews: some View {
        PlatformsView()
    }
}
