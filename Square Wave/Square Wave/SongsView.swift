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
    @State var selections = Set<Track>()
    init() {
        UITableViewCell.appearance().selectionStyle = .gray
    }
    var body: some View {
        List {
            if tracks.count > 0 {
                ForEach(tracks, id: \.id) { track in
                    Button(action: {
                        let path = URL(fileURLWithPath: FileEngine.getMusicDirectory()).appendingPathComponent(track.url!).path
                        AudioEngine.sharedInstance()?.stop()
                        AudioEngine.sharedInstance()?.setFileName(path)
                        AudioEngine.sharedInstance()?.setTrack(Int32(track.trackNum))
                        AudioEngine.sharedInstance()?.play()
                        self.playbackState.isNowPlaying = true
                        self.playbackState.updateNowPlaying()
                    }) {
                        VStack(alignment: .leading) {
                            Text("\(track.name ?? "")")
                            Text("\(track.game?.name ?? "")")
                                .font(.subheadline)
                                .foregroundColor(Color(.secondaryLabel))
                        }
                    }
                }
            } else {
                Text("Add games to your Library")
            }
            
        }.navigationBarTitle(Text("Songs"), displayMode: .inline)
            .padding(EdgeInsets(top: 0.0, leading: 0.0, bottom: 75.0, trailing: 0.0))
        
    }
}

struct SongsView_Previews: PreviewProvider {
    static let playbackState = PlaybackState()
    static var previews: some View {
        SongsView().environmentObject(playbackState)
    }
}
