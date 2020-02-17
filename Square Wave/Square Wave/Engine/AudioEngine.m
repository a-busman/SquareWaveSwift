//
//  AudioEngine.m
//  Square Wave
//
//  Created by Alex Busman on 5/6/18.
//  Copyright © 2018 Alex Busman. All rights reserved.
//

#import "gme/gme.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

#import "AudioEngine.h"

@interface AudioEngine()
@property AudioStreamBasicDescription mStreamFormat;
@property Boolean                     mIsPlaying;
@property Boolean                     mIsPaused;
@property NSString *                  mFileName;


@property AudioQueueRef               mAudioQueue;
@property AudioQueueBufferRef         mAudioQueueBuf;
@property int                         mTrack;
@property int                         mVoiceMask;
@property Music_Emu *                 mEmu;
@end

@interface TrackInfo()

@end

@implementation TrackInfo

- (id)init {
    if (!(self = [super init])) return nil;
    return self;
}

@end

@implementation AudioEngine

#define CHECK_EMU_AND_RETURN() \
if (!_mEmu) { \
return; \
}
const int kSampleRate = 44100;
const int kBufferSize = 8000;
const int kBufferCount = 3;

+ (AudioEngine *)sharedInstance {
    static AudioEngine *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[AudioEngine alloc] init];
    });
    return sharedInstance;
}

- (id)init {
    if (!(self = [super init])) return nil;

    [self setupFormat];
    OSStatus err = AudioQueueNewOutput(&_mStreamFormat, AudioEngineOutputBufferCallback, (__bridge void * _Nullable)(self), nil, nil, 0, &_mAudioQueue);
    if (err != noErr) {
        NSLog(@"AudioQueueNewOutput() error: %d", err);
        return nil;
    }
    return self;
}

- (void)setFileName:(NSString *)fileName {
    if (_mEmu) {
        gme_delete(_mEmu);
        _mEmu = NULL;
    }
    _mFileName = fileName;
    const char *path_string = [_mFileName UTF8String];
    handle_error(gme_open_file(path_string, &_mEmu, kSampleRate));
}

- (void)setTrack:(int)track {
    CHECK_EMU_AND_RETURN();
    _mTrack = track;
    int count = gme_track_count(_mEmu);
    if (_mTrack > count - 1) {
        _mTrack = count - 1;
    }
    handle_error(gme_start_track(_mEmu, _mTrack));
}

- (void)play {
    CHECK_EMU_AND_RETURN();
    if (!_mFileName) {
        NSLog(@"No file name to play");
        return;
    }
    if (_mIsPaused == NO) {
        handle_error(gme_start_track(_mEmu, _mTrack));
        [self setupFormat];
    }
    AVAudioSession *session = AVAudioSession.sharedInstance;
    [session setActive:true error:NULL];
    [self startAudioQueue];
}

- (void)pause {
    AudioQueuePause(_mAudioQueue);
    AVAudioSession *session = AVAudioSession.sharedInstance;
    [session setActive:false error:NULL];
    _mIsPaused = YES;
}

- (void)stop {
    _mIsPlaying = NO;
    _mIsPaused = NO;
    AudioQueueStop(_mAudioQueue, YES);
    AVAudioSession *session = AVAudioSession.sharedInstance;
    [session setActive:false error:NULL];

}

- (void)nextTrack {
    CHECK_EMU_AND_RETURN();
    int count = gme_track_count(_mEmu);
    _mTrack++;
    if (_mTrack > count - 1) {
        _mTrack--;
    }
    else handle_error(gme_start_track(_mEmu, _mTrack));
}

- (void)prevTrack {
    CHECK_EMU_AND_RETURN();
    _mTrack--;
    if (_mTrack < 0) {
        _mTrack++;
    }
    else handle_error(gme_start_track(_mEmu, _mTrack));
}

- (void)setMuteVoices:(int)mask {
    CHECK_EMU_AND_RETURN();
    _mVoiceMask = mask;
    gme_mute_voices(_mEmu, mask);
}

- (BOOL)getTrackEnded {
    if (_mEmu) {
        return gme_track_ended(_mEmu);
    }
    return true;
}

- (void)fadeOutCurrentTrack {
    CHECK_EMU_AND_RETURN();
    gme_info_t *info = NULL;
    gme_track_info(_mEmu, &info, _mTrack);
    gme_set_fade(_mEmu, info->play_length);
    gme_free_info(info);
}

- (void)setFadeTime:(int)msec {
    CHECK_EMU_AND_RETURN();
    gme_set_fade(_mEmu, msec);
}

- (void)resetFadeTime {
    CHECK_EMU_AND_RETURN();
    gme_reset_fade(_mEmu);
}

