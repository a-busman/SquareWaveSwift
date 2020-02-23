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

enum PlaybackStateProperty: String {
    case lastPlayedTrack    = "lastPlayedTrack"
    case lastPlayedTracknum = "lastPlayedTracknum"
    case loopTrack          = "loopTrack"
    case shuffleTracks      = "shuffleTracks"
    case trackLength        = "trackLength"
    case loopCount          = "loopCount"

    func getProperty<T>() -> T? {
        switch(self) {
        case .lastPlayedTrack:
            if let id = UserDefaults.standard.string(forKey: self.rawValue) {
                let delegate = UIApplication.shared.delegate as! AppDelegate
                let context = delegate.persistentContainer.viewContext
                let request = NSFetchRequest<Track>(entityName: "Track")
                request.predicate = NSPredicate(format: "id == %@", (UUID(uuidString: id) ?? UUID()) as CVarArg)
                request.returnsObjectsAsFaults = false
                do {
                    let results = try context.fetch(request)
                    return results.first as? T
                } catch {
                    NSLog("Could not get last played track: %s", error.localizedDescription)
                }
            }
            return nil
        case .lastPlayedTracknum:
            fallthrough
        case .loopCount:
            fallthrough
        case .trackLength:
            return UserDefaults.standard.integer(forKey: self.rawValue) as? T
        case .loopTrack:
            fallthrough
        case .shuffleTracks:
            return UserDefaults.standard.bool(forKey: self.rawValue) as? T
        }
    }
    
    func setProperty(newValue: Any?) {
        switch(self) {
        case .lastPlayedTrack:
            if let uuid = newValue as? UUID {
                UserDefaults.standard.set(uuid.uuidString, forKey: self.rawValue)
            } else {
                UserDefaults.standard.removeObject(forKey: self.rawValue)
            }
        case .lastPlayedTracknum:
            fallthrough
        case .loopCount:
            fallthrough
        case .trackLength:
            if let num = newValue as? Int {
                UserDefaults.standard.set(num, forKey: self.rawValue)
            }
        case .loopTrack:
            fallthrough
        case .shuffleTracks:
            if let val = newValue as? Bool {
                UserDefaults.standard.set(val, forKey: self.rawValue)
            }
        }
    }
}

// MARK: -
class PlaybackState: ObservableObject {
    @Published var isNowPlaying = false {
        didSet {
            if self.isNowPlaying {
                self.playTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                    self.elapsedTime = Int(AudioEngine.sharedInstance()?.getElapsedTime() ?? 0)
                    self.updateNowPlayingElapsed()
                    if let didEnd = AudioEngine.sharedInstance()?.getTrackEnded() {
                        if didEnd && !self.loopTrack && !self.trackEnded {
                            self.playTimer?.invalidate()
                            self.trackEnded = true
                            if self.trackNum + 1 < self.currentTracklist.count {
                                self.nextTrack()
                            } else {
                                self.stop()
                            }
                        } else if !didEnd {
                            self.trackEnded = false
                        }
                    }
                }
            } else {
                self.playTimer?.invalidate()
            }
        }
    }

    @Published var nowPlayingTrack:  Track? {
        didSet {
            PlaybackStateProperty.lastPlayedTrack.setProperty(newValue: self.nowPlayingTrack?.id)
        }
    }
    private var nowPlayingPlaylist: Playlist?
    @Published var currentTracklist: [Track] = [] {
        didSet {
            if self.currentTracklist.count == 0 {
                return
            }
            if self.nowPlayingPlaylist == nil {
                self.getNowPlayingPlaylist()
            }
            let delegate = UIApplication.shared.delegate as! AppDelegate
            self.nowPlayingPlaylist?.removeFromTracks(at: NSIndexSet(indexesIn: NSRange(location: 0, length: self.nowPlayingPlaylist?.tracks?.count ?? 1)))
            let playlistToSave = self.originalTrackList.count == 0 ? self.currentTracklist : self.originalTrackList
            self.nowPlayingPlaylist?.addToTracks(NSOrderedSet(array: playlistToSave))
            delegate.saveContext()
        }
    }
    
    private var originalTrackList: [Track] = []
    @Published var trackNum = 0 {
        didSet {
            PlaybackStateProperty.lastPlayedTracknum.setProperty(newValue: self.trackNum)
        }
    }
    @Published var elapsedTime   = 0
    @Published var loopTrack     = false
    @Published var shuffleTracks = false
    private var trackEnded: Bool = false
    
    private var playTimer: Timer?
    
    private var nowPlayingInfo = [String : Any]()
    
    // MARK: - Initialization
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

        commandCenter.changeShuffleModeCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            let shuffleStatus = event as! MPChangeShuffleModeCommandEvent
            
            if shuffleStatus.shuffleType == .off {
                self.shuffle(false)
                self.shuffleTracks = false
            } else {
                self.shuffle(true)
                self.shuffleTracks = true
            }

            return .success
        }
