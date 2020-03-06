//
//  SongsView.swift
//  Square Wave
//
//  Created by Alex Busman on 2/13/20.
//  Copyright © 2020 Alex Busman. All rights reserved.
//

import SwiftUI

struct SongsView: View {
    @EnvironmentObject var playbackState: PlaybackState
    var predicate: NSPredicate?
    var tracksRequest : FetchRequest<Track>
    var tracks: FetchedResults<Track>{tracksRequest.wrappedValue}
    var title: String
    var sortFromDesc: Bool
    
    @State private var sortSheetShowing = false
    @State private var animationSettings: [Track : AnimationSettings] = [:]
    @State private var selectedIndex = ""
    @State private var sortType = PlaybackStateProperty.sortType.getProperty() ?? 0
    
    init(title: String = "Songs", predicate: NSPredicate?, sortFromDesc: Bool = false) {
        self.predicate = predicate
        self.tracksRequest = FetchRequest(entity: Track.entity(), sortDescriptors: [], predicate: predicate)
        self.title = title
        self.sortFromDesc = sortFromDesc
        UITableView.appearance().insetsLayoutMarginsFromSafeArea = false
    }
    
    private func shouldDisplayAnimation(_ track: Track) -> Bool {
        let shouldAnimate = (track == self.playbackState.nowPlayingTrack)
        return shouldAnimate
    }
    private func shouldAnimate(_ track: Track) -> Bool {
        let shouldAnimate = (track == self.playbackState.nowPlayingTrack) && self.playbackState.isNowPlaying
        return shouldAnimate
    }
    
    private func getSettings(for track: Track) -> AnimationSettings {
        guard let settings = self.animationSettings[track] else { return AnimationSettings() }
        if shouldDisplayAnimation(track) {
            if shouldAnimate(track) {
                settings.startAnimating()
            } else {
                settings.pauseAnimating()
            }
        } else {
            settings.hideAnimation()
        }
        return settings
    }
    
    private func updateSettings() {
        for track in tracks {
            self.animationSettings[track] = AnimationSettings()
        }
    }
    
    var body: some View {
        ZStack(alignment: .trailing) {
            UIListView(rows: Binding(get: { self.tracks.sorted {
                if self.sortType == SortType.title.rawValue && self.predicate == nil {
                        return $0.name! < $1.name!
                    } else {
                        return $0.game!.name! < $1.game!.name!
                    }
                }
            }, set: { _ in
                
            }), sortType: self.$sortType, isEditing: .constant(false), rowType: Track.self, keypaths: UIListViewCellKeypaths(art: \Track.system?.name, title: \Track.name, desc: \Track.game?.name), sortFromDesc: self.sortFromDesc)
                .navigationBarTitle(Text(self.title), displayMode: .inline)
                .navigationBarItems(trailing: Button(action: {
                    self.sortSheetShowing = true
                }) {
                    if self.predicate == nil {
                        Text("Sort")
                    }
                }
            ).actionSheet(isPresented: self.$sortSheetShowing) {
            ActionSheet(title: Text("Sort by..."), buttons: [
                .default(Text("Title")) {
                    self.sortType = SortType.title.rawValue
                    PlaybackStateProperty.sortType.setProperty(newValue: self.sortType)
                },
                .default(Text("Game")) {
                    self.sortType = SortType.game.rawValue
                    PlaybackStateProperty.sortType.setProperty(newValue: self.sortType)
                },
                .cancel()
            ])
            }.onAppear(perform: {
                self.updateSettings()
                })
                .edgesIgnoringSafeArea(.vertical)
        }
    }
}

struct SongsView_Previews: PreviewProvider {
    static var previews: some View {
        SongsView(predicate: nil)
    }
}
