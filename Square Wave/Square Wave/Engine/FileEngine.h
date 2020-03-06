//
//  FileEngine.h
//  Square Wave
//
//  Created by Alex Busman on 5/8/18.
//  Copyright © 2018 Alex Busman. All rights reserved.
//

#define __DEBUG_FILE_ENGINE

#if defined(__DEBUG_FILE_ENGINE)
#define __DEBUG_FE(m, ...) NSLog((m), __VA_ARGS__)
#else
#define __DEBUG_FE(m, ...)
#endif

@class AppDelegate;
@class Track;
@class Game;
@class System;
@class Song;
@class Artist;

@protocol FileEngineDelegate
- (void)progress:(NSUInteger)currentIndex total:(NSUInteger)total;
- (void)complete;
- (void)failed:(NSError *_Nonnull)error;
@end

@interface FileEngine : NSObject
+ (void) reloadFromCloudWith:(id<FileEngineDelegate>_Nonnull)delegate;
+ (BOOL) addFile:(nonnull NSURL *)url removeOriginal:(BOOL)removeOriginal;
+ (void) refreshDatabase;
+ (NSString *_Nonnull)getMusicDirectory;
+ (BOOL) clearAll;
+ (BOOL) clearDatabase;
@end
