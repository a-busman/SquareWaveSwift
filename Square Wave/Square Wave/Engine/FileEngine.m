//
//  FileEngine.m
//  Square Wave
//
//  Created by Alex Busman on 5/8/18.
//  Copyright © 2018 Alex Busman. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "SSZipArchive.h"
#import "UnrarKit.h"
#import "LzmaSDKObjC.h"
#include "gme/gme.h"
#include <CommonCrypto/CommonDigest.h>
#import "Square_Waves-Swift.h"
#import "FileEngine.h"

@implementation FileEngine

const NSString * kZipFolder          = @"Zip";
const NSString * kRarFolder          = @"Rar";
const NSString * k7ZipFolder         = @"7Zip";
const NSString * kMSXFolder          = @"MSX";
const NSString * kNESFolder          = @"NES";
const NSString * kSNESFolder         = @"SNES";
const NSString * kAtariFolder        = @"Atari";
const NSString * kGenesisFolder      = @"Genesis";
const NSString * kGameBoyFolder      = @"GameBoy";
const NSString * kSpectrumFolder     = @"Spectrum";
const NSString * kTurboGrafxFolder   = @"TurboGrafx";
const NSString * kMasterSystemFolder = @"MasterSystem";
const NSString * kC64Folder          = @"C64";

const NSString * const kSupportedFileTypes[] = {
    // Archives
    @"zip", @"7z", @"rar",
    // GME
    @"nsf", @"ay", @"gbs", @"gym", @"hes", @"kss", @"sap", @"spc", @"vgm",
    // SID
    @"sid", @"c64", @"prg", @"p00", @"mus" };

const NSString * kAddToThisFolder = @"Add music files here";

typedef enum {
    ZIP,
    SEVEN_ZIP,
    RAR,
    NSF,
    AY,
    GBS,
    GYM,
    HES,
    KSS,
    SAP,
    SPC,
    VGM,
    SID,
    C64,
    PRG,
    P00,
    MUS
} FILE_TYPE;

/**
 * getContainerUrl
 * @brief Gets the url for the default ubiquity container ID
 * @param [in]manager File manager instance to use
 * @return If a container URL exists, and the directory also exists, the container's URL, else nil
 */
+ (NSURL *)getContainerUrl:(NSFileManager *)manager {
    NSURL *containerUrl = [manager URLForUbiquityContainerIdentifier:nil];
    
    if (containerUrl != nil) {
        NSURL *documentsDir = [containerUrl URLByAppendingPathComponent:@"Documents"];
        // Check if we have to create the default directory for our ubiquity container
        if (![manager fileExistsAtPath:[documentsDir path]]) {
            NSError *err = nil;
            [manager createDirectoryAtURL:documentsDir withIntermediateDirectories:YES attributes:nil error:&err];
            
            if (err != nil) {
                NSLog(@"Error creating cloud container directory: %@", [err localizedDescription]);
                containerUrl = nil;
            }
        } else {
            /*NSError *err = nil;
            [manager removeItemAtURL:documentsDir error:&err];
            if (err != nil) {
                NSLog(@"Error removing container url: %@", [err localizedDescription]);
            }*/
        }
        if (![manager fileExistsAtPath:[[documentsDir URLByAppendingPathComponent:kAddToThisFolder] path]]) {
            [manager createFileAtPath:[[documentsDir URLByAppendingPathComponent:kAddToThisFolder] path] contents:nil attributes:nil];
        }
    }
    return containerUrl;
}

/**
 * addUbiquitousItemAt
 * @brief adds an ubiquitous item to the database and file structure at a given url
 * @param [in]url The URL of the ubiquitous item to add
 */
