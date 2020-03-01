//
//  NowPlayingMiniView.swift
//  Square Wave
//
//  Created by Alex Busman on 2/14/20.
//  Copyright © 2020 Alex Busman. All rights reserved.
//

import SwiftUI
import Combine

class NowPlayingMiniViewDelegate: ObservableObject {
    var willChange = PassthroughSubject<NowPlayingMiniViewDelegate, Never>()
    var didChange  = PassthroughSubject<NowPlayingMiniViewDelegate, Never>()
    
    var didTap: Bool = false {
        willSet {
            willChange.send(self)
        }
        
        didSet {
            didChange.send(self)
        }
    }
}

struct NowPlayingMiniView: View {
    @State var playButtonImage = "play.fill"
    @EnvironmentObject var playbackState: PlaybackState
    
    @ObservedObject var delegate: NowPlayingMiniViewDelegate
    
    var swipe: some Gesture {
        DragGesture()
            .onChanged({ value in
                if value.predictedEndLocation.y < -20.0 {
                    self.delegate.didTap = true
                }
            })
    }

    var body: some View {
        VStack {
            HStack {
                Image(uiImage: ListArtView.getImage(for: self.playbackState.nowPlayingTrack?.system?.name ?? "") ?? UIImage(named: "placeholder-art")!)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 50.0)
                    .cornerRadius(6.0)
                    .overlay(RoundedRectangle(cornerRadius: 6.0).stroke(Color(.systemGray4), lineWidth: 0.5))
                    .shadow(radius: 5.0)
                    .padding()
                VStack(alignment: .leading) {
                    Text(self.playbackState.nowPlayingTrack?.name ?? "Not Playing")
                        .foregroundColor(Color(.label))
                        .lineLimit(1)
                    if (self.playbackState.nowPlayingTrack?.game?.name?.count ?? 0) > 0 {
                        Text(self.playbackState.nowPlayingTrack?.game?.name ?? "")
                            .foregroundColor(Color(.secondaryLabel))
                        .lineLimit(1)
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
                    Image(systemName: self.playbackState.isNowPlaying ? "pause.fill" : "play.fill")
                    .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 25.0)
                }.foregroundColor(Color(.label))
                Button(action: {
                    self.playbackState.nextTrack()
                }) {
                    Image(systemName: "forward.end.fill")
                    .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 20.0)
                    .padding()
                }.foregroundColor(Color(.label))
            }
            Spacer()
            }.contentShape(Rectangle())
        .onTapGesture {
            self.delegate.didTap = true
        }.gesture(self.swipe)
    }
}

struct NowPlayingMiniView_Previews: PreviewProvider {
    static var previews: some View {
        NowPlayingMiniView(delegate: NowPlayingMiniViewDelegate())
            .frame(width: UIScreen.main.bounds.width, height: 75.0)
    }
}
