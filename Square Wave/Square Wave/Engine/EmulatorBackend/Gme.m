//
//  Gme.m
//  Square Waves
//
//  Created by Alex Busman on 3/14/20.
//  Copyright © 2020 Alex Busman. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Gme.h"
#import "EmulatorBackendPrivate.h"

#include "../gme/gme.h"

@interface Gme()

@property (atomic, readwrite) Music_Emu *mEmu;

@end

@implementation Gme

#define CHECK_EMU_AND_RETURN() \
do { \
if (!_mEmu) { \
return; \
} \
} while(0);

+ (BOOL)isFileCompatible:(NSString *)fileName {
    gme_type_t type = {0};
    gme_err_t err = gme_identify_file([fileName UTF8String], &type);
    
    if (err != NULL) {
        return NO;
    }
    return YES;
}

- (void)dealloc {
    if (_mEmu) {
        gme_delete(_mEmu);
        _mEmu = NULL;
    }
}

- (void)openFile:(NSString *)fileName {
    const char *path_string = [fileName UTF8String];
    handle_error(gme_open_file(path_string, &_mEmu, super.mSampleRate));
}

- (int)getTrackCount {
    @synchronized (self) {
        if (_mEmu == NULL) {
            return -1;
        }
        return gme_track_count(_mEmu);
    }
}

- (void)startTrack:(int)trackNum {
    @synchronized (self) {
        CHECK_EMU_AND_RETURN();
        handle_error(gme_start_track(_mEmu, trackNum));
    }
}

- (void)muteVoices:(int)mask {
    @synchronized (self) {
        CHECK_EMU_AND_RETURN();
        gme_mute_voices(_mEmu, mask);
    }
}

- (int)getVoiceCount {
    @synchronized (self) {
        if (_mEmu == NULL) {
            return 0;
        }
        return gme_voice_count(_mEmu);
    }
}

- (NSString *)getVoiceName:(int)index {
    @synchronized (self) {
        if (_mEmu == NULL) {
            return nil;
        }
        return [NSString stringWithUTF8String:gme_voice_name(_mEmu, index)];
    }
}

- (BOOL)getTrackEnded {
    @synchronized (self) {
        if (_mEmu == NULL) {
            return YES;
        }
        return gme_track_ended(_mEmu);
    }
}

- (void)setFade:(int)ms {
    @synchronized (self) {
        CHECK_EMU_AND_RETURN();
        gme_set_fade(_mEmu, ms);
    }
}

- (void)setTempo:(double)tempo {
    @synchronized (self) {
        CHECK_EMU_AND_RETURN();
        gme_set_tempo(_mEmu, tempo);
    }
}

- (void)resetFade {
    @synchronized (self) {
        CHECK_EMU_AND_RETURN();
        gme_reset_fade(_mEmu);
    }
}

- (int)tell {
    @synchronized (self) {
        if (_mEmu == nil) {
            return -1;
        }
        return gme_tell(_mEmu);
    }
}

- (void)play:(int)sampleCount buffer:(SInt16 *)buf {
    @synchronized (self) {
        CHECK_EMU_AND_RETURN();
        handle_error(gme_play(_mEmu, sampleCount, buf));
    }
}

static void handle_error(const char* str) {
    if (str) {
        NSLog(@"%@", [NSString stringWithUTF8String:str]);
    }
}
@end
