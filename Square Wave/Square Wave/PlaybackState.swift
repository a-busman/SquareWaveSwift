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


///Playback State Properties. This is an enum that maps directly to user defaults.
enum PlaybackStateProperty: String {
    /// UUID of last played track
    case lastPlayedTrack    = "lastPlayedTrack"
    /// Last played track number in a "now playing" playlist
    case lastPlayedTracknum = "lastPlayedTracknum"
    /// Whether or not to loop an individual track
    case loopTrack          = "loopTrack"
    /// Whether or not the playlist should be shuffled
    case shuffleTracks      = "shuffleTracks"
    /// User specified length of track for tracks without loop information
    case trackLength        = "trackLength"
    /// User specified amount of loops for tracks with loop information
    case loopCount          = "loopCount"
    /// User specified playback speed
    case tempo              = "tempo"
    /// How to sort tracks
    case sortType           = "sortType"

    /**
     Gets a property from userdefaults, or initializes a new value.
     - Returns: The property to get as the called type.
     */
    func getProperty<T>() -> T? {
        switch(self) {
        case .lastPlayedTrack:
            let delegate = UIApplication.shared.delegate as! AppDelegate
            let context = delegate.persistentContainer.viewContext
            if let id = UserDefaults.standard.string(forKey: self.rawValue) {
                let request = NSFetchRequest<Track>(entityName: "Track")
                request.predicate = NSPredicate(format: "id == %@", (UUID(uuidString: id) ?? UUID()) as CVarArg)
                request.returnsObjectsAsFaults = false
                do {
                    let results = try context.fetch(request)
                    if let track = results.first as? T {
                        return track
                    }
                } catch {
                    NSLog("Could not get last played track: %s", error.localizedDescription)
                }
            }
            return nil
        case .sortType:
            fallthrough
        case .lastPlayedTracknum:
            return UserDefaults.standard.integer(forKey: self.rawValue) as? T
        case .loopCount:
            let loopCount = UserDefaults.standard.integer(forKey: self.rawValue)
            return loopCount == 0 ? 2 as? T : loopCount as? T
        case .trackLength:
            let trackLength = UserDefaults.standard.integer(forKey: self.rawValue)
            return trackLength == 0 ? 150000 as? T : trackLength as? T
        case .loopTrack:
            fallthrough
        case .shuffleTracks:
            return UserDefaults.standard.bool(forKey: self.rawValue) as? T
        case .tempo:
            let value = UserDefaults.standard.double(forKey: self.rawValue)
            return value == 0.0 ? 1.0 as? T : value as? T
        }
    }
    
    /**
     Sets a property in userdefaults
     - Parameter newValue: The value to set to the given property.
     */
    func setProperty(newValue: Any?) {
        switch(self) {
        case .lastPlayedTrack:
            if let uuid = newValue as? UUID {
                UserDefaults.standard.set(uuid.uuidString, forKey: self.rawValue)
            } else {
                UserDefaults.standard.removeObject(forKey: self.rawValue)
            }
        case .sortType:
            fallthrough
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
        case .tempo:
            if let val = newValue as? Double {
                UserDefaults.standard.set(val, forKey: self.rawValue)
            }
        }
    }
}