+ (BOOL) addUbiquitousItemAt:(NSURL *) url {
    NSFileManager *manager = [NSFileManager defaultManager];
    NSString *filePath = @"";
    BOOL isDownloaded = YES;
    BOOL isSecured = [url startAccessingSecurityScopedResource];
    BOOL ret = NO;
    
    if ([[url pathExtension] isEqualToString:@"icloud"]) {
        // Remove trailing ".icloud"
        filePath = [[url URLByDeletingPathExtension] lastPathComponent];
        // Remove leading '.'
        filePath = [filePath substringFromIndex:1];
        isDownloaded = NO;
    } else {
        filePath = [url lastPathComponent];
    }
    NSURL *finalUrl = [[url URLByDeletingLastPathComponent] URLByAppendingPathComponent:filePath];
    if (!isDownloaded) {
        NSError *err = nil;
        [manager startDownloadingUbiquitousItemAtURL:url error:&err];
        if (err != nil) {
            NSLog(@"Could not start downloading: %@", [err localizedDescription]);
            return NO;
        }
        
        // Wait for download to complete by checking if file is present.
        for (int i = 0; i < 10; i++) {
            if ([manager fileExistsAtPath:finalUrl.path]) {
                isDownloaded = YES;
                break;
            }
            [NSThread sleepForTimeInterval:1];
        }
        if (isDownloaded) {
            NSLog(@"Download success!");
        } else {
            NSLog(@"Download failed!");
        }
    }
    if (isDownloaded) {
        ret = [FileEngine addFile:finalUrl removeOriginal:NO];
    }
    if (isSecured) {
        [url stopAccessingSecurityScopedResource];
    }
    return ret;
}

/**
 * reloadFromCloudWith
 * @brief Adds all new files in cloud container
 * @param delegate Delegate to update with progress and completion status.
 */
+ (void)reloadFromCloudWith:(id<FileEngineDelegate>)delegate {
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
        NSFileManager *defaultManager = [NSFileManager defaultManager];
        NSURL *containerUrl = [FileEngine getContainerUrl:defaultManager];
        
        if (containerUrl == nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [delegate failed:[NSError errorWithDomain:@"SquareWaveError" code:-1 userInfo:@{NSLocalizedDescriptionKey : @"Container URL could not be determined"}]];
            });
            return;
        }
        NSError *err = nil;
        NSArray *contents = [defaultManager contentsOfDirectoryAtURL:[containerUrl URLByAppendingPathComponent:@"Documents"] includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsPackageDescendants error:&err];
        NSUInteger index = 0;
        const NSUInteger total = [contents count];
        BOOL success = NO;
        for (NSURL *url in contents) {
            if ([defaultManager isUbiquitousItemAtURL:url]) {
                if ([FileEngine addUbiquitousItemAt:url]) {
                    success = YES;
                }
            } else {
                if ([FileEngine addFile:url removeOriginal:NO]) {
                    success = YES;
                }
            }
            index++;
            dispatch_sync(dispatch_get_main_queue(), ^{
                [delegate progress:index total:total];
                if (success) {
                    [AppDelegate updatePlaybackStateWithHasTracks:YES];
                }
            });
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [delegate complete];
        });
    });
}

