//
//  NowPlayingMiniView.swift
//  Square Wave
//
//  Created by Alex Busman on 2/14/20.
//  Copyright © 2020 Alex Busman. All rights reserved.
//

import SwiftUI

struct NowPlayingMiniView: View {
    @Binding var nowPlayingTapped: Bool
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
                    Text(self.playbackState.nowPlayingTrack?.name ?? "Not Playing")
                        .foregroundColor(Color(.label))
                    if (self.playbackState.nowPlayingTrack?.game?.name?.count ?? 0) > 0 {
                        Text(self.playbackState.nowPlayingTrack?.game?.name ?? "")
                            .foregroundColor(Color(.secondaryLabel))
                    }
                }
                Spacer()
                Button(action: {
                    if !self.playbackState.isNowPlaying {
                        self.playbackState.play()
                    } else {
                        self.playbackState.pause()
                    }
                }) {
                    Image(systemName: playbackState.isNowPlaying ? "pause.fill" : "play.fill")
                    .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 25.0)
                }.foregroundColor(Color(.label))
                Button(action: {
                    self.playbackState.nextTrack()
                }) {
                    Image(systemName: "forward.fill")
                    .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 20.0)
                    .padding()
                }.foregroundColor(Color(.label))
            }
        }.onTapGesture {
            self.nowPlayingTapped = true
        }
    }
}

struct NowPlayingMiniView_Previews: PreviewProvider {
    static var previews: some View {
        NowPlayingMiniView(nowPlayingTapped: .constant(false))
            .frame(width: UIScreen.main.bounds.width, height: 75.0)
    }
}
