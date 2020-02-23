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
#include "gme/gme.h"
#import "Square_Wave-Swift.h"
#import "FileEngine.h"

@implementation FileEngine

const NSString * kZipFolder          = @"Zip";
const NSString * kMSXFolder          = @"MSX";
const NSString * kNESFolder          = @"NES";
const NSString * kSNESFolder         = @"SNES";
const NSString * kAtariFolder        = @"Atari";
const NSString * kGenesisFolder      = @"Genesis";
const NSString * kGameBoyFolder      = @"GameBoy";
const NSString * kSpectrumFolder     = @"Spectrum";
const NSString * kTurboGrafxFolder   = @"TurboGrafx";
const NSString * kMasterSystemFolder = @"MasterSystem";

const NSString * const kSupportedFileTypes[] = { @"zip", @"nsf" };

typedef enum {
    ZIP,
    NSF
} FILE_TYPE;

/**
 * addFile
 * @brief Adds a file to the local container and database
 * @param [in]url URL to external file
 * @return NO for failure, YES for success
*/
+ (BOOL)addFile:(NSURL *)url {
    // Determine file type
    NSFileManager * defaultManager = [NSFileManager defaultManager];
    NSString * extension = [[url pathExtension] lowercaseString];
    NSString * filePath = [url path];
    NSError * error = nil;
    BOOL isDirectory = false;
    BOOL success = false;
    
    if (![defaultManager fileExistsAtPath:[FileEngine getMusicDirectory] isDirectory:&isDirectory]) {
        __DEBUG_FE(@"Creating %@", [FileEngine getMusicDirectory]);
        success = [defaultManager createDirectoryAtPath:[FileEngine getMusicDirectory] withIntermediateDirectories:NO attributes:nil error:&error];
        if (!success) {
            NSLog(@"Error creating directory %@: %@", [FileEngine getMusicDirectory], error);
            return NO;
        }
    }
    NSArray * supportedTypes = [NSArray arrayWithObjects:kSupportedFileTypes count:(sizeof(kSupportedFileTypes) / sizeof(id))];
    FILE_TYPE fType = [supportedTypes indexOfObject:extension];
    NSLog(@"zip directory %@", [[FileEngine getMusicDirectory] stringByAppendingPathComponent:kZipFolder]);
    switch (fType) {
        case ZIP:
        {
            NSString * destination =[[FileEngine getMusicDirectory] stringByAppendingPathComponent:kZipFolder];
            
            // Check if Zip directory exists, create it if not, clean it if so
            if (![defaultManager fileExistsAtPath:destination isDirectory:nil]) {
                __DEBUG_FE(@"Creating %@", destination);
                success = [defaultManager createDirectoryAtPath:destination withIntermediateDirectories:NO attributes:nil error:&error];
                if (!success) {
                    NSLog(@"Error creating directory %@: %@", destination, error);
                    return NO;
                }
            } else {
                // Remove everything from directory if it already exists
                NSDirectoryEnumerator *enumerator = [defaultManager enumeratorAtPath:destination];
                NSString *file = nil;
                while (file = [enumerator nextObject]) {
                    __DEBUG_FE(@"Removing %@", file);
                    success = [defaultManager removeItemAtPath:[destination stringByAppendingPathComponent:file] error:&error];
                    if (!success) {
                        NSLog(@"Error removing %@: %@", file, error);
                        return NO;
                    }
                }
            }
            
            // Unzip file to Zip directory
            __DEBUG_FE(@"Unzipping to %@", destination);
            success = [SSZipArchive unzipFileAtPath:filePath toDestination:destination overwrite:YES password:nil error:&error];
            if (!success) {
                NSLog(@"Error unzipping %@ to %@: %@", filePath, destination, error);
                return NO;
            }
            
            // Remove zip file
            __DEBUG_FE(@"Removing original file %@", filePath);
            success = [defaultManager removeItemAtPath:filePath error:&error];
            if (!success) {
                NSLog(@"Error removing %@: %@", filePath, error);
                return NO;
            }
            // Determine contents of zip file
            NSDirectoryEnumerator *enumerator = [defaultManager enumeratorAtPath:destination];
            NSString *file = nil;
            while (file = [enumerator nextObject]) {
                [FileEngine parseAudioFileContents:[destination stringByAppendingPathComponent:file]];
            }
        }
            break;
        case NSF:
        {
            [FileEngine parseAudioFileContents:url.path];
        }
            break;
        default:
            break;
    }
    return YES;
}

/**
 * getMusicDirectory
 * @brief Get the current music directory in the container
 * @return Absolute path of music directory
*/
+ (NSString *)getMusicDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return [documentsDirectory stringByAppendingPathComponent:@"Music"];
}

