//
//  PlaylistView.swift
//  Square Wave
//
//  Created by Alex Busman on 2/21/20.
//  Copyright © 2020 Alex Busman. All rights reserved.
//

import SwiftUI

class PlaylistModel: ObservableObject {
    @Published var tracks: [Track] = [] {
        didSet {
            if let playlist = self.playlist {
                playlist.tracks = NSOrderedSet(array: self.tracks)
                NSLog("Setting playlist to have \(self.tracks.count) tracks")
                let delegate = UIApplication.shared.delegate as! AppDelegate
                
                delegate.saveContext()
            }
        }
    }
    @Published var titleText: String = "" {
        didSet {
            if let playlist = self.playlist {
                playlist.name = self.titleText
                let delegate = UIApplication.shared.delegate as! AppDelegate
                
                delegate.saveContext()
            }
        }
    }
    var playlist: Playlist?
    
    init() {
        NSLog("Empty init")
    }
    
    init(playlist: Playlist) {
        if let tracks = playlist.tracks {
            self.tracks = tracks.array as! [Track]
            NSLog("PlaylistModel with \(self.tracks.count) tracks")
        }
        self.titleText = playlist.name ?? ""
        self.playlist = playlist
    }
}

struct PlaylistView: View {
    @State var isEditMode = false
    @State private var isShowingAddModal = false
    var isNewPlaylist = false
    @ObservedObject var playlistModel: PlaylistModel = PlaylistModel()
    @EnvironmentObject var playbackState: PlaybackState
    
    init(isNewPlaylist: Bool, playlistModel: PlaylistModel) {
        self.isNewPlaylist = isNewPlaylist
        self.playlistModel = playlistModel
    }
    
    init(playlist: Playlist) {
        NSLog("Playlist with \(playlist.tracks?.count ?? 0) tracks")
        self.playlistModel = PlaylistModel(playlist: playlist)
    }

    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top) {
                Image("placeholder-art")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 128)
                    .cornerRadius(5.0)
                    .padding()
                if self.isEditMode {
                    TextView(title:"Playlist Title", text: self.$playlistModel.titleText).padding(.vertical, 5.0)
                    .frame(height: 128)
                } else {
                    Text(self.playlistModel.titleText).font(.headline).padding(.vertical, 12.5).padding(.leading, 6.0)
                }
            }
            Divider().padding(.leading)
            if self.isEditMode {
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
            }
            UIListView(rows: Binding(get: {
                NSLog("Updating List with \(self.playlistModel.tracks.count) tracks")
                return self.playlistModel.tracks
            }, set: { value in
                self.playlistModel.objectWillChange.send()
                self.playlistModel.tracks = value as! [Track]
                self.playbackState.currentTracklist = self.playlistModel.tracks
            }), sortType: .constant(SortType.none.rawValue), isEditing: self.$isEditMode, rowType: Track.self, keypaths: UIListViewCellKeypaths(art: \Track.system?.name, title: \Track.name, desc: \Track.game?.name), showSections: false, showSearch: false, showsHeader: !self.isEditMode)
                .environmentObject(AppDelegate.playbackState)
                .offset(y: -8.0)
                .edgesIgnoringSafeArea(.bottom)
                .sheet(isPresented: self.$isShowingAddModal) {
                    AddToPlaylistView(selectedTracks: self.$playlistModel.tracks).environment(\.managedObjectContext, (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext)
            }
                .if(!self.isNewPlaylist) {
                    $0.navigationBarItems(trailing: Button(action: {
                        self.isEditMode.toggle()
                    }) {
                        Text(self.isEditMode ? "Done" : "Edit")
                    })
                }
        }.onAppear {
            if self.isNewPlaylist {
                self.isEditMode = true
            }
        }.navigationBarTitle("", displayMode: .inline)
    }
}

extension View {
    func `if`<Content: View>(_ conditional: Bool, content: (Self) -> Content) -> some View {
        if conditional {
            return AnyView(content(self))
        } else {
            return AnyView(self)
        }
    }
}

/*
struct PlaylistView_Previews: PreviewProvider {
    static var previews: some View {
        PlaylistView()
    }
}
*/
