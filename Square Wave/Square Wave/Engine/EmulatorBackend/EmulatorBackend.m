//
//  EmulatorBackend.m
//  Square Waves
//
//  Created by Alex Busman on 3/14/20.
//  Copyright © 2020 Alex Busman. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "EmulatorBackend.h"
#import "EmulatorBackendPrivate.h"

@implementation EmulatorBackend

+ (BOOL)isFileCompatible:(NSString *)fileName {
    NSLog(@"%s unimplemented", __FUNCTION__);
    return NO;
}

- (id)init {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
      reason:@"-init is not a valid initializer for the class Foo"
    userInfo:nil];
}

- (id)init:(int)sampleRate {
    if (!(self = [super init])) return nil;
    _mSampleRate = sampleRate;
    return self;
}

- (void)openFile:(NSString *)fileName {
    NSLog(@"%s unimplemented", __FUNCTION__);
}

- (int)getTrackCount {
    NSLog(@"%s unimplemented", __FUNCTION__);
    return -1;
}

- (void)startTrack:(int)trackNum {
    NSLog(@"%s unimplemented", __FUNCTION__);
}

- (void)muteVoices:(int)mask {
    NSLog(@"%s unimplemented", __FUNCTION__);
}

- (int)getVoiceCount {
    NSLog(@"%s unimplemented", __FUNCTION__);
    return -1;
}

- (NSString *)getVoiceName:(int)index {
    NSLog(@"%s unimplemented", __FUNCTION__);
    return nil;
}

- (BOOL)isTrackEnded {
    NSLog(@"%s unimplemented", __FUNCTION__);
    return NO;
}

- (void)setFade:(int)ms {
    NSLog(@"%s unimplemented", __FUNCTION__);
}

- (void)setTempo:(double)tempo {
    NSLog(@"%s unimplemented", __FUNCTION__);
}

- (void)resetFade {
    NSLog(@"%s unimplemented", __FUNCTION__);
}

- (int)tell {
    NSLog(@"%s unimplemented", __FUNCTION__);
    return -1;
}

- (void)play:(int)sampleCount buffer:(SInt16 *)buf {
    NSLog(@"%s unimplemented", __FUNCTION__);
}

- (void)ignoreSilence:(int)ignore {
    NSLog(@"%s unimplemented", __FUNCTION__);
}

@end
