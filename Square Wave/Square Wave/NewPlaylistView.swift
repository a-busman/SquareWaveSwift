//
//  NewPlaylistView.swift
//  Square Wave
//
//  Created by Alex Busman on 3/1/20.
//  Copyright © 2020 Alex Busman. All rights reserved.
//

import SwiftUI

struct NewPlaylistView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @State var playlist: Playlist?
    @ObservedObject var playlistModel = PlaylistModel()
    var body: some View {
        NavigationView {
            PlaylistView(isNewPlaylist: true, playlistModel: self.playlistModel)
                .navigationBarTitle(Text(NSLocalizedString("New Playlist", comment: "New Playlist")), displayMode: .inline)
                .navigationBarItems(leading: Button(action: {
                    self.presentationMode.wrappedValue.dismiss()
                }) {
                    Text(NSLocalizedString("Cancel", comment: "Cancel"))
                }, trailing: Button(action: {
                    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
                    let playlist = Playlist(entity: Playlist.entity(), insertInto: context)
                    
                    playlist.id = UUID()
                    playlist.name = self.playlistModel.titleText
                    playlist.tracks = NSOrderedSet(array: self.playlistModel.tracks)
                    playlist.dateAdded = Date()
                    let image = self.playlistModel.image
                    self.savePlaylistImage(playlist, image: image)
                    
                    self.presentationMode.wrappedValue.dismiss()
                }) {
                    Text(NSLocalizedString("Done", comment: "Done"))
                    .bold()
                })
        }
    }
    
    func savePlaylistImage(_ playlist: Playlist, image: UIImage?) {
        if let filename = Util.getPlaylistImagesDirectory()?.appendingPathComponent("\(playlist.id!).png") {
            let url = URL(fileURLWithPath: "\(playlist.id!).png")
            let delegate = UIApplication.shared.delegate as! AppDelegate
            if image != nil {
                let data = image!.pngData()
                do {
                    try data?.write(to: filename)
                    playlist.art = url
                    delegate.saveContext()
                } catch {
                    NSLog("Failed to write image data to \(filename.path)")
                }
            } else {
                do {
                    try FileManager.default.removeItem(at: filename)
                    playlist.art = nil
                    delegate.saveContext()
                } catch {
                    NSLog("Failed to remove \(filename.path)")
                }
            }
        }
    }
}

/*
struct NewPlaylistView_Previews: PreviewProvider {
    static var previews: some View {
        NewPlaylistView()
    }
}
*/