/**
 * addFile
 * @brief Adds a file to the local container and database
 * @param [in]url URL to external file
 * @return NO for failure, YES for success
*/
+ (BOOL)addFile:(NSURL *)url removeOriginal:(BOOL)removeOriginal {
    // Determine file type
    NSFileManager *defaultManager = [NSFileManager defaultManager];
    NSString      *extension      = [[url pathExtension] lowercaseString];
    NSString      *filePath       = [url path];
    NSError       *error          = nil;
    
    BOOL isDirectory = NO;
    BOOL success     = NO;
    
    if (![defaultManager fileExistsAtPath:[FileEngine getMusicDirectory] isDirectory:&isDirectory]) {
        __DEBUG_FE(@"Creating %@", [FileEngine getMusicDirectory]);
        success = [defaultManager createDirectoryAtPath:[FileEngine getMusicDirectory] withIntermediateDirectories:NO attributes:nil error:&error];
        if (!success) {
            NSLog(@"Error creating directory %@: %@", [FileEngine getMusicDirectory], error);
            return NO;
        }
    }
    NSArray *supportedTypes = [NSArray arrayWithObjects:kSupportedFileTypes count:(sizeof(kSupportedFileTypes) / sizeof(id))];
    
    FILE_TYPE fType = [supportedTypes indexOfObject:extension];
    switch (fType) {
        case ZIP:
        {
            NSString *destination = [[FileEngine getMusicDirectory] stringByAppendingPathComponent:kZipFolder];
            
            if (![FileEngine prepareExtractionDirectory:destination]) {
                return NO;
            }
            
            // Unzip file to Zip directory
            __DEBUG_FE(@"Unzipping to %@", destination);
            success = [SSZipArchive unzipFileAtPath:filePath toDestination:destination overwrite:YES password:nil error:&error];
            if (!success) {
                NSLog(@"Error unzipping %@ to %@: %@", filePath, destination, error);
                return NO;
            }
            
            // Remove zip file
            if (removeOriginal) {
                __DEBUG_FE(@"Removing original file %@", filePath);
                success = [defaultManager removeItemAtPath:filePath error:&error];
                if (!success) {
                    NSLog(@"Error removing %@: %@", filePath, error);
                    return NO;
                }
            }
            [FileEngine moveExtractedFiles:destination];
        }
            break;
        case SEVEN_ZIP:
        {
            NSString *destination = [[FileEngine getMusicDirectory] stringByAppendingPathComponent:k7ZipFolder];
            
            if (![FileEngine prepareExtractionDirectory:destination]) {
                return NO;
            }
            LzmaSDKObjCReader *reader = [[LzmaSDKObjCReader alloc] initWithFileURL:[NSURL fileURLWithPath:filePath] andType:LzmaSDKObjCFileType7z];
            
            NSError * error = nil;
            __DEBUG_FE(@"Opening reader to %@", destination);
            if (![reader open:&error]) {
                NSLog(@"Open error: %@", error);
            }
            NSMutableArray * items = [NSMutableArray array];
            __DEBUG_FE(@"iterating through 7zip items at %@", destination);
            [reader iterateWithHandler:^BOOL(LzmaSDKObjCItem * item, NSError * error){
                NSLog(@"\n%@", item);
                if (item) [items addObject:item]; // If needed, store to array.
                return YES; // YES - continue iterate, NO - stop iteration
            }];
            __DEBUG_FE(@"Un7zipping to %@", destination);
            [reader extract:items toPath:destination withFullPaths:YES];
            if (reader.lastError) {
                NSLog(@"Extract error: %@", reader.lastError);
                return NO;
            }
            
            [FileEngine moveExtractedFiles:destination];
        }
            break;
        case RAR:
        {
            NSString *destination = [[FileEngine getMusicDirectory] stringByAppendingPathComponent:kRarFolder];
            
            if (![FileEngine prepareExtractionDirectory:destination]) {
                return NO;
            }
            
            NSError *archiveError = nil;
            URKArchive *archive = [[URKArchive alloc] initWithPath:filePath error:&archiveError];
            __DEBUG_FE(@"Unraring to %@", destination);
            success = [archive extractFilesTo:destination overwrite:YES error:&error];
            if (!success) {
                NSLog(@"Error unraring %@ to %@: %@", filePath, destination, error);
                return NO;
            }
            
            if (removeOriginal) {
                __DEBUG_FE(@"Removing original file %@", filePath);
                success = [defaultManager removeItemAtPath:filePath error:&error];
                if (!success) {
                    NSLog(@"Error removing %@: %@", filePath, error);
                    return NO;
                }
            }
            
            [FileEngine moveExtractedFiles:destination];
        }
            break;
        case NSF:
        case AY:
        case GBS:
        case GYM:
        case HES:
        case KSS:
        case SAP:
        case SPC:
        case VGM:
        case SID:
        case C64:
        case PRG:
        case P00:
        case MUS:
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSError *err = nil;
                if (![FileEngine checkAndParseFileContents:url.path m3uPath:nil]) {
                    NSLog(@"Removing %@", url.path);
                    [defaultManager removeItemAtPath:url.path error:&err];
                }
            });
        }
            break;
        default:
            NSLog(@"Unsupported file type %@", extension);
            break;
    }
    if (removeOriginal) {
        [AppDelegate updatePlaybackStateWithHasTracks:YES];
    }
    return YES;
}

