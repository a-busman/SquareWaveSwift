//
//  PlaylistsView.swift
//  Square Wave
//
//  Created by Alex Busman on 2/13/20.
//  Copyright © 2020 Alex Busman. All rights reserved.
//

import SwiftUI

struct PlaylistRowView: View {
    @State var image: UIImage
    @State var text: String = ""
    @State var blurViewVisible: Bool = false
    
    var body: some View {
        HStack {
            ZStack {
                Image(uiImage: self.image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .overlay(RoundedRectangle(cornerRadius: 5.0).stroke(Color(.systemGray4)))
                    .cornerRadius(5.0)
                if self.blurViewVisible {
                    VisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
                        .cornerRadius(5.0)
                    Image("placeholder-playlist")
                            .resizable()

                    .mask(Image(systemName: "plus")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(Color(.white)))
                    .frame(width: 48.0, height: 48.0)
                    VisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialLight))

                    .mask(Image(systemName: "plus")
                    .resizable()
                    .aspectRatio(contentMode: .fit))
                                .frame(width: 48.0)
                }
            }.frame(width: 128.0, height: 128.0)

            Text(self.text)
                .foregroundColor(Color(.systemBlue))
                .padding()
            
        }
    }
}

struct PlaylistsView: View {
    @FetchRequest(entity: Playlist.entity(), sortDescriptors: [], predicate: NSPredicate(format: "isNowPlaying != true")) var playlists: FetchedResults<Playlist>
    var body: some View {
        List {
            Button(action: {
                // new playlist
            }) {
                PlaylistRowView(image: UIImage(named: "placeholder-playlist") ?? UIImage(), text: "New Playlist...", blurViewVisible: true)
            }
            ForEach(self.playlists, id: \.self) { (playlist: Playlist) in
                NavigationLink(destination: PlaylistView()) {
                    PlaylistRowView(image: self.getPlaylistImage(playlist), text: playlist.name ?? "")
                }
            }
            Spacer()
                .frame(height: LibraryView.miniViewPosition)
        }.navigationBarTitle(Text("Playlists"))
    }
    
    func getPlaylistImage(_ playlist: Playlist) -> UIImage {
        return UIImage()
    }
}

struct PlaylistsView_Previews: PreviewProvider {
    static var previews: some View {
        PlaylistsView()
    }
}
