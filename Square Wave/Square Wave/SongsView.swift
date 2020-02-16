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
    @FetchRequest(entity: Track.entity(), sortDescriptors: []) var tracks: FetchedResults<Track>
    @State private var sortSheetShowing = false
    @State private var animationSettings = AnimationSettings(tracks: [])
    
    private func shouldDisplayAnimation(_ track: Track) -> Bool {
        let shouldAnimate = (track == self.playbackState.nowPlayingTrack)
        return shouldAnimate
    }
    private func shouldAnimate(_ track: Track) -> Bool {
        let shouldAnimate = (track == self.playbackState.nowPlayingTrack) && self.playbackState.isNowPlaying
        return shouldAnimate
    }
    
    private func getSettings(for track: Track) -> AnimationSettings {
        if shouldDisplayAnimation(track) {
            if shouldAnimate(track) {
                animationSettings.startAnimating(track)
            } else {
                animationSettings.pauseAnimating(track)
            }
        } else {
            animationSettings.hideAnimation(track)
        }
        return self.animationSettings
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
                            ListArtView(track: track)
                                .frame(width: 30.0, height: 30.0).environmentObject(self.getSettings(for: track))
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
            
        }.navigationBarTitle(Text("Songs"), displayMode: .inline)
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
            self.animationSettings.updateTracks(Array(self.tracks))
            })
    }
}

struct SongsView_Previews: PreviewProvider {
    static let playbackState = PlaybackState()
    static var previews: some View {
        SongsView()
    }
}
