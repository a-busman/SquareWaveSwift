//
//  EmulatorBackend.h
//  Square Waves
//
//  Created by Alex Busman on 3/14/20.
//  Copyright © 2020 Alex Busman. All rights reserved.
//

#ifndef EmulatorBackend_h
#define EmulatorBackend_h

#import <Foundation/Foundation.h>

@interface EmulatorBackend : NSObject

+ (BOOL)isFileCompatible:(NSString *)fileName;
- (id)init:(int)sampleRate;
- (void)openFile:(NSString *)fileName;
- (int)getTrackCount;
- (void)startTrack:(int)trackNum;
- (void)muteVoices:(int)mask;
- (int)getVoiceCount;
- (NSString *)getVoiceName:(int)index;
- (BOOL)isTrackEnded;
- (void)setFade:(int)ms;
- (void)setTempo:(double)tempo;
- (void)resetFade;
- (int)tell;
- (void)ignoreSilence:(int)ignore;
- (void)play:(int)sampleCount buffer:(SInt16 *)buf;

@end

#endif /* EmulatorBackend_h */