+ (void)moveExtractedFiles:(NSString *)path {
    NSFileManager *defaultManager = [NSFileManager defaultManager];
    NSDirectoryEnumerator *enumerator = [defaultManager enumeratorAtPath:path];
    NSString              *file       = nil;
    NSArray               *fileList   = [defaultManager contentsOfDirectoryAtPath:path error:nil];
    NSString              *m3uPath    = nil;
    for (file in fileList) {
        if ([[file pathExtension] isEqualToString:@"m3u"]) {
            // Don't support multiple m3us
            if (m3uPath != nil) {
                m3uPath = nil;
                break;
            }
            m3uPath = [path stringByAppendingPathComponent:file];
        }
    }
    while (file = [enumerator nextObject]) {
        if ([[file pathExtension] isEqualToString:@"m3u"]) {
            continue;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            NSError *err = nil;
            if (![FileEngine checkAndParseFileContents:[path stringByAppendingPathComponent:file] m3uPath:m3uPath]) {
                NSLog(@"Removing %@", [path stringByAppendingPathComponent:file]);
                [defaultManager removeItemAtPath:[path stringByAppendingPathComponent:file] error:&err];
            }
        });
    }
}

+ (BOOL)prepareExtractionDirectory:(NSString *)path {
    NSFileManager *defaultManager = [NSFileManager defaultManager];
    NSError *error = nil;
    BOOL success = NO;
    
    if (![defaultManager fileExistsAtPath:path isDirectory:nil]) {
        __DEBUG_FE(@"Creating %@", path);
        success = [defaultManager createDirectoryAtPath:path withIntermediateDirectories:NO attributes:nil error:&error];
        if (!success) {
            NSLog(@"Error creating directory %@: %@", path, error);
            return NO;
        }
    } else {
        // Remove everything from directory if it already exists
        NSDirectoryEnumerator *enumerator = [defaultManager enumeratorAtPath:path];
        NSString              *file       = nil;

        while (file = [enumerator nextObject]) {
            __DEBUG_FE(@"Removing %@", file);
            success = [defaultManager removeItemAtPath:[path stringByAppendingPathComponent:file] error:&error];
            if (!success) {
                NSLog(@"Error removing %@: %@", file, error);
                return NO;
            }
        }
    }
    return YES;
}

+ (BOOL)checkAndParseFileContents:(NSString *)path m3uPath:(NSString *)m3uPath {
    AppDelegate            *delegate      = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *objectContext = delegate.persistentContainer.viewContext;
    NSFetchRequest         *request       = [NSFetchRequest fetchRequestWithEntityName:@"File"];
    NSError                *error         = nil;

    NSString *checksum = [FileEngine getFileChecksum:path];
    if (checksum != nil) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"checksum == %@", checksum];
        
        [request setPredicate:predicate];
        NSArray *objects = [objectContext executeFetchRequest:request error:&error];
        if ((error == nil) && ([objects count] == 0)) {
            File *newFile = [[File alloc] initWithContext:objectContext];
            [newFile setExt:[path pathExtension]];
            [newFile setChecksum:checksum];
            [newFile setFilename:path];
            [FileEngine parseAudioFileContents:newFile m3uPath:m3uPath];
        } else {
            NSLog(@"File: %@ already imported.", path);
            return NO;
        }
    } else {
        return NO;
    }
    return YES;
}

+ (NSString *)getFileChecksum:(NSString *)path {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    // Make sure the file exists
    if([fileManager fileExistsAtPath:path isDirectory:nil]) {
        NSData *data = [NSData dataWithContentsOfFile:path];
        unsigned char digest[CC_MD5_DIGEST_LENGTH] = {0};

        CC_MD5(data.bytes, (CC_LONG)data.length, digest);

        NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];

        for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
            [output appendFormat:@"%02x", digest[i]];
        }
        return output;
    } else {
        return nil;
    }
}

/**
 * getMusicDirectory
 * @brief Get the current music directory in the container
 * @return Absolute path of music directory
*/
+ (NSString *)getMusicDirectory {
    NSArray  *paths              = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];

    return [documentsDirectory stringByAppendingPathComponent:@"Music"];
}

/**
 * parseAudioFileContents
 * @brief Given a file path, determine which folder it should be placed in, place it there,
 *        and add its contents to the database.
 * @param [in]fileObject Preformed file object.
 * @return NO for failure, YES for success
 */