// MARK: -
/// Overall playback state of the app.
class PlaybackState: ObservableObject {
    /// Whether or not the audio engine is currently playing.
    @Published var isNowPlaying = false {
        didSet {
            if self.isNowPlaying {
                self.playTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                    self.elapsedTime = Int(Double(AudioEngine.sharedInstance()?.getElapsedTime() ?? 0) * self.currentTempo)
                    self.updateNowPlayingElapsed()
                    if let didEnd = AudioEngine.sharedInstance()?.getTrackEnded() {
                        if (didEnd && !self.loopTrack && !self.trackEnded) || (didEnd && self.loopTrack && !self.trackEnded && self.nowPlayingTrack?.length ?? 0 > 0) {
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

    /// What the current track is that is playing, or will be played
    @Published var nowPlayingTrack:  Track? {
        didSet {
            PlaybackStateProperty.lastPlayedTrack.setProperty(newValue: self.nowPlayingTrack?.id)
        }
    }
    /// Playlist representing the track list that is now playing. Used primariy for saving to coredata
    private var nowPlayingPlaylist: Playlist?
    /// List of tracks to go through when progressing through tracks
    @Published var currentTracklist: [Track] = [] {
        didSet {
            if self.currentTracklist.count == 0 {
                self.trackNum = 0
                return
            }
            if self.nowPlayingPlaylist == nil {
                self.getNowPlayingPlaylist()
            }
            if self.nowPlayingTrack != nil {
                self.trackNum = self.currentTracklist.firstIndex(of: self.nowPlayingTrack!) ?? 0
            }
            let delegate = UIApplication.shared.delegate as! AppDelegate
            self.nowPlayingPlaylist?.removeFromTracks(at: NSIndexSet(indexesIn: NSRange(location: 0, length: self.nowPlayingPlaylist?.tracks?.count ?? 1)))
            let playlistToSave = self.originalTrackList.count == 0 ? self.currentTracklist : self.originalTrackList
            self.nowPlayingPlaylist?.addToTracks(NSOrderedSet(array: playlistToSave))
            delegate.saveContext()
        }
    }
    /// List of tracks to go through in the original order in case a shuffle occurs.
    private var originalTrackList: [Track] = []
    @Published var trackNum = 0 {
        didSet {
            PlaybackStateProperty.lastPlayedTracknum.setProperty(newValue: self.trackNum)
        }
    }
    /// Time in ms the currently playing track has progressed.
    var elapsedTime   = 0
    /// Whether or not to keep looping the current track.
    @Published var loopTrack     = false
    /// Whether or not to play the current track list in a random order.
    @Published var shuffleTracks = false
    /// Current tempo of playing track
    @Published var currentTempo  = 1.0
    /// Whether or not the current track has finished playing.
    private var trackEnded: Bool = false
    /// Timer used to update track information and determine if track has ended
    private var playTimer: Timer?
    /// Info for MPNowPlayingInfoCenter
    private var nowPlayingInfo = [String : Any]()
    /// Mask of which voices to mute.
    @Published var muteMask: Int = 0
    /// Whether or not there are any tracks in the DB
    @Published var hasTracks: Bool = false
    
    // MARK: - Initialization
    /**
     Initializes a new Playback State, and sets up MPRemoteCommandCenter
     - Returns: New playback state
     */
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
            if self.isNowPlaying {
                self.pause()
            }
            return .success
        }
        
        commandCenter.playCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            if !self.isNowPlaying {
                self.play()
            }
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

        commandCenter.changeRepeatModeCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            let repeatStatus = event as! MPChangeRepeatModeCommandEvent
            
            if repeatStatus.repeatType == .off {
                self.loopTrack = false
                PlaybackStateProperty.loopTrack.setProperty(newValue: false)
                self.setFade()
            } else {
                self.loopTrack = true
                PlaybackStateProperty.loopTrack.setProperty(newValue: true)
                self.setFade()
            }
            return .success
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleAudioInterruption), name: .AVCaptureSessionWasInterrupted, object: AVAudioSession.sharedInstance())
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleAudioInterruption), name: .AVCaptureSessionInterruptionEnded, object: AVAudioSession.sharedInstance())
 
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
        self.currentTempo = PlaybackStateProperty.tempo.getProperty() ?? 1.0
        
