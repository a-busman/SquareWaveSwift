//
//  LibraryView.swift
//  Square Wave
//
//  Created by Alex Busman on 2/13/20.
//  Copyright © 2020 Alex Busman. All rights reserved.
//

import SwiftUI

struct LibraryView: View {
    @EnvironmentObject var playbackState: PlaybackState
    
    static var miniViewPosition: CGFloat = 75.0
    var body: some View {
        ZStack(alignment: .topLeading) {
            List {
                NavigationLink(destination: PlaylistsView()) {
                    Text("Playlists")
                }
                NavigationLink(destination: PlatformsView()) {
                    Text("Platforms")
                }
                NavigationLink(destination: GamesView()) {
                    Text("Games")
                }
                NavigationLink(destination: SongsView(predicate: nil)) {
                    Text("Songs")
                }
            }
                .navigationBarTitle(Text("Library"))
        }
    }
}

struct LibraryView_Previews: PreviewProvider {
    static let playbackState = PlaybackState()
    static var previews: some View {
        LibraryView().environmentObject(playbackState)
    }
}
