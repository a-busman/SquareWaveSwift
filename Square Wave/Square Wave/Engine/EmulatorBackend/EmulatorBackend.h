//
//  EmulatorBackend.h
//  Square Waves
//
//  Created by Alex Busman on 3/14/20.
//  Copyright © 2020 Alex Busman. All rights reserved.
//

#ifndef EmulatorBackend_h
#define EmulatorBackend_h

@class Track;

typedef struct {
    // Track data
    UInt32 introLength;
    UInt32 length;
    UInt32 loopLength;
    NSString * title;
    UInt16 trackNum;
    
    // Artist data
    NSString * artist;
    
    // Game data
    NSString * game;
    NSString * year;
    
    // System data
    NSString * system;
} track_info_t;

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
+ (track_info_t)getTrackInfo:(NSString *)fileName trackNum:(UInt16)trackNum;
- (track_info_t)getTrackInfo:(UInt16)trackNum;

@property (nonatomic, readwrite) int mSampleRate;

@end

#endif /* EmulatorBackend_h */