+ (BOOL)parseAudioFileContents:(File *)fileObject m3uPath:(NSString *)m3uPath {
    BOOL success     = false;
    BOOL isDirectory = false;
    
    NSError *error = nil;
    
    NSString *filePath = [fileObject filename];
    
    const NSString *consoleFolder = nil;
    NSString       *consolePath   = nil;
    NSString       *gameFolder    = nil;
    NSString       *gamePath      = nil;
    NSString       *finalPath     = nil;
    
    gme_type_t  gameType = NULL;
    gme_info_t *gameInfo = NULL;
    Music_Emu  *emu      = NULL;
    
    NSFileManager *defaultManager = [NSFileManager defaultManager];
    NSLog(@"Attempting to open %@", filePath);
    handle_error(gme_identify_file([filePath UTF8String], &gameType));
    handle_error(gme_open_file([filePath UTF8String], &emu, gme_info_only));
    
    if (emu == nil) {
        return NO;
    }
    
    if (m3uPath != nil) {
        handle_error(gme_load_m3u(emu, [m3uPath UTF8String]));
    }
    
    handle_error(gme_track_info(emu, &gameInfo, 0));
    
    if (gameInfo == nil) {
        return NO;
    }
    
    if (gameType == gme_ay_type) {
        // ZX Spectrum
        consoleFolder = kSpectrumFolder;
    } else if (gameType == gme_gbs_type) {
        // Game Boy
        consoleFolder = kGameBoyFolder;
    } else if (gameType == gme_gym_type) {
        // Genesis
        consoleFolder = kGenesisFolder;
    } else if (gameType == gme_hes_type) {
        // PC Engine/TurboGrafx-16
        consoleFolder = kTurboGrafxFolder;
    } else if (gameType == gme_kss_type) {
        // MSX
        consoleFolder = kMSXFolder;
    } else if (gameType == gme_nsf_type) {
        // NES
        consoleFolder = kNESFolder;
    } else if (gameType == gme_nsfe_type) {
        // NES Extended
        consoleFolder = kNESFolder;
    } else if (gameType == gme_sap_type) {
        // Atari XL
        consoleFolder = kAtariFolder;
    } else if (gameType == gme_spc_type) {
        // SNES
        consoleFolder = kSNESFolder;
    } else if (gameType == gme_vgm_type || gameType == gme_vgz_type) {
        // Master system / Genesis
        if (strncmp(gameInfo->system, "Sega Genesis", 256) == 0) {
            consoleFolder = kGenesisFolder;
        } else {
            consoleFolder = kMasterSystemFolder;
        }
    } else {
        NSLog(@"Invalid game type: %@", gameType);
        return NO;
    }
    
    consolePath = [[FileEngine getMusicDirectory] stringByAppendingPathComponent:consoleFolder];
    // If console folder doesn't exist, create it
    success = [defaultManager fileExistsAtPath:consolePath isDirectory:&isDirectory];
    
    if (!success) {
        __DEBUG_FE(@"Creating directory %@", consolePath);
        success = [defaultManager createDirectoryAtPath:consolePath withIntermediateDirectories:NO attributes:nil error:&error];
        if (!success) {
            NSLog(@"Could not create directory %@: %@", consolePath, error);
            return NO;
        }
    } else if (!isDirectory) {
        __DEBUG_FE(@"Removing file %@", consolePath);
        success = [defaultManager removeItemAtPath:consolePath error:&error];
        if (!success) {
            NSLog(@"Could not remove %@: %@", consolePath, error);
            return NO;
        }
        __DEBUG_FE(@"Creating directory %@", consolePath);
        success = [defaultManager createDirectoryAtPath:consolePath withIntermediateDirectories:NO attributes:nil error:&error];
        if (!success) {
            NSLog(@"Could not create directory %@: %@", consolePath, error);
            return NO;
        }
    }
    
    // If game folder doesn't exist, create it
    gameFolder = strlen(gameInfo->game) > 0 ? [NSString stringWithUTF8String:gameInfo->game] : [[[fileObject filename] lastPathComponent] stringByDeletingPathExtension];
    gamePath   = [consolePath stringByAppendingPathComponent:gameFolder];
    
    success = [defaultManager fileExistsAtPath:gamePath isDirectory:&isDirectory];
    
    if (!success) {
        __DEBUG_FE(@"Creating directory %@", gamePath);
        success = [defaultManager createDirectoryAtPath:gamePath withIntermediateDirectories:NO attributes:nil error:&error];
        if (!success) {
            NSLog(@"Could not create directory %@: %@", gamePath, error);
            return NO;
        }
    } else if (!isDirectory) {
        __DEBUG_FE(@"Removing file %@", gamePath);
        success = [defaultManager removeItemAtPath:gamePath error:&error];
        if (!success) {
            NSLog(@"Could not remove %@: %@", gamePath, error);
            return NO;
        }
        __DEBUG_FE(@"Creating directory %@", gamePath);
        success = [defaultManager createDirectoryAtPath:gamePath withIntermediateDirectories:NO attributes:nil error:&error];
        if (!success) {
            NSLog(@"Could not create directory %@: %@", gamePath, error);
            return NO;
        }
    }
    
    // Move file to new destination
    finalPath = [gamePath stringByAppendingPathComponent:[filePath lastPathComponent]];
    __DEBUG_FE(@"Moving %@ to %@", filePath, finalPath);
    success = [defaultManager moveItemAtPath:filePath toPath:finalPath error:&error];
    if (!success) {
        NSLog(@"Failed to move %@ to %@: %@", filePath, finalPath, error);
        return NO;
    }
    
    // Add all tracks found in file to database
    [FileEngine addToDatabase:emu relativePath:[[consoleFolder stringByAppendingPathComponent:gameFolder] stringByAppendingPathComponent:[filePath lastPathComponent]] fileObject:fileObject];
    gme_delete(emu);
    return YES;
}
/**
 * refreshDatabase
 * @brief Clears database and readds all files
 */
