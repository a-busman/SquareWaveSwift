//
//  PlaybackState.swift
//  Square Wave
//
//  Created by Alex Busman on 2/15/20.
//  Copyright © 2020 Alex Busman. All rights reserved.
//

import Foundation
import CoreData
import UIKit
import MediaPlayer

class PlaybackState: ObservableObject {
    @Published var isNowPlaying = false {
        didSet {
            if self.isNowPlaying {
                self.playTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                    self.elapsedTime = Int(AudioEngine.sharedInstance()?.getElapsedTime() ?? 0)
                    self.updateNowPlayingElapsed()
                    if AudioEngine.sharedInstance()?.getTrackEnded() ?? false && !self.loopTrack {
                        self.playTimer?.invalidate()
                        if self.trackNum + 1 < self.currentTracklist.count {
                            self.nextTrack()
                        } else {
                            self.stop()
                        }
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
    
    var nowPlayingInfo = [String : Any]()
    
    init() {
        UIApplication.shared.beginReceivingRemoteControlEvents()
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.togglePlayPauseCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            if self.isNowPlaying {
                self.pause()
            } else {
                self.play()
            }
            return .success
        }
        
        commandCenter.pauseCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            self.pause()
            return .success
        }
        
        commandCenter.playCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            self.play()
            return .success
        }
        
        commandCenter.nextTrackCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            self.nextTrack()
            return .success
        }
        
        commandCenter.previousTrackCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            self.prevTrack()
            return .success
        }
/*
        commandCenter.changeShuffleModeCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            let shuffleStatus = event as! MPChangeShuffleModeCommandEvent
            
            if shuffleStatus.shuffleType == .off {
                self.shuffle = false
                let _currentSongIndex = self.indicies[self.currentSongIndex]
                self.currentSongIndex = _currentSongIndex
                self.indicies = Array(stride(from: 0, to: self.currentPlaylist?.songs?.count ?? 0, by: 1))
            } else {
                self.shuffle = true
                let _currentSongIndex = self.currentSongIndex
                self.indicies.remove(at: _currentSongIndex)
                self.currentSongIndex = 0
                self.indicies = [_currentSongIndex] + self.indicies.shuffled()
            }
            UserDefaults.standard.set(self.shuffle, forKey: "shuffle")
            self.nowPlayingViewController?.shuffle(enabled: self.shuffle)

            return .success
        }
        
        commandCenter.changeRepeatModeCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            let repeatStatus = event as! MPChangeRepeatModeCommandEvent
            
            if repeatStatus.repeatType == .all {
                self.repeats = true
                self.repeat1 = false
            } else if repeatStatus.repeatType == .one {
                self.repeats = true
                self.repeat1 = true
            } else {
                self.repeats = false
                self.repeat1 = false
            }
            UserDefaults.standard.set(self.repeats, forKey: "repeats")
            UserDefaults.standard.set(self.repeat1, forKey: "repeat1")
            self.nowPlayingViewController?.repeat(enabled: self.repeats, one: self.repeat1)
            return .success
        }
 */
    }
    
    func setFade() {
        if self.loopTrack {
            AudioEngine.sharedInstance()?.resetFadeTime()
        } else {
            AudioEngine.sharedInstance()?.fadeOutCurrentTrack()
        }
    }
    
    func updateNowPlayingInfoCenter() {
        self.nowPlayingInfo[MPMediaItemPropertyTitle] = self.nowPlayingTrack?.name ?? ""
        self.nowPlayingInfo[MPMediaItemPropertyArtist] = self.nowPlayingTrack?.game?.name ?? ""
        
        let image = ListArtView.getImage(for: self.nowPlayingTrack?.system?.name ?? "")
        let mediaArtwork = MPMediaItemArtwork(boundsSize: CGSize(width: 768, height: 768), requestHandler: { (size) -> UIImage in
            if let scaledImage = image?.image(with: size) {
                return scaledImage
            } else {
                return image!
            }
        })
        self.nowPlayingInfo[MPMediaItemPropertyArtwork] = mediaArtwork
        self.nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = (self.nowPlayingTrack?.length ?? 0) / 1000
        self.updateNowPlayingElapsed()
    }
    
    func updateNowPlayingElapsed() {
        self.nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = self.elapsedTime / 1000
        MPNowPlayingInfoCenter.default().nowPlayingInfo = self.nowPlayingInfo
    }
    
    func play() {
        guard self.currentTracklist.count > 0 else {
            self.populateTrackList()
            self.play(index: 0)
            return
        }
        DispatchQueue.global().async {
            AudioEngine.sharedInstance()?.play()
            self.setFade()
        }
        self.isNowPlaying = true
        self.nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 1.0
        self.updateNowPlayingInfoCenter()
        
    }
    
    func populateTrackList() {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let context  = delegate.persistentContainer.viewContext
        let request = NSFetchRequest<Track>(entityName: "Track")
        request.returnsObjectsAsFaults = false
        do {
            let results = try context.fetch(request)
            self.currentTracklist = results
        } catch {
            NSLog("Could not get tracks: \(error.localizedDescription)")
        }
        
    }
    
    func pause() {
        DispatchQueue.global().async {
            AudioEngine.sharedInstance()?.pause()
        }
        self.isNowPlaying = false
        self.nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 0.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = self.nowPlayingInfo
    }
    
    func play(index: Int) {
        guard index < self.currentTracklist.count else { return }
        let track = self.currentTracklist[index]
        self.trackNum = index
        self.play(track)
    }
    
    private func play(_ track: Track) {
        DispatchQueue.global().async {
            let path = URL(fileURLWithPath: FileEngine.getMusicDirectory()).appendingPathComponent(track.url!).path

            AudioEngine.sharedInstance()?.stop()
            AudioEngine.sharedInstance()?.setFileName(path)
            AudioEngine.sharedInstance()?.setTrack(Int32(track.trackNum))
            AudioEngine.sharedInstance()?.play()
            self.setFade()

        }
        self.nowPlayingTrack = track
        self.nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 1.0
        self.updateNowPlayingInfoCenter()
        self.isNowPlaying = true
    }
    
    func stop() {
        self.isNowPlaying = false
        AudioEngine.sharedInstance()?.stop()
        self.nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 0.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = self.nowPlayingInfo
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
            self.updateNowPlayingInfoCenter()
            self.isNowPlaying = true
        } else {
            self.play(nextTrack)
        }
    }
    
    func prevTrack() {
        guard ((self.trackNum - 1) >= 0 && self.elapsedTime < 3000) else {
            self.stop()
            self.play()
            return
        }
        self.trackNum -= 1
        let prevTrack = self.currentTracklist[self.trackNum]
        if self.nowPlayingTrack != nil && prevTrack.url == self.nowPlayingTrack!.url {
            DispatchQueue.global().async {
                AudioEngine.sharedInstance()?.prevTrack()
                self.setFade()
            }
            self.nowPlayingTrack = prevTrack
        } else {
            self.play(prevTrack)
        }
    }
}

extension UIImage {
    func image(with size:CGSize) -> UIImage?
    {
        var scaledImageRect = CGRect.zero;
        let originalSize = self.size
        let aspectWidth:CGFloat = size.width / originalSize.width;
        let aspectHeight:CGFloat = size.height / originalSize.height;
        let aspectRatio:CGFloat = max(aspectWidth, aspectHeight);
        
        scaledImageRect.size.width = originalSize.width * aspectRatio;
        scaledImageRect.size.height = originalSize.height * aspectRatio;
        scaledImageRect.origin.x = (size.width - scaledImageRect.size.width) / 2.0;
        scaledImageRect.origin.y = (size.height - scaledImageRect.size.height) / 2.0;
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0);
        
        self.draw(in: scaledImageRect);
        
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        return scaledImage;
    }
}
