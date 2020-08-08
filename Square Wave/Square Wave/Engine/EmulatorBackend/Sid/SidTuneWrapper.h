//
//  SidTuneWrapper.h
//  Square Waves
//
//  Created by Alex Busman on 4/24/20.
//  Copyright © 2020 Alex Busman. All rights reserved.
//

#ifndef SidTuneWrapper_h
#define SidTuneWrapper_h

#include "../../libsidplay/sidplayfp/SidTuneInfo.h"

@interface SidTuneWrapper : NSObject

- (id)initWithFilename:(NSString *)fileName;
- (void)load:(NSString *)fileName;
- (void)read:(UInt8 *)sourceBuffer bufferLen:(UInt32)bufferLen;
- (unsigned int)selectSong:(unsigned int)songNum;
- (const SidTuneInfo *)getInfo;
- (const SidTuneInfo *)getInfoWithSongnum:(unsigned int)songNum;
- (BOOL)getStatus;
- (NSString *)statusString;
@end

#endif /* SidTuneWrapper_h */