+ (void)refreshDatabase {
    [FileEngine clearDatabase];
    // TODO: Implement
    // Traverse all files
    // Readd them one by one
}

/**
 * removeGame
 * @brief Removes a game and all its associated tracks from the database.
 * @param [in]game Game to remove
 * @return NO if any track failed to remove associated file. YES otherwise.
 */
+ (BOOL)removeGame:(Game *)game {
    BOOL ret = YES;
    
    NSOrderedSet *tracks = [[game tracks] copy] ;
    
    for (int i = 0; i < [tracks count]; i++) {
        if (![FileEngine removeTrack:tracks[i]]) {
            ret = NO;
        }
    }
    
    NSString *folder = [[FileEngine getMusicDirectory] stringByAppendingPathComponent:[game folder]];
    if ([[NSFileManager defaultManager] isDeletableFileAtPath:folder]) {
        NSError *error = nil;
        [[NSFileManager defaultManager] removeItemAtPath:folder error:&error];
        if (error != nil) {
            NSLog(@"Failed to remove folder: %@", folder);
            ret = NO;
        }
    }
    return ret;
}

/**
 * removeTrack
 * @brief Removes a track from the database
 * @note If it is the last track in a file, it removes the file. If last track in game, artist, or system, it removes these as well.
 * @param [in]track Track to remove from database
 * @return NO if failed to remove file. YES otherwise
 */
+ (BOOL)removeTrack:(Track *)track {
    BOOL ret = YES;
    
    AppDelegate *delegate = (AppDelegate *)UIApplication.sharedApplication.delegate;
    
    NSManagedObjectContext *context = [[delegate persistentContainer] viewContext];
    
    File     *file      = [track file];
    Game     *game      = [track game];
    System   *platform  = [track system];
    Artist   *artist    = [track artist];
    NSString *filePath  = [[FileEngine getMusicDirectory] stringByAppendingPathComponent:[file filename]];
    NSError  *error     = nil;
    
    [AppDelegate removeTrackFromTracklist: track];

    if (track != nil) {
        [context deleteObject:track];
    }
    
    if ((game != nil) && ([[game tracks] count] <= 1)) {
        [context deleteObject:game];
    }
    
    if ((platform != nil) && ([[platform tracks] count] <= 1)) {
        [context deleteObject:platform];
    }
    
    if ((artist != nil) && ([[artist tracks] count] <= 1)) {
        [context deleteObject:artist];
    }
    if ((file != nil) && ([[file tracks] count] <= 1) && ([[NSFileManager defaultManager] isDeletableFileAtPath:filePath])) {
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
        if (error != nil) {
            NSLog(@"Failed to remove %@: %@", filePath, [error localizedDescription]);
            ret = NO;
        }
        [context deleteObject:file];
    }

    [context save:&error];
    return ret;
}

/**
 * clearAll
 * @brief Clears database and deletes all local files
 * @return NO for failure, YES for success
 */
