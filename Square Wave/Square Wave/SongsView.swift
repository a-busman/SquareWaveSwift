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
    @State private var sortSheetShowing = false
    @State private var animationSettings: [Track : AnimationSettings] = [:]
    
    init(title: String = "Songs", predicate: NSPredicate?) {
        self.predicate = predicate
        self.tracksRequest = FetchRequest(entity: Track.entity(), sortDescriptors: [], predicate: predicate)
        self.title = title
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
        List {
            if tracks.count > 0 {
                ForEach(tracks, id: \.id) { track in
                    Button(action: {
                        self.playbackState.currentTracklist = Array(self.tracks)
                        if let index = self.tracks.firstIndex(of: track) {
                            self.playbackState.play(index: index)
                        }
                    }) {
                        HStack
                        {
                            ListArtView(animationSettings: self.getSettings(for: track))
                                .frame(width: 34.0, height: 34.0)
                            VStack(alignment: .leading) {
                                Text("\(self.tracks[self.tracks.firstIndex(of: track) ?? 0].name ?? "")")
                                Text("\(self.tracks[self.tracks.firstIndex(of: track) ?? 0].game?.name ?? "")")
                                    .font(.subheadline)
                                    .foregroundColor(Color(.secondaryLabel))
                            }
                        }
                    }
                }
            } else {
                Text("Add games to your Library")
            }
            
        }.navigationBarTitle(Text(self.title), displayMode: .inline)
            .padding(EdgeInsets(top: 0.0, leading: 0.0, bottom: 75.0, trailing: 0.0))
            .navigationBarItems(trailing: Button(action: {
                self.sortSheetShowing = true
            }) {
                Text("Sort")
            }
        ).actionSheet(isPresented: self.$sortSheetShowing) {
        ActionSheet(title: Text("Sort by..."), buttons: [
            .default(Text("Game")) {
                
            },
            .cancel()
        ])
        }.onAppear(perform: {
            self.updateSettings()
            })
    }
}

struct SongsView_Previews: PreviewProvider {
    static let playbackState = PlaybackState()
    static var previews: some View {
        SongsView(predicate: nil)
    }
}