        let req: NSFetchRequest = Track.fetchRequest()
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        self.hasTracks = (try? context.count(for: req)) ?? 0 != 0
    }
    /**
     Handles any audio interruption by pausing when interruption began, and playing when it ended
     - Parameter notification: The interruption notification.
     */
    @objc private func handleAudioInterruption(_ notification: Notification) {
        guard let info = notification.userInfo,
              let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
                return
        }
        
        if type == .began {
            self.pause()
        }
        else if type == .ended {
            guard let optionsValue = info[AVAudioSessionInterruptionOptionKey] as? UInt else {
                return
            }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume) {
                self.play()
            }
        }
    }
    
    /**
     Sets up the audio engine to get ready to play the current playing track.
     */
    private func setupAudioEngine() {
        let path = URL(fileURLWithPath: FileEngine.getMusicDirectory()).appendingPathComponent(self.nowPlayingTrack?.url ?? "").path

        AudioEngine.sharedInstance()?.stop()
        AudioEngine.sharedInstance()?.setFileName(path)
        AudioEngine.sharedInstance()?.setTrack(Int32(self.nowPlayingTrack?.trackNum ?? 0))
    }
    
    /**
     Gets the now playing playlist from coredata
     */
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
    
    /**
     Populates the current track list with all tracks from coredata
     */
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
    
    /**
     Resets states to initial values
     */
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
    /**
     Toggles shuffling of the current track list.
     */
    func shuffle() {
        self.shuffleTracks.toggle()
        PlaybackStateProperty.shuffleTracks.setProperty(newValue: self.shuffleTracks)
        self.shuffle(self.shuffleTracks)
    }
    
    /**
     Utility function to shuffle current track list, given whether or not it is enabled
     - Parameter enabled: Whether or not to enable shuffle
     */
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
            if let track = self.nowPlayingTrack {
                self.trackNum = self.currentTracklist.firstIndex(of: track) ?? 0
            } else {
                self.trackNum = 0
            }
        }
    }
    
    /**
     Toggles infinite looping of now playing tracks
     */
    func loop() {
        self.loopTrack.toggle()
        PlaybackStateProperty.loopTrack.setProperty(newValue: self.loopTrack)
        self.setFade()
        self.updateNowPlayingInfoCenter()
    }
    
    /**
     Sets the fade out time of the currently playing track
     */
    func setFade() {
        if self.loopTrack {
            AudioEngine.sharedInstance()?.resetFadeTime()
        } else {
            if self.nowPlayingTrack?.loopLength ?? 0 > 0 {
                let loopCount: Int = PlaybackStateProperty.loopCount.getProperty() ?? 2
                let loopLength = Int32(loopCount) * self.nowPlayingTrack!.loopLength
                let fadeOutTime = self.nowPlayingTrack!.introLength + loopLength
                AudioEngine.sharedInstance()?.setFadeTime(Int32(Double(fadeOutTime) / self.currentTempo))
            } else if self.nowPlayingTrack?.length ?? 0 > 0 {
                let fadeTime = self.nowPlayingTrack!.length
                AudioEngine.sharedInstance()?.setFadeTime(Int32(Double(fadeTime) / self.currentTempo))
            } else {
                let fadeTime: Int = PlaybackStateProperty.trackLength.getProperty() ?? 150000
                AudioEngine.sharedInstance()?.setFadeTime(Int32(Double(fadeTime) / self.currentTempo))
            }
        }
    }
    
    /**
     Sets the playback rate of current tracks.
     - Parameter tempo: Tempo to set.
     */
    func set(tempo: Double) {
        self.currentTempo = tempo
        self.setFade()
        self.updateNowPlayingInfoCenter()
        AudioEngine.sharedInstance()?.setTempo(tempo)
        PlaybackStateProperty.tempo.setProperty(newValue: tempo)
    }

    // MARK: - Now Playing Info Center
    /**
     Updates all of the MPNowPlayingInfoCenter
     */
    func updateNowPlayingInfoCenter() {
        self.nowPlayingInfo[MPMediaItemPropertyTitle] = self.nowPlayingTrack?.name ?? ""
        self.nowPlayingInfo[MPMediaItemPropertyArtist] = self.nowPlayingTrack?.game?.name ?? ""
        self.nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = self.nowPlayingTrack?.system?.name ?? ""
        self.nowPlayingInfo[MPMediaItemPropertyGenre] = "Video Game"
        
        let image = ListArtView.getImage(for: self.nowPlayingTrack?.system?.name ?? "")
        let mediaArtwork = MPMediaItemArtwork(boundsSize: CGSize(width: 768, height: 768), requestHandler: { (size) -> UIImage in
            if let scaledImage = image?.image(with: size) {
                return scaledImage
            } else {
                return image!
            }
        })
        self.nowPlayingInfo[MPMediaItemPropertyArtwork] = mediaArtwork
        if !self.loopTrack {
            if self.nowPlayingTrack?.loopLength ?? 0 > 0 {
                let loopCount: Int = PlaybackStateProperty.loopCount.getProperty() ?? 2
                let loopLength = self.nowPlayingTrack!.loopLength * Int32(loopCount)
                self.nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = (self.nowPlayingTrack!.introLength + loopLength) / 1000
            } else if self.nowPlayingTrack?.length ?? 0 > 0 {
                self.nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = Int(self.nowPlayingTrack!.length) / 1000
            } else {
                let trackLength: Int = PlaybackStateProperty.trackLength.getProperty() ?? 150000
                self.nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = trackLength / 1000
            }
            self.nowPlayingInfo[MPNowPlayingInfoPropertyIsLiveStream] = false
            self.nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = self.currentTempo
        } else {
            self.nowPlayingInfo[MPNowPlayingInfoPropertyIsLiveStream] = true
        }
        self.updateNowPlayingElapsed()
    }
    
    /**
     Updates the elapsed time of the MPNowPlayingInfoCenter
     */
    func updateNowPlayingElapsed() {
        self.nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = self.elapsedTime / 1000
        MPNowPlayingInfoCenter.default().nowPlayingInfo = self.nowPlayingInfo
    }
    
    // MARK: - Playback
    /**
     Plays the current track. If there is no current track, it will populate the track list with all tracks, and begin playing at the beginning.
     Also updates MPNowPlayingInfoCenter
     */
    func play() {
        guard !self.isNowPlaying else {
            return
        }
        guard self.currentTracklist.count > 0 else {
            self.populateTrackList()
            if (self.currentTracklist.count > 0) {
                self.play(index: 0)
            }
            return
        }
        self.isNowPlaying = true
        self.nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = self.currentTempo
        self.updateNowPlayingInfoCenter()
        DispatchQueue.global().async {
            AudioEngine.sharedInstance()?.setTempo(self.currentTempo)
            AudioEngine.sharedInstance()?.setMuteVoices(Int32(self.muteMask))
            AudioEngine.sharedInstance()?.play()
            self.setFade()
        }

        
    }
    /**
     Pauses the currently playing track, and updates MPNowPlayingInfoCenter
     */
    func pause() {
        self.isNowPlaying = false
        self.nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 0.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = self.nowPlayingInfo
        DispatchQueue.global().async {
            AudioEngine.sharedInstance()?.pause()
        }
    }
    
    /**
     Plays a given index in the current track list
     - Parameter index: Index to play
     */
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
    
    /**
     Plays a given track.
     - Parameter track: Track to play.
     */
    private func play(_ track: Track) {
        self.elapsedTime = 0
        self.nowPlayingTrack = track
        self.nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 1.0
        self.updateNowPlayingInfoCenter()
        self.isNowPlaying = true
        DispatchQueue.global().async {
            let path = URL(fileURLWithPath: FileEngine.getMusicDirectory()).appendingPathComponent(track.url!).path

            AudioEngine.sharedInstance()?.stop()
            AudioEngine.sharedInstance()?.setFileName(path)
            AudioEngine.sharedInstance()?.setTrack(Int32(track.trackNum))
            AudioEngine.sharedInstance()?.setTempo(self.currentTempo)
            AudioEngine.sharedInstance()?.setMuteVoices(Int32(self.muteMask))
            AudioEngine.sharedInstance()?.play()
            self.setFade()

        }
    }
    
    /**
     Stops the audio engine and updates MPNowPlayingInfoCenter
     */
    func stop() {
        self.isNowPlaying = false
        AudioEngine.sharedInstance()?.stop()
        self.nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 0.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = self.nowPlayingInfo
    }
    
    /**
     If another track is available in the current track list, play the next track
     */
    func nextTrack() {
        guard (self.trackNum + 1) < self.currentTracklist.count else { return }
        self.trackNum += 1
        let nextTrack = self.currentTracklist[self.trackNum]
        self.play(nextTrack)
    }
    
    /**
     If we aren't already at the first track in the track list, play the previous track. Will restart current track if over 3 seconds of playback has occurred on current track.
     */
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
    /**
     Resize an image, and return a new UIImage
     - Parameter size: Size to scale image to
     - Returns: New UIImage, or nil if UIGraphicsGetImageFromCurrentImageContext fails.
     */
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
