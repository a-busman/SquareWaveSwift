//
//  PlaybackState.swift
//  Square Wave
//
//  Created by Alex Busman on 2/15/20.
//  Copyright © 2020 Alex Busman. All rights reserved.
//

import Foundation

class PlaybackState: ObservableObject {
    @Published var isNowPlaying = false {
        didSet {
            if self.isNowPlaying {
                self.playTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                    self.elapsedTime = Int(AudioEngine.sharedInstance()?.getElapsedTime() ?? 0)
                    if AudioEngine.sharedInstance()?.getTrackEnded() ?? false && !self.loopTrack {
                        self.playTimer?.invalidate()
                        self.nextTrack()
                    }
                }
            } else {
                self.playTimer?.invalidate()
            }
        }
    }

    @Published var nowPlayingTrack:  Track?
    @Published var currentTracklist: [Track] = []
    @Published var trackNum          = 0
    @Published var elapsedTime       = 0
    @Published var loopTrack         = false {
        didSet {
            self.setFade()
        }
    }
    
    var playTimer: Timer?
    
    func setFade() {
        if self.loopTrack {
            AudioEngine.sharedInstance()?.resetFadeTime()
        } else {
            AudioEngine.sharedInstance()?.fadeOutCurrentTrack()
        }
    }
    
    func play() {
        DispatchQueue.global().async {
            AudioEngine.sharedInstance()?.play()
            self.setFade()
        }
        self.isNowPlaying = true
        
    }
    
    func pause() {
        DispatchQueue.global().async {
            AudioEngine.sharedInstance()?.pause()
        }
        self.isNowPlaying = false
    }
    
    func play(index: Int) {
        guard index < self.currentTracklist.count else { return }
        let track = self.currentTracklist[index]
        self.trackNum = index
        self.play(track)
    }
    
    private func play(_ track: Track) {
        self.isNowPlaying    = true
        self.nowPlayingTrack = track
        DispatchQueue.global().async {
            let path = URL(fileURLWithPath: FileEngine.getMusicDirectory()).appendingPathComponent(track.url!).path

            AudioEngine.sharedInstance()?.stop()
            AudioEngine.sharedInstance()?.setFileName(path)
            AudioEngine.sharedInstance()?.setTrack(Int32(track.trackNum))
            AudioEngine.sharedInstance()?.play()
            self.setFade()

        }
    }
    
    func stop() {
        self.isNowPlaying = false
        AudioEngine.sharedInstance()?.stop()
    }
    
    func nextTrack() {
        guard (self.trackNum + 1) < self.currentTracklist.count else { return }
        self.trackNum += 1
        let nextTrack = self.currentTracklist[self.trackNum]
        if self.nowPlayingTrack != nil && nextTrack.url == self.nowPlayingTrack!.url {
            DispatchQueue.global().async {
                AudioEngine.sharedInstance()?.nextTrack()
                self.setFade()
            }
            self.nowPlayingTrack = nextTrack
        } else {
            self.play(nextTrack)
        }
    }
}
