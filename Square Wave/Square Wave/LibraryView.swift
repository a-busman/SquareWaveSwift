//
//  LibraryView.swift
//  Square Wave
//
//  Created by Alex Busman on 2/13/20.
//  Copyright © 2020 Alex Busman. All rights reserved.
//

import SwiftUI

struct LibraryView: View {
    @State private var showingDocumentPicker = false
    @State private var showingSheet = false
    @State private var showingSettings = false
    @State private var inputFiles: [URL]? 
    @State private var fromFolder = false
    @EnvironmentObject var playbackState: PlaybackState
    private let position: CGFloat = 75.0
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                NavigationView {
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
                        NavigationLink(destination: SongsView()) {
                            Text("Songs")
                        }
                        
                    }
                        .navigationBarTitle(Text("Library"))
                        .actionSheet(isPresented: self.$showingSheet) {
                            ActionSheet(title: Text("Add Music"), buttons: [
                                .default(Text("From Folder...")) {
                                    self.fromFolder = true
                                    self.showingDocumentPicker = true
                                },
                                .default(Text("From Files...")) {
                                    self.fromFolder = false
                                    self.showingDocumentPicker = true
                                },
                                .cancel()])
                    }
                        .sheet(isPresented: self.$showingDocumentPicker) {
                            FilePicker(files: self.$inputFiles, folderType: self.fromFolder)
                    }
                    

                        .navigationBarItems(leading:
                            Button(action: {
                                self.showingSettings = true
                            }) {
                                Text("Settings")
                            }.sheet(isPresented: self.$showingSettings) {
                                SettingsView()
                            },
                            trailing:
                                Button(action: {
                                    self.showingSheet = true
                                }) {
                                    Text("Add")
                                }
                        )
                }

                NowPlayingMiniView()
                    .frame(width: geometry.size.width, height: self.position + (UIScreen.main.bounds.height - geometry.size.height))
                    .offset(y:geometry.size.height - self.position)
            }
        }
    }
}

struct LibraryView_Previews: PreviewProvider {
    static let playbackState = PlaybackState()
    static var previews: some View {
        LibraryView().environmentObject(playbackState)
    }
}