/*
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
        self.loopTrack = PlaybackStateProperty.loopTrack.getProperty() ?? false
        self.shuffleTracks = PlaybackStateProperty.shuffleTracks.getProperty() ?? false
        self.getNowPlayingPlaylist()
        self.currentTracklist = self.nowPlayingPlaylist?.tracks?.array as? [Track] ?? []
        self.originalTrackList = self.currentTracklist
        self.nowPlayingTrack = PlaybackStateProperty.lastPlayedTrack.getProperty()

        if !self.shuffleTracks {
            self.trackNum = PlaybackStateProperty.lastPlayedTracknum.getProperty() ?? 0
        }
        
        if self.trackNum < self.currentTracklist.count {
            self.setupAudioEngine()
        }
        
        if self.shuffleTracks {
            self.shuffle(true)
        }
    }
    
    private func setupAudioEngine() {
        let path = URL(fileURLWithPath: FileEngine.getMusicDirectory()).appendingPathComponent(self.nowPlayingTrack?.url ?? "").path

        AudioEngine.sharedInstance()?.stop()
        AudioEngine.sharedInstance()?.setFileName(path)
        AudioEngine.sharedInstance()?.setTrack(Int32(self.nowPlayingTrack?.trackNum ?? 0))
    }
    
    func getNowPlayingPlaylist() {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let context  = delegate.persistentContainer.viewContext
        let request = NSFetchRequest<Playlist>(entityName: "Playlist")
        request.predicate = NSPredicate(format: "isNowPlaying == true")
        request.returnsObjectsAsFaults = false
        do {
            let results = try context.fetch(request)
            self.nowPlayingPlaylist = results.first
            if self.nowPlayingPlaylist == nil {
                self.nowPlayingPlaylist = Playlist(context: context)
                try context.save()
                self.nowPlayingPlaylist?.isNowPlaying = true
            }
        } catch {
            NSLog("Could not get now playing playlist: \(error.localizedDescription)")
        }
    }
    
    func clearCurrentPlaybackState() {
        self.stop()
        self.nowPlayingTrack = nil
        self.currentTracklist = []
        self.originalTrackList = []
        self.nowPlayingPlaylist = nil
        self.trackNum = 0
        self.elapsedTime = 0
    }
    
    // MARK: - Playback Modifiers
    func shuffle() {
        if !self.shuffleTracks {
            self.shuffle(true)
        } else {
            self.shuffle(false)
        }
        self.shuffleTracks.toggle()
        PlaybackStateProperty.shuffleTracks.setProperty(newValue: self.shuffleTracks)
    }
    
    func shuffle(_ enabled: Bool) {
        if enabled {
            self.originalTrackList = self.currentTracklist
            var tempList = Array(self.currentTracklist)
            if self.nowPlayingTrack != nil {
                tempList.remove(at: self.trackNum)
            }
            tempList.shuffle()
            if self.nowPlayingTrack != nil {
                self.currentTracklist = [self.nowPlayingTrack!] + tempList
            } else {
                self.currentTracklist = tempList
            }
            self.trackNum = 0
        } else {
            self.currentTracklist = self.originalTrackList
            self.trackNum = self.currentTracklist.firstIndex(of: self.nowPlayingTrack ?? Track()) ?? 0
        }
    }
    
    func loop() {
        if self.loopTrack {
            self.setFade()
        }
        self.loopTrack.toggle()
        PlaybackStateProperty.loopTrack.setProperty(newValue: self.loopTrack)
    }
    
    func setFade() {
        if self.loopTrack {
            AudioEngine.sharedInstance()?.resetFadeTime()
        } else {
            if self.nowPlayingTrack?.loopLength ?? 0 > 0 {
                let loopCount = PlaybackStateProperty.loopCount.getProperty() ?? 2
                let loopLength = Int32(loopCount) * self.nowPlayingTrack!.loopLength
                let fadeOutTime = self.nowPlayingTrack!.introLength + loopLength
                AudioEngine.sharedInstance()?.setFadeTime(fadeOutTime)
            } else {
                AudioEngine.sharedInstance()?.setFadeTime(PlaybackStateProperty.trackLength.getProperty() ?? 150000)
            }
        }
    }
    
    // MARK: - Now Playing Info Center
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
        if self.nowPlayingTrack?.loopLength ?? 0 > 0 {
            let loopCount = PlaybackStateProperty.loopCount.getProperty() ?? 2
            let loopLength = self.nowPlayingTrack!.loopLength * Int32(loopCount)
            self.nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = (self.nowPlayingTrack!.introLength + loopLength) / 1000
        } else if self.nowPlayingTrack?.length ?? 0 > 0 {
            self.nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = Int(self.nowPlayingTrack!.length) / 1000
        } else {
            self.nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = (PlaybackStateProperty.trackLength.getProperty() ?? 150000) / 1000
        }
        self.updateNowPlayingElapsed()
    }
    
    func updateNowPlayingElapsed() {
        self.nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = self.elapsedTime / 1000
        MPNowPlayingInfoCenter.default().nowPlayingInfo = self.nowPlayingInfo
    }
    
    // MARK: - Playback
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
        if self.shuffleTracks {
            self.shuffle(true)
        } else {
            self.trackNum = index
        }
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
        self.play(nextTrack)
    }
    
    func prevTrack() {
        guard ((self.trackNum - 1) >= 0 && self.elapsedTime < 3000) else {
            self.stop()
            self.play()
            return
        }
        self.trackNum -= 1
        let prevTrack = self.currentTracklist[self.trackNum]
        self.play(prevTrack)
    }
}

// MARK: -
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
