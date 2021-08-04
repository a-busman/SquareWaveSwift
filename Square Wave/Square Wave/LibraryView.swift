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
    @State var isShowingPicker: Bool = false
    static var miniViewPosition: CGFloat = 75.0

    var body: some View {
        Group {
            if self.hasTracks {
                List {
                    NavigationLink(destination: PlaylistsView()) {
                        Text(NSLocalizedString("Playlists", comment: "Playlists"))
                    }
                    NavigationLink(destination: PlatformsView()) {
                        Text(NSLocalizedString("Platforms", comment: "Platforms"))
                    }
                    NavigationLink(destination: ArtistsView()) {
                        Text(NSLocalizedString("Artists", comment: "Artists"))
                    }
                    NavigationLink(destination: GamesView()) {
                        Text(NSLocalizedString("Games", comment: "Games"))
                    }
                    NavigationLink(destination: SongsView(predicate: nil).environmentObject(playbackState)) {
                        Text(NSLocalizedString("Songs", comment: "Songs"))
                    }
                }
                .navigationBarTitle(Text(NSLocalizedString("Library", comment: "Library")))
            } else {
                VStack {
                    Spacer()
                    Button(action: {
                        self.isShowingPicker.toggle()
                    }) {
                    Image(systemName: "plus")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(Edge.Set(arrayLiteral: [.horizontal, .top]), 100)
                    }
                    Text(NSLocalizedString("Add Files", comment: "Add Files")).multilineTextAlignment(.center)
                    .lineLimit(6)
                    .padding()
                        .padding(.bottom, 50)
                    Spacer()
                }
                .foregroundColor(Color(.tertiaryLabel))
                .navigationBarTitle(Text(NSLocalizedString("Library", comment: "Library")))
                .sheet(isPresented: self.$isShowingPicker) {
                    FilePicker()
                }
            }
        }.onAppear {
            self.hasTracks = self.playbackState.hasTracks
        }
        .onReceive(self.playbackState.$hasTracks) { value in
            self.hasTracks = value
        }
    }
}

/*
struct LibraryView_Previews: PreviewProvider {
    static let playbackState = PlaybackState()
    static var previews: some View {
        LibraryView().environmentObject(playbackState)
    }
}
*/