+ (BOOL)clearAll {
    BOOL ret = YES;

    if (![FileEngine clearDatabase]) {
        ret = NO;
    }
    [AppDelegate updatePlaybackStateWithHasTracks:NO];
    if (![FileEngine clearFiles]) {
        ret = NO;
    }
    return ret;
}

/**
 * clearFiles
 * @brief Deletes all local files
 * @return NO for failure, YES for success
 */
+ (BOOL)clearFiles {
    NSError *error      = nil;
    BOOL    isDirectory = NO;

    NSString      *directory      = [FileEngine getMusicDirectory];
    NSFileManager *defaultManager = [NSFileManager defaultManager];

    if (![defaultManager fileExistsAtPath:directory isDirectory:&isDirectory]) {
        NSLog(@"Music directory does not exist");
        return NO;
    }
    if (![defaultManager isDeletableFileAtPath:directory])
    {
        NSLog(@"Music directory not deletable");
        return NO;
    }

    if (![defaultManager removeItemAtPath:directory error:&error]) {
        NSLog(@"Failed to delete Music directory. Error: %@", error);
        return NO;
    }
    return YES;
}

/**
 * clearDatabase
 * @brief Clears database
 * @return NO for failure, YES for success
 */
+ (BOOL)clearDatabase {
    __block BOOL ret = YES;

    AppDelegate            *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context  = [[delegate persistentContainer] viewContext];

    [context performBlockAndWait:^{
        NSError *err = nil;
        [context reset];
        for (NSEntityDescription *entity in [[delegate persistentContainer] managedObjectModel]) {
            if (![FileEngine deleteEntity:[entity name]]) {
                ret = NO;
            }
        }
        [context save:&err];
        if (err != nil) {
            NSLog(@"Failed to save context: %@", [err localizedDescription]);
        }
    }];
    [delegate saveContext];
    return ret;
}

/**
 * deleteEntity
 * @brief Deletes all records of a given entity
 * @param [in]entity Entity to delete
 * @return NO for failure, YES for success
 */
+ (BOOL)deleteEntity:(NSString *)entity {
    NSError *error = nil;
    
    AppDelegate          *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSFetchRequest       *request  = [NSFetchRequest fetchRequestWithEntityName:entity];
    NSBatchDeleteRequest *delete   = [[NSBatchDeleteRequest alloc] initWithFetchRequest:request];

    [[[delegate persistentContainer] persistentStoreCoordinator] executeRequest:delete withContext:[[delegate persistentContainer] viewContext] error:&error];

    if (error != nil) {
        NSLog(@"Failed to delete entity: %@", entity);
        return NO;
    }
    return YES;
}

/**
 * addToDatabase
 * @brief Given a music emu and a file path, add the contents to the database
 * @param [in]emu Music emulator all ready to go
 * @param [in]relativePath Path of file to parse
 */
