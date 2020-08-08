//
//  Sid.m
//  Square Waves
//
//  Created by Alex Busman on 3/14/20.
//  Copyright © 2020 Alex Busman. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Sid.h"
#import "EmulatorBackendPrivate.h"

#include "../../libsidplay/player.h"

@interface Sid()

@end

@implementation Sid

+ (BOOL)isFileCompatible:(NSString *)fileName {
    return NO;
}

- (void)dealloc {
    
}

- (void)openFile:(NSString *)fileName {
    
}

- (int)getTrackCount {
    return 0;
}

- (void)startTrack:(int)trackNum {
    
}

- (void)muteVoices:(int)mask {
    
}

- (void)getVoiceCount {
    
}

- (NSString *)getVoiceName:(int)index {
    return nil;
}

- (BOOL)getTrackEnded {
    return NO;
}

- (void)setFade:(int)ms {
    
}

- (void)setTempo:(double)tempo {
    
}

- (void)resetFade {
    
}

- (int)tell {
    return 0;
}

- (void)play:(int)sampleCount buffer:(SInt16 *)buf {
    
}

- (void)ignoreSilence:(int)ignore {
    
}

@end