/**
 * parseAudioFileContents
 * @brief Given a file path, determine which folder it should be placed in, place it there,
 *        and add its contents to the database.
 * @param [in]filePath Path of file to parse
 * @return NO for failure, YES for success
 */
+ (BOOL)parseAudioFileContents:(NSString *)filePath {
    BOOL success     = false;
    BOOL isDirectory = false;
    
    NSError *error = nil;
    
    const NSString *consoleFolder = nil;
    NSString       *consolePath   = nil;
    NSString       *gameFolder    = nil;
    NSString       *gamePath      = nil;
    NSString       *finalPath     = nil;
    
    gme_type_t  gameType = nil;
    gme_info_t *gameInfo = nil;
    Music_Emu  *emu      = nil;
    
    NSFileManager *defaultManager = [NSFileManager defaultManager];
    NSLog(@"Attempting to open %@", filePath);
    handle_error(gme_identify_file([filePath UTF8String], &gameType));
    handle_error(gme_open_file([filePath UTF8String], &emu, gme_info_only));
    
    if (emu == nil) {
        return NO;
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
    gameFolder = strlen(gameInfo->game) > 0 ? [NSString stringWithUTF8String:gameInfo->game] : @"No Game";
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
    [FileEngine addToDatabase:emu relativePath:[[consoleFolder stringByAppendingPathComponent:gameFolder] stringByAppendingPathComponent:[filePath lastPathComponent]]];
    
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
 * clearAll
 * @brief Clears database and deletes all local files
 * @return NO for failure, YES for success
 */
+ (BOOL)clearAll {
    BOOL ret = YES;
    if (![FileEngine clearDatabase]) {
        ret = NO;
    }
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
    BOOL isDirectory = NO;
    NSString *directory = [FileEngine getMusicDirectory];
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
    NSError *error = NULL;
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
    BOOL ret = YES;
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSURL *url = [[[[delegate persistentContainer] persistentStoreDescriptions] firstObject] URL];
    ret = [[[delegate persistentContainer] persistentStoreCoordinator] destroyPersistentStoreAtURL: url withType: NSSQLiteStoreType options:NULL error:NULL];
    if (ret == NO) {
        return ret;
    }
    
    ret = [[[delegate persistentContainer] persistentStoreCoordinator] addPersistentStoreWithType:NSSQLiteStoreType configuration:NULL URL:url options:NULL error:NULL];
    
    return ret;
}

/**
 * addToDatabase
 * @brief Given a music emu and a file path, add the contents to the database
 * @param [in]emu Music emulator all ready to go
 * @param [in]relativePath Path of file to parse
 */
+ (void)addToDatabase:(Music_Emu *)emu relativePath:(NSString *)relativePath {
    gme_info_t *gameInfo = nil;
    
    AppDelegate            *delegate          = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *objectContext     = delegate.persistentContainer.viewContext;
    NSEntityDescription    *entityDescription = [NSEntityDescription entityForName:@"Track" inManagedObjectContext:objectContext];
    NSFetchRequest         *request           = [[NSFetchRequest alloc] init];
    NSError                *error             = nil;
    [request setEntity:entityDescription];

    __DEBUG_FE(@"database location: %@", delegate.persistentContainer.persistentStoreCoordinator.persistentStores.firstObject.URL);
    for (int i = 0; i < gme_track_count(emu); i++) {
        gme_track_info(emu, &gameInfo, i);
        NSString *trackName  = strlen(gameInfo->song)   > 0 ? [NSString stringWithUTF8String:gameInfo->song]   : [NSString stringWithFormat:@"Track %d", i + 1];
        NSString *artistName = strlen(gameInfo->author) > 0 ? [NSString stringWithUTF8String:gameInfo->author] : @"No Artist";
        NSString *gameName   = strlen(gameInfo->game)   > 0 ? [NSString stringWithUTF8String:gameInfo->game]   : @"No Game";
        NSString *systemName = strlen(gme_type_system(gme_type(emu))) > 0 ? [NSString stringWithUTF8String:gme_type_system(gme_type(emu))] : @"No System";
        int trackLength = gameInfo->length;
        int loopLength = gameInfo->loop_length;
        int introLength = gameInfo->intro_length;
        
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
        [trackMO setTrackNum:i];
        [trackMO setUrl:relativePath];
        [trackMO setLength:trackLength];
        [trackMO setIntroLength:introLength];
        [trackMO setLoopLength:loopLength];
        
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
    NSArray *ret = nil;
    NSManagedObjectContext *context = [[(AppDelegate *)[[UIApplication sharedApplication] delegate] persistentContainer] viewContext];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:entity inManagedObjectContext:context];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name == %@", name];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDescription];
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