+ (void)addToDatabase:(Music_Emu *)emu relativePath:(NSString *)relativePath fileObject:(File *)fileObject {
    gme_info_t *gameInfo = nil;
    
    AppDelegate            *delegate          = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *objectContext     = delegate.persistentContainer.viewContext;
    NSEntityDescription    *entityDescription = [NSEntityDescription entityForName:@"Track" inManagedObjectContext:objectContext];
    NSFetchRequest         *request           = [[NSFetchRequest alloc] init];
    NSError                *error             = nil;
    [request setEntity:entityDescription];

    __DEBUG_FE(@"database location: %@", delegate.persistentContainer.persistentStoreCoordinator.persistentStores.firstObject.URL);
    [fileObject setFilename:relativePath];
    
    int trackCount = gme_track_count(emu);
    for (int i = 0; i < trackCount; i++) {
        gme_track_info(emu, &gameInfo, i);
        NSString *trackName  = strlen(gameInfo->song)   > 0 ? [NSString stringWithUTF8String:gameInfo->song]   : [NSString stringWithFormat:@"Track %d", i + 1];
        NSString *artistName = strlen(gameInfo->author) > 0 ? [NSString stringWithUTF8String:gameInfo->author] : @"No Artist";
        NSString *gameName   = strlen(gameInfo->game)   > 0 ? [NSString stringWithUTF8String:gameInfo->game]   : [[[fileObject filename] lastPathComponent] stringByDeletingPathExtension];
        NSString *systemName = strlen(gme_type_system(gme_type(emu))) > 0 ? [NSString stringWithUTF8String:gme_type_system(gme_type(emu))] : @"No System";
        int trackLength = gameInfo->length;
        int loopLength = gameInfo->loop_length;
        int introLength = gameInfo->intro_length;
        int trackNum = i;
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name == %@ AND artist.name == %@ AND game.name == %@ AND system.name == %@", trackName, artistName, gameName, systemName];
        [request setPredicate:predicate];
        NSArray *objects = [objectContext executeFetchRequest:request error:&error];
        __DEBUG_FE(@"Found %lu objects that matches predicate %@", [objects count], predicate);
        // Already in database, so no need to add another
        if ([objects count] > 0) {
            continue;
        } else if (error != nil) {
            NSLog(@"request error: %@", error);
        }
        
        Track *trackMO = [[Track alloc] initWithContext:objectContext];
        Artist *artistMO;
        Game *gameMO;
        System *systemMO;
        [trackMO setId:[NSUUID UUID]];
        [trackMO setName:trackName];
        [trackMO setFavourite:NO];
        [trackMO setTrackNum:trackNum >= 0 ? trackNum : i];
        [trackMO setUrl:relativePath];
        [trackMO setLength:trackLength];
        [trackMO setIntroLength:introLength];
        [trackMO setLoopLength:loopLength];
        [trackMO setFile:fileObject];
        
        // Look up other attributes, if they don't exist, create them.
        
        objects = [FileEngine getObjectsByName:artistName entity:@"Artist"];
        
        if (objects != nil && [objects count] > 0) {
            artistMO = (Artist *)[objects firstObject];
        } else {
            artistMO = [[Artist alloc] initWithContext:objectContext];
            [artistMO setId:[NSUUID UUID]];
            [artistMO setName:artistName];
        }
        
        [trackMO setArtist:artistMO];
        
        objects = [FileEngine getObjectsByName:[NSString stringWithUTF8String:gme_type_system(gme_type(emu))] entity:@"System"];
        
        if (objects != nil && [objects count] > 0) {
            systemMO = (System *)[objects firstObject];
        } else {
            systemMO = [[System alloc] initWithContext:objectContext];
            [systemMO setId:[NSUUID UUID]];
            [systemMO setName:systemName];
        }
        
        [trackMO setSystem:systemMO];
        
        objects = [FileEngine getObjectsByName:gameName entity:@"Game"];
        
        if (objects != nil && [objects count] > 0) {
            gameMO = (Game *)[objects firstObject];
        } else {
            gameMO = [[Game alloc] initWithContext:objectContext];
            [gameMO setId:[NSUUID UUID]];
            [gameMO setName:gameName];
            [gameMO setYear:strlen(gameInfo->copyright) > 0 ? [NSString stringWithUTF8String:gameInfo->copyright] : [NSString stringWithFormat:@"No Year"]];
            [gameMO setSystem:systemMO];
            [gameMO setFolder:[relativePath stringByDeletingLastPathComponent]];
        }
        
        [trackMO setGame:gameMO];

        [delegate saveContext];
    }
}

/**
 * getObjectsByName
 * @brief Gets an array of objects where the name field matches the given name, of a given entity
 * @param [in]name Name of object to get
 * @param [in]entity Entity of object to get
 * @return Array of objects matching the given criteria
*/
+ (NSArray *)getObjectsByName:(NSString *)name entity:(NSString *)entity {
    NSError *error = nil;
    NSArray *ret   = nil;

    NSManagedObjectContext *context   = [[(AppDelegate *)[[UIApplication sharedApplication] delegate] persistentContainer] viewContext];
    NSPredicate            *predicate = [NSPredicate predicateWithFormat:@"name == %@", name];
    NSFetchRequest         *request   = [NSFetchRequest fetchRequestWithEntityName:entity];

    [request setPredicate:predicate];
    
    ret = [context executeFetchRequest:request error:&error];
    
    if (error != nil) {
        ret = nil;
        NSLog(@"Error fetching %@ of type %@: %@", name, entity, error);
    }
    return ret;
}

static void handle_error(const char* str) {
    if (str) {
        NSLog(@"%s", str);
    }
}
@end
