//
//  SidTuneWrapper.mm
//  Square Waves
//
//  Created by Alex Busman on 4/24/20.
//  Copyright © 2020 Alex Busman. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SidTuneWrapper.h"

#include "../../libsidplay/sidplayfp/SidTune.h"

@interface SidTuneWrapper()

@property (atomic, readwrite) SidTune *mSidTune;

@end

@implementation SidTuneWrapper

- (id)initWithFilename:(NSString *)fileName {
    self = [super init];
    
    _mSidTune = new SidTune([fileName cStringUsingEncoding:kCFStringEncodingUTF8]);
    return self;
}

- (void)load:(NSString *)fileName {
    _mSidTune->load([fileName cStringUsingEncoding:kCFStringEncodingUTF8]);
}

- (void)read:(UInt8 *)sourceBuffer bufferLen:(UInt32)bufferLen {
    _mSidTune->read(sourceBuffer, bufferLen);
}

- (unsigned int)selectSong:(unsigned int)songNum {
    return _mSidTune->selectSong(songNum);
}

- (const SidTuneInfo *)getInfo {
    return _mSidTune->getInfo();
}

- (const SidTuneInfo *)getInfoWithSongnum:(unsigned int)songNum {
    return _mSidTune->getInfo(songNum);
}

- (BOOL)getStatus {
    return _mSidTune->getStatus() ? YES : NO;
}

- (NSString *)statusString {
    return [NSString stringWithUTF8String:_mSidTune->statusString()];
}
@end
