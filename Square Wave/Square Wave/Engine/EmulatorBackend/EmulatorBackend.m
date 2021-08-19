//
//  EmulatorBackend.m
//  Square Waves
//
//  Created by Alex Busman on 3/14/20.
//  Copyright © 2020 Alex Busman. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "EmulatorBackend.h"

#define UNIMPLEMENTED_EXCEPTION [NSException exceptionWithName:NSInternalInconsistencyException \
                                     reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)] \
                                     userInfo:nil]

@implementation EmulatorBackend

+ (BOOL)isFileCompatible:(NSString *)fileName {
    @throw UNIMPLEMENTED_EXCEPTION;
    return NO;
}

- (id)init {
    @throw UNIMPLEMENTED_EXCEPTION;
}

- (id)init:(int)sampleRate {
    if (!(self = [super init])) return nil;
    _mSampleRate = sampleRate;
    return self;
}

- (void)openFile:(NSString *)fileName {
    @throw UNIMPLEMENTED_EXCEPTION;
}

- (int)getTrackCount {
    @throw UNIMPLEMENTED_EXCEPTION;
    return -1;
}

- (void)startTrack:(int)trackNum {
    @throw UNIMPLEMENTED_EXCEPTION;
}

- (void)muteVoices:(int)mask {
    @throw UNIMPLEMENTED_EXCEPTION;
}

- (int)getVoiceCount {
    @throw UNIMPLEMENTED_EXCEPTION;
    return -1;
}

- (NSString *)getVoiceName:(int)index {
    @throw UNIMPLEMENTED_EXCEPTION;
    return nil;
}

- (BOOL)isTrackEnded {
    @throw UNIMPLEMENTED_EXCEPTION;
    return NO;
}

- (void)setFade:(int)ms {
    @throw UNIMPLEMENTED_EXCEPTION;
}

- (void)setTempo:(double)tempo {
    @throw UNIMPLEMENTED_EXCEPTION;
}

- (void)resetFade {
    @throw UNIMPLEMENTED_EXCEPTION;
}

- (int)tell {
    @throw UNIMPLEMENTED_EXCEPTION;
    return -1;
}

- (void)play:(int)sampleCount buffer:(SInt16 *)buf {
    @throw UNIMPLEMENTED_EXCEPTION;
}

- (void)ignoreSilence:(int)ignore {
    @throw UNIMPLEMENTED_EXCEPTION;
}

+ (Track *)getTrackInfo:(NSString *)fileName {
    @throw UNIMPLEMENTED_EXCEPTION;
    return nil;
}

- (Track *)getTrackInfo {
    @throw UNIMPLEMENTED_EXCEPTION;
    return nil;
}

@end
