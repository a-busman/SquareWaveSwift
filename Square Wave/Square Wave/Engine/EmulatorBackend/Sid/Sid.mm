//
//  Sid.m
//  Square Waves
//
//  Created by Alex Busman on 3/14/20.
//  Copyright © 2020 Alex Busman. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Sid.h"

#include "../../libsidplay/config.h"
#include "../../libsidplay/sidplayfp/sidplayfp.h"
#include "../../libsidplay/sidplayfp/SidTune.h"
#include "../../libsidplay/sidplayfp/SidTuneInfo.h"

#define CHECK_AND_RETURN(var) \
do { \
if ((var) == nullptr) { \
return; \
} \
} while(0);

#define CHECK_EMU_AND_RETURN() CHECK_AND_RETURN(_mPlayer)
#define CHECK_TUNE_AND_RETURN() CHECK_AND_RETURN(_mTune)

#define UNSUPPORTED(fn_name) NSLog(@"%@ unsupported for SID", fn_name)

@interface Sid()

@property (atomic, readwrite) sidplayfp *mPlayer;
@property (atomic, readwrite) SidTune *mTune;

@end

NSArray * sidFileNameExt = [NSArray arrayWithObjects:
    // Preferred default file extension for single-file sidtunes
    // or sidtune description files in SIDPLAY INFOFILE format.
    @".sid", @".SID",
    // File extensions used (and created) by various C64 emulators and
    // related utilities. These extensions are recommended to be used as
    // a replacement for ".dat" in conjunction with two-file sidtunes.
    @".c64", @".prg", @".p00", @".C64", @".PRG", @".P00",
    // Stereo Sidplayer (.mus/.MUS ought not be included because
    // these must be loaded first; it sometimes contains the first
    // credit lines of a MUS/STR pair).
    @".str", @".STR", @".mus", @".MUS",
    // End.
    nil];

@implementation Sid

+ (BOOL)isFileCompatible:(NSString *)fileName {
    for (NSString * ext in sidFileNameExt) {
        if ([fileName isEqualToString:ext]) {
            return YES;
        }
    }
    return NO;
}

- (void)dealloc {
    if (_mTune != nullptr) {
        delete(_mTune);
        _mTune = nullptr;
    }
    if (_mPlayer != nullptr) {
        _mPlayer->stop();
        delete(_mPlayer);
        _mPlayer = nullptr;
    }
}

- (void)openFile:(NSString *)fileName {
    _mTune = new SidTune([fileName UTF8String]);
    _mPlayer = new sidplayfp();
    _mPlayer->load(_mTune);
}

- (int)getTrackCount {
    @synchronized (self) {
        if (_mTune == nullptr) {
            return -1;
        }
        return _mTune->getInfo()->songs();
    }
}

- (void)startTrack:(int)trackNum {
    @synchronized (self) {
        CHECK_TUNE_AND_RETURN();
        _mTune->selectSong(trackNum);
    }
}

- (void)muteVoices:(int)mask {
    @synchronized (self) {
        CHECK_EMU_AND_RETURN();
        for (int voice = 0; mask != 0; voice++, mask >>= 1) {
            // Each SID chip has 3 voices
            int sid = voice / 3;
            int voiceIndex = voice % 3;
            BOOL enable = !(mask & 0x1);
            
            _mPlayer->mute(sid, voiceIndex, enable);
        }
    }
}

- (int)getVoiceCount {
    return 3 * _mTune->getInfo()->sidChips();
}

- (NSString *)getVoiceName:(int)index {
    return [NSString stringWithFormat:@"SID %d", index + 1];
}

- (BOOL)isTrackEnded {
    return NO;
}

- (void)setFade:(int)ms {
    UNSUPPORTED(@"setFade");
}

- (void)setTempo:(double)tempo {
    @synchronized (self) {
        CHECK_EMU_AND_RETURN();
        if (!_mPlayer->fastForward(tempo * 100)) {
            NSLog(@"Could not fast forward: %s", _mPlayer->error());
        }
    }
}

- (void)resetFade {
    UNSUPPORTED(@"resetFade");
}

- (int)tell {
    @synchronized (self) {
        if (_mPlayer == nullptr) {
            return -1;
        }
        return _mPlayer->timeMs();
    }
}

- (void)play:(int)sampleCount buffer:(SInt16 *)buf {
    @synchronized (self) {
        CHECK_EMU_AND_RETURN();
        _mPlayer->stop();
        _mPlayer->play(buf, sampleCount);
    }
}

- (void)ignoreSilence:(int)ignore {
    UNSUPPORTED(@"ignoreSilence");
}

- (track_info_t)getTrackInfo:(UInt16)trackNum {
    @synchronized (self) {
        track_info_t trackInfo = {};
        if (_mTune == nullptr) {
            return trackInfo;
        }
        const SidTuneInfo * info = _mTune->getInfo(trackNum);
        
        return [Sid getTrackInfo:info];
    }
}

+ (track_info_t)getTrackInfo:(NSString *)fileName trackNum:(UInt16)trackNum {
    SidTune * tune = new SidTune([fileName UTF8String]);
    if (tune == nullptr) {
        return track_info_t{};
    }
    return [Sid getTrackInfo:tune->getInfo(trackNum)];
}

+ (track_info_t)getTrackInfo:(const SidTuneInfo *)info {
    track_info_t trackInfo = {};
    if (info == nullptr) {
        return trackInfo;
    }
    
    if (info->numberOfInfoStrings() > 0) {
        trackInfo.title = [NSString stringWithUTF8String:info->infoString(0)];
    }
    if (info->numberOfInfoStrings() > 1) {
        trackInfo.artist = [NSString stringWithUTF8String:info->infoString(1)];
    }
    trackInfo.trackNum = info->currentSong();
    trackInfo.system = @"Commodore 64";
    
    // Get game name from file name
    trackInfo.game = [[NSString stringWithUTF8String:info->dataFileName()] stringByDeletingPathExtension];
    
    return trackInfo;
}

@end
