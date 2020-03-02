//
//  PlaylistView.swift
//  Square Wave
//
//  Created by Alex Busman on 2/21/20.
//  Copyright © 2020 Alex Busman. All rights reserved.
//

import SwiftUI

struct PlaylistView: View {
    @State private var titleText = ""
    @State var isEditMode: EditMode = .inactive
    @State private var isShowingAddModal = false
    var isNewPlaylist = false
    var playlist: Playlist?
    @State var tracks: [Track] = []
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top) {
                Image("placeholder-art")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 128)
                    .cornerRadius(5.0)
                    .padding()
                TextView(title:"Playlist Title", text: self.$titleText).padding(.vertical, 5.0)
                    .frame(height: 128)
            }
            Divider().padding(.leading)
            Button(action: {
                self.isShowingAddModal.toggle()
            }) {
                ZStack(alignment: .leading) {
                    Rectangle().foregroundColor(.clear)
                        .frame(height: 30.0)
                    HStack {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10).frame(width: 20.0, height: 20.0)
                                .foregroundColor(.white)
                            Image(systemName: "plus.circle.fill")
                                .resizable()
                                .frame(width: 24.0, height: 24.0)
                                .foregroundColor(Color(.systemGreen))
                        }
                        Text("Add Songs")
                    }
                }
            }.padding(.horizontal)
            Divider().padding(.leading)
            List {
                ForEach(self.tracks, id: \.self) { (track: Track) in
                    HStack {
                        Image(uiImage: ListArtView.getImage(for: track.system?.name ?? "") ?? UIImage())
                            .resizable()
                            .frame(width: 32.0, height: 32.0)
                            .cornerRadius(3.0)
                        VStack(alignment: .leading) {
                            Text("\(track.name ?? "")")
                            Text("\(track.game?.name ?? "")").font(.subheadline).foregroundColor(Color(.secondaryLabel))
                        }.padding(.leading)
                    }
                }
            }.environment(\.editMode, self.$isEditMode)
                .offset(y: -8.0)
                .edgesIgnoringSafeArea(.bottom)
                .sheet(isPresented: self.$isShowingAddModal) {
                    AddToPlaylistView(selectedTracks: self.$tracks).environment(\.managedObjectContext, (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext)
            }
        }
    }
}

struct PlaylistView_Previews: PreviewProvider {
    static var previews: some View {
        PlaylistView()
    }
}
