//
//  LibraryView.swift
//  Square Wave
//
//  Created by Alex Busman on 2/13/20.
//  Copyright © 2020 Alex Busman. All rights reserved.
//

import SwiftUI

struct LibraryView: View {
    enum SheetType {
        case none
        case settings
        case folder
        case file
        case nowPlaying
    }
    @State private var showingDocumentPicker = false
    @State private var showingSheet = false
    @State private var showingActionSheet = false
    @State private var showingSettings = false
    @State private var inputFiles: [URL]? 
    @State private var fromFolder = false
    @State private var nowPlayingShowing = false
    @State private var sheetSelection: SheetType = .none
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
                                self.sheetSelection = .settings
                                self.showingSheet.toggle()
                            }) {
                                Text("Settings")
                            },
                            trailing:
                                Button(action: {
                                    self.showingActionSheet.toggle()
                                }) {
                                    Text("Add").bold()
                                }
                        )

                }
                NowPlayingMiniView(nowPlayingTapped: Binding(
                    get: {
                        self.showingSheet
                }, set: { (newValue) in
                    self.sheetSelection = .nowPlaying
                    self.showingSheet.toggle()
                }
                ))
                .frame(width: geometry.size.width, height: LibraryView.miniViewPosition + (UIScreen.main.bounds.height - geometry.size.height))
                .offset(y:geometry.size.height - LibraryView.miniViewPosition)

                
            }.sheet(isPresented: self.$showingSheet) {
                if self.sheetSelection == .file {
                    FilePicker(files: self.$inputFiles, folderType: false)
                } else if self.sheetSelection == .folder {
                    FilePicker(files: self.$inputFiles, folderType: true)
                } else if self.sheetSelection == .settings {
                    SettingsView(isShowing: self.$showingSheet).environmentObject(self.playbackState)
                } else if self.sheetSelection == .nowPlaying {
                    NowPlayingView().environmentObject(self.playbackState)
                }
            }.actionSheet(isPresented: self.$showingActionSheet) {
            ActionSheet(title: Text("Add Music"), buttons: [
                .default(Text("From Folder...")) {
                    self.sheetSelection = .folder
                    self.showingSheet.toggle()
                },
                .default(Text("From Files...")) {
                    self.sheetSelection = .file
                    self.showingSheet.toggle()
                },
                .cancel()])
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
