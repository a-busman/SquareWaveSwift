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

@interface TrackInfo : NSObject

@property NSString *title;
@property NSString *artist;
@property NSString *system;
@property NSString *game;
@property int play_length;
@property int length;
@property int intro_length;
@property int loop_length;
@end

@interface AudioEngine : NSObject

+ (AudioEngine *)sharedInstance;
- (void)setFileName:(NSString *)fileName;
- (void)setTrack:(int)track;
- (void)setMuteVoices:(int)mask;
- (void)play;
- (void)pause;
- (void)stop;
- (void)nextTrack;
- (void)prevTrack;
- (TrackInfo *)getCurrentTrackInfo;

@end
#endif /* AudioEngine_h */
