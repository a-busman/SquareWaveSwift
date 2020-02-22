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
    @State private var nowPlayingShowing = false
    @EnvironmentObject var playbackState: PlaybackState
    static let miniViewPosition: CGFloat = 75.0
    static var miniViewHeight: CGFloat = 0.0
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
                        NavigationLink(destination: SongsView(predicate: nil)) {
                            Text("Songs")
                        }
                        
                    }
                        .navigationBarTitle(Text("Library"))
                        .navigationBarItems(leading:
                            Button(action: {
                                self.showingSettings = true
                            }) {
                                Text("Settings")
                            }.sheet(isPresented: self.$showingSettings, onDismiss: {self.showingSettings = false}) {
                                SettingsView(isDisplayed: self.$showingSettings)
                            },
                            trailing:
                                Button(action: {
                                    self.showingSheet = true
                                }) {
                                    Text("Add")
                                }.actionSheet(isPresented: self.$showingSheet) {
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
                                .sheet(isPresented: self.$showingDocumentPicker, onDismiss: {self.showingDocumentPicker = false}) {
                                    FilePicker(files: self.$inputFiles, folderType: self.fromFolder)
                            }
                        )
                }
                NowPlayingMiniView(nowPlayingTapped: self.$nowPlayingShowing)
                    .frame(width: geometry.size.width, height: LibraryView.getHeight(geometry.size.height))
                    .offset(y:geometry.size.height - LibraryView.miniViewPosition)
            }.sheet(isPresented: self.$nowPlayingShowing, onDismiss: {self.nowPlayingShowing = false}) {
                NowPlayingView().environmentObject(self.playbackState)
            }
        }
    }
    
    static func getHeight(_ geometryHeight: CGFloat) -> CGFloat {
        LibraryView.miniViewHeight = LibraryView.miniViewPosition + (UIScreen.main.bounds.height - geometryHeight)
        return LibraryView.miniViewHeight
    }
}

struct LibraryView_Previews: PreviewProvider {
    static let playbackState = PlaybackState()
    static var previews: some View {
        LibraryView().environmentObject(playbackState)
    }
}
