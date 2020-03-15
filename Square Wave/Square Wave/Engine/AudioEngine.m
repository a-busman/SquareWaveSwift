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
#import "EmulatorBackend/EmulatorBackend.h"
#import "EmulatorBackend/Gme.h"
#import "EmulatorBackend/Sid.h"

#import "AudioEngine.h"

@interface AudioEngine()
@property AudioStreamBasicDescription mStreamFormat;
@property Boolean                     mIsPlaying;
@property Boolean                     mIsPaused;
@property NSString *                  mFileName;

@property AudioQueueRef       mAudioQueue;
@property AudioQueueBufferRef mAudioQueueBuf;
@property int                 mTrack;
@property int                 mVoiceMask;

@property (strong, nonatomic, retain) EmulatorBackend * mBackend;

@end

@implementation AudioEngine

const int kSampleRate = 44100;
const int kBufferSize = 8000;
const int kBufferCount = 3;

// MARK: - Initialization
/**
 * sharedInstance
 * @brief Returns a single instance of an Audio Engine
 * @return A static instance of an Audio Engine
 */
+ (AudioEngine *)sharedInstance {
    static AudioEngine *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[AudioEngine alloc] init];
    });
    return sharedInstance;
}

/**
 * init
 * @brief Initializes a new Audio Engine
 * @return A new Audio Engine object
 */
- (id)init {
    if (!(self = [super init])) return nil;

    NSLog(@"reinit");
    [self setupFormat];
    OSStatus err = AudioQueueNewOutput(&_mStreamFormat, AudioEngineOutputBufferCallback, (__bridge void * _Nullable)(self), nil, nil, 0, &_mAudioQueue);
    if (err != noErr) {
        NSLog(@"AudioQueueNewOutput() error: %d", err);
        return nil;
    }
    return self;
}

/**
 * dealloc
 * @brief Cleans up Audio Engine object
 */
- (void)dealloc {
    NSLog(@"Deallocating");
}

/**
 * setFileName
 * @brief Creates a new emulator based on the given filename
 * @param [in]fileName Name of file to open
 */
- (void)setFileName:(NSString *)fileName {
    @synchronized (self) {
        _mFileName = fileName;

        if ([Gme isFileCompatible:fileName]) {
            if (_mBackend != nil) {
                
            }
            _mBackend = [[Gme alloc] init:kSampleRate];
            [_mBackend openFile:fileName];
        }
    }
}

/**
 * setTrack
 * @brief Sets the current active track in the file
 * @param track Track number to activate
 */
- (void)setTrack:(int)track {
    @synchronized (self) {
        _mTrack = track;
        int count = [_mBackend getTrackCount];
        if (_mTrack > count - 1) {
            _mTrack = count - 1;
        }
        [_mBackend startTrack:_mTrack];
    }
}

// MARK: - Playback
/**
 * play
 * @brief Starts current audio track and starts the audio queue
 */
- (void)play {
    @synchronized (self) {
        if (!_mFileName) {
            NSLog(@"No file name to play");
            return;
        }
        if (_mIsPaused == NO) {
            [_mBackend startTrack:_mTrack];
            [self setupFormat];
        }
    }
    AVAudioSession *session = AVAudioSession.sharedInstance;
    [session setActive:YES error:nil];
    [self startAudioQueue];
}

/**
 * pause
 * @brief Pauses current audio queue
 */
- (void)pause {
    AudioQueuePause(_mAudioQueue);
    AVAudioSession *session = AVAudioSession.sharedInstance;
    [session setActive:NO error:nil];
    @synchronized (self) {
        _mIsPaused = YES;
    }
}

/**
 * stop
 * @brief Stops current audio queue
 */
- (void)stop {
    @synchronized (self) {
        _mIsPlaying = NO;
        _mIsPaused = NO;
    }
    AudioQueueStop(_mAudioQueue, YES);
    AVAudioSession *session = AVAudioSession.sharedInstance;
    [session setActive:NO error:nil];

}

/**
 * nextTrack
 * @brief Skips to the next track in the current file
 */
- (void)nextTrack {
    @synchronized (self) {
        int count = [_mBackend getTrackCount];
        _mTrack++;
        if (_mTrack > count - 1) {
            _mTrack--;
        } else {
            [_mBackend startTrack:_mTrack];
        }
    }
}

/**
 * prevTrack
 * @brief Skips to the previous track in the current file
 */
- (void)prevTrack {
    @synchronized (self) {
        _mTrack--;
        if (_mTrack < 0) {
            _mTrack++;
        } else {
            [_mBackend startTrack:_mTrack];
        }
    }
}

