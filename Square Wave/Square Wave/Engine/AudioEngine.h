//
//  AudioEngine.h
//  Square Wave
//
//  Created by Alex Busman on 5/6/18.
//  Copyright © 2018 Alex Busman. All rights reserved.
//

#ifndef AudioEngine_h
#define AudioEngine_h

#import <Foundation/Foundation.h>

@class AppDelegate;

@interface AudioEngine : NSObject

+ (AudioEngine *)sharedInstance;
- (void)setFileName:(NSString *)fileName;
- (void)setTrack:(int)track;
- (void)setMuteVoices:(int)mask;
- (int)getVoiceCount;
- (NSString *)getVoiceName:(int)index;
- (void)play;
- (void)pause;
- (void)stop;
- (void)nextTrack;
- (void)prevTrack;
- (int)getElapsedTime;
- (BOOL)isTrackEnded;
- (void)setFadeTime:(int)msec;
- (void)setTempo:(double)tempo;
- (void)ignoreSilence;
- (void)resetFadeTime;

@end
#endif /* AudioEngine_h */
