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
    @State var hasTracks: Bool = false
    static var miniViewPosition: CGFloat = 75.0

    var body: some View {
        Group {
            if self.hasTracks {
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
            } else {
                VStack {
                    Image(systemName: "plus")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(Edge.Set(arrayLiteral: [.horizontal, .top]), 100)
                    Text("Add files by pressing the \"+\" button in the top right, or by adding them to the\nSquare Wave folder on your iCloud Drive").multilineTextAlignment(.center)
                    .lineLimit(4)
                    .padding()
                    Spacer()
                }
                .foregroundColor(Color(.tertiaryLabel))
                .navigationBarTitle(Text("Library"))
            }
        }.onAppear {
            self.hasTracks = self.playbackState.hasTracks
        }
        .onReceive(self.playbackState.$hasTracks) { value in
            self.hasTracks = value
        }
    }
}

struct LibraryView_Previews: PreviewProvider {
    static let playbackState = PlaybackState()
    static var previews: some View {
        LibraryView().environmentObject(playbackState)
    }
}