/**
 * setMuteVoices
 * @brief Sets the mask for muting voices of the current track
 * @param mask Voice mask
 */
- (void)setMuteVoices:(int)mask {
    @synchronized (self) {
        _mVoiceMask = mask;
        [_mBackend muteVoices:mask];
    }
}

/**
 * getVoiceCount
 * @brief Gets the count of voices of the current track
 * @return Voice count
 */
- (int)getVoiceCount {
    @synchronized (self) {
        return [_mBackend getVoiceCount];
    }
}

/**
 * getVoiceName
 * @brief Gets the name of a given voice for the current track
 * @param index Index of the voice to get
 * @return Voice name
 */
- (NSString *)getVoiceName:(int)index {
    @synchronized (self) {
        return [_mBackend getVoiceName:index];
    }
}

// MARK: - Track Properties
/**
 * getTrackEnded
 * @brief Checks to see if the current track has ended
 * @return NO for not ended, YES for ended
 */
- (BOOL)getTrackEnded {
    @synchronized (self) {
        return [_mBackend getTrackEnded];
    }
}

/**
 * setFadeTime
 * @brief Sets the time to fade out the current track
 * @param msec Time to fade out in milliseconds
 */
- (void)setFadeTime:(int)msec {
    @synchronized (self) {
        [_mBackend setFade:msec];
    }
}

/**
 * setTempo
 * @brief Sets the playback rate of the current track
 * @param tempo Playback rate to set as a multiplier
 */
- (void)setTempo:(double)tempo {
    @synchronized (self) {
        [_mBackend setTempo:tempo];
    }
}

/**
 * resetFadeTime
 * @brief Removes fade out of current track
 */
- (void)resetFadeTime {
    @synchronized (self) {
        [_mBackend resetFade];
    }
}

/**
 * getElapsedTime
 * @brief Gets the current elapsed time of the current track in milliseconds
 * @return Elapsed time in milliseconds
 */
- (int)getElapsedTime {
    @synchronized (self) {
        return [_mBackend tell];
    }
}

- (void)ignoreSilence {
    @synchronized (self) {
        if (_mEmu) {
            gme_ignore_silence(_mEmu, 1);
        }
    }
}

// MARK: - Audio Management
/**
 * startAudioQueue
 * @brief Starts the current audio queue
 */
- (void)startAudioQueue {
    @synchronized (self) {
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
                [_mBackend play:sampleCount buffer:rawBuf];
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
}

/**
 * setupFormat
 * @brief Sets up the stream format needed for an AudioQueue
 */
- (void)setupFormat {
    @synchronized (self) {
        _mStreamFormat.mSampleRate       = kSampleRate;
        _mStreamFormat.mFormatID         = kAudioFormatLinearPCM;
        _mStreamFormat.mFormatFlags      = kLinearPCMFormatFlagIsSignedInteger;
        _mStreamFormat.mFramesPerPacket  = 1;
        _mStreamFormat.mChannelsPerFrame = 2;
        _mStreamFormat.mBitsPerChannel   = 16;
        _mStreamFormat.mBytesPerFrame    = (_mStreamFormat.mBitsPerChannel / 8) * _mStreamFormat.mChannelsPerFrame;
        _mStreamFormat.mBytesPerPacket   = _mStreamFormat.mBytesPerFrame;
    }
}

/**
 * AudioEngineOutputBufferCallback
 * @brief callback for when a buffer becomes free in an AudioQueue
 * @param inUserData Audio Engine instance
 * @param inAQ Current queue
 * @param inBuffer Current buffer to fill
 */
void AudioEngineOutputBufferCallback(void * inUserData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer) {
    AudioEngine *engine = (__bridge AudioEngine *) inUserData;
    [engine processOutputBuffer:inBuffer queue: inAQ];
}

/**
 * processOutputBuffer
 * @brief Fills Audio Queue buffer by playing enough samples to fill it, then enqueues the buffer.
 * @param buffer AudioQueue buffer to fill
 * @param queue AudioQueue to enqueue buffer in
 */
- (void)processOutputBuffer:(AudioQueueBufferRef)buffer queue:(AudioQueueRef)queue {
    @synchronized (self) {
        OSStatus err;
        if (_mIsPlaying == YES && _mBackend != nil) {
            SInt16 *rawBuf = buffer->mAudioData;
            int sampleCount = buffer->mAudioDataBytesCapacity / sizeof (SInt16);
            [_mBackend play:sampleCount buffer:rawBuf];

            buffer->mAudioDataByteSize = sampleCount * sizeof (SInt16);

            err = AudioQueueEnqueueBuffer(queue, buffer, 0, nil);
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
}

@end