- (TrackInfo *)getCurrentTrackInfo {
    if (!_mEmu) {
        return NULL;
    }
    TrackInfo *ret = [[TrackInfo alloc] init];
    gme_info_t *info = NULL;
    
    gme_track_info(_mEmu, &info, _mTrack);
    
    ret.artist = [[NSString alloc] initWithUTF8String:info->author];
    ret.game   = [[NSString alloc] initWithUTF8String:info->game];
    if (strlen(info->song) == 0) {
        ret.title = [[NSString alloc] initWithFormat:@"Track %d", _mTrack + 1];
    } else {
        ret.title  = [[NSString alloc] initWithUTF8String:info->song];
    }
    ret.system = [[NSString alloc] initWithUTF8String:info->system];
    
    ret.play_length  = info->play_length;
    ret.length       = info->length;
    ret.intro_length = info->intro_length;
    ret.loop_length  = info->loop_length;
    
    gme_free_info(info);
    return ret;
}

- (int)getElapsedTime {
    if (_mEmu) {
        return gme_tell(_mEmu);
    }
    return -1;
}

- (void)startAudioQueue {
    CHECK_EMU_AND_RETURN();
    if (_mIsPlaying == NO) {
        OSStatus err;
        AudioQueueReset(_mAudioQueue);
        for (int i = 0; i < kBufferCount; ++i) {
            err = AudioQueueAllocateBuffer(_mAudioQueue, kBufferSize, &_mAudioQueueBuf);
            if (err != noErr) {
                NSLog(@"AudioQueueAllocateBuffer() error: %d", err);
                return;
            }
            
            int sampleCount = _mAudioQueueBuf->mAudioDataBytesCapacity / sizeof (SInt16);
            _mAudioQueueBuf->mAudioDataByteSize = sampleCount * sizeof (SInt16);
            SInt16 *rawBuf = _mAudioQueueBuf->mAudioData;
            handle_error(gme_play(_mEmu, sampleCount, rawBuf));
            err = AudioQueueEnqueueBuffer(_mAudioQueue, _mAudioQueueBuf, 0, nil);
            if (err != noErr) {
                NSLog(@"AudioQueueEnqueueBuffer() error: %d", err);
            }
        }
        _mIsPlaying = YES;
        err = AudioQueueStart(_mAudioQueue, nil);
        if (err != noErr) {
            NSLog(@"AudioQueueStart() error: %d", err);
            _mIsPlaying = NO;
            return;
        }
    } else {
        if (_mIsPaused == YES) {
            _mIsPaused = NO;
            OSStatus err = AudioQueueStart(_mAudioQueue, nil);
            if (err != noErr) { NSLog(@"AudioQueueStart() error: %d", err); _mIsPlaying = NO; return; }
        } else {
            NSLog(@"Error: audio is already playing back.");
        }
    }
}

- (void)setupFormat {
    _mStreamFormat.mSampleRate       = kSampleRate;
    _mStreamFormat.mFormatID         = kAudioFormatLinearPCM;
    _mStreamFormat.mFormatFlags      = kLinearPCMFormatFlagIsSignedInteger;
    _mStreamFormat.mFramesPerPacket  = 1;
    _mStreamFormat.mChannelsPerFrame = 2;
    _mStreamFormat.mBitsPerChannel   = 16;
    _mStreamFormat.mBytesPerFrame    = (_mStreamFormat.mBitsPerChannel / 8) * _mStreamFormat.mChannelsPerFrame;
    _mStreamFormat.mBytesPerPacket   = _mStreamFormat.mBytesPerFrame;
}

void AudioEngineOutputBufferCallback(void * inUserData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer) {
    AudioEngine *engine = (__bridge AudioEngine *) inUserData;
    [engine processOutputBuffer:inBuffer queue: inAQ];
}

- (void)processOutputBuffer:(AudioQueueBufferRef)buffer queue:(AudioQueueRef)queue {
    OSStatus err;
    if (_mIsPlaying == YES && _mEmu != NULL) {
        SInt16 *rawBuf = buffer->mAudioData;
        int sampleCount = buffer->mAudioDataBytesCapacity / sizeof (SInt16);
        handle_error(gme_play(_mEmu, sampleCount, rawBuf));
        buffer->mAudioDataByteSize = sampleCount * sizeof (SInt16);

        err = AudioQueueEnqueueBuffer(queue, buffer, 0, NULL);
        if (err == kAudioSessionNotActiveError || err == kAudioQueueErr_EnqueueDuringReset) {
            _mIsPlaying = NO;
        } else if (err != noErr) {
            NSLog(@"AudioQueueEnqueueBuffer() error %d", err);
        }
    } else {
        err = AudioQueueStop(queue, NO);
        if (err != noErr) NSLog(@"AudioQueueStop() error: %d", err);
    }
}

- (void)dealloc {
    if (_mEmu) {
        gme_delete(_mEmu);
        _mEmu = NULL;
    }
}

static void handle_error(const char* str) {
    if (str) {
        NSLog(@"%@", [[NSString alloc] initWithUTF8String:str]);
    }
}
@end
