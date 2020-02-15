//
//  NowPlayingMiniView.swift
//  Square Wave
//
//  Created by Alex Busman on 2/14/20.
//  Copyright © 2020 Alex Busman. All rights reserved.
//

import SwiftUI

struct NowPlayingMiniView: View {
    @State var playButtonImage = "play.fill"
    @EnvironmentObject var playbackState: PlaybackState

    var body: some View {
        ZStack(alignment: .top) {
            Rectangle()
                .background(BlurView())
                .foregroundColor(.clear)
            HStack {
                Image(systemName: "a.square.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 50.0)
                    .padding()
                VStack(alignment: .leading) {
                    Text(self.playbackState.currentTitle)
                        .foregroundColor(Color(.label))
                    if self.playbackState.currentGame.count > 0 {
                        Text(self.playbackState.currentGame)
                            .foregroundColor(Color(.secondaryLabel))
                    }
                }
                Spacer()
                Button(action: {
                    if !self.playbackState.isNowPlaying {
                        AudioEngine.sharedInstance()?.play()
                        self.playbackState.isNowPlaying = true
                        self.playbackState.updateNowPlaying()
                    } else {
                        AudioEngine.sharedInstance()?.pause()
                        self.playbackState.isNowPlaying = false
                    }
                }) {
                    Image(systemName: playbackState.isNowPlaying ? "pause.fill" : "play.fill")
                    .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 25.0)
                }.foregroundColor(Color(.label))
                Button(action: {
                    AudioEngine.sharedInstance()?.nextTrack()
                    self.playbackState.updateNowPlaying()
                }) {
                    Image(systemName: "forward.fill")
                    .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 20.0)
                    .padding()
                }.foregroundColor(Color(.label))
            }
        }
    }
}

struct NowPlayingMiniView_Previews: PreviewProvider {
    static var previews: some View {
        NowPlayingMiniView()
            .frame(width: UIScreen.main.bounds.width, height: 75.0)
    }
}
