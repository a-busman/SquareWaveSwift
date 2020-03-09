//
//  Util.swift
//  Square Wave
//
//  Created by Alex Busman on 3/8/20.
//  Copyright © 2020 Alex Busman. All rights reserved.
//

import Foundation

class Util {
    class func getPlaylistImagesDirectory() -> URL? {
        var ret: URL?
        do {
            let docsDir = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            ret = docsDir.appendingPathComponent("images/playlists")
        } catch {
            NSLog("Could not get docs dir")
        }
        return ret
    }
}
