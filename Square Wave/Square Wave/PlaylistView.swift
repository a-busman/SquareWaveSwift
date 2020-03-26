//
//  PlaylistView.swift
//  Square Wave
//
//  Created by Alex Busman on 2/21/20.
//  Copyright © 2020 Alex Busman. All rights reserved.
//

import AVFoundation
import SwiftUI

class PlaylistModel: ObservableObject {
    @Published var tracks: [Track] = [] {
        didSet {
            if let playlist = self.playlist {
                playlist.tracks = NSOrderedSet(array: self.tracks)
                let delegate = UIApplication.shared.delegate as! AppDelegate
                delegate.saveContext()
            }
            self.updatePlaylistImage()
        }
    }
    @Published var titleText: String = "" {
        didSet {
            if let playlist = self.playlist {
                playlist.name = self.titleText
                let delegate = UIApplication.shared.delegate as! AppDelegate
                
                delegate.saveContext()
            }
        }
    }
    
    @Published var image: UIImage = UIImage(named: "placeholder-art")!
    var playlist: Playlist?
    
    init() {

    }
    
    init(playlist: Playlist) {
        if let tracks = playlist.tracks {
            self.tracks = tracks.array as! [Track]
        }
        self.titleText = playlist.name ?? ""
        self.playlist = playlist
        
        self.image = self.loadPlaylistImage(url: Util.getPlaylistImagesDirectory()?.appendingPathComponent(playlist.art?.path ?? ""))
    }
    
    func updatePlaylistImage() {
        if self.tracks.count > 0 {
            var platforms: [System] = []
            for track in self.tracks {
                if let system = track.system,
                    platforms.firstIndex(of: system) == nil {
                        platforms.append(system)
                }
            }
            var images: [UIImage] = []
            for platform in platforms {
                if let image = ListArtView.getImage(for: platform.name ?? "") {
                    images.append(image)
                }
            }
            switch images.count {
            case 0:
                self.savePlaylistImage(image: nil)
                self.image = UIImage(named: "placeholder-art")!
            case 1:
                self.savePlaylistImage(image: images[0])
                self.image = images[0]
            case 2:
                let stitched = self.stitch(images: images, isVertical: false)
                self.savePlaylistImage(image: stitched)
                self.image = stitched
            case 3:
                let intermediate = self.stitch(images: [images[0], images[1]], isVertical: false)
                let stitched = self.stitch(images: [intermediate, images[2]], isVertical: true)
                self.savePlaylistImage(image: stitched)
                self.image = stitched
            default:
                let intermediate1 = self.stitch(images: [images[0], images[1]], isVertical: false)
                let intermediate2 = self.stitch(images: [images[2], images[3]], isVertical: false)
                let stitched = self.stitch(images: [intermediate1, intermediate2], isVertical: true)
                self.savePlaylistImage(image: stitched)
                self.image = stitched
            }
        } else {
            self.savePlaylistImage(image: nil)
            self.image = UIImage(named: "placeholder-art")!
        }
    }
    
    func loadPlaylistImage(url: URL?) -> UIImage {
        if url != nil {
            return UIImage(contentsOfFile: url!.path) ?? UIImage(named: "placeholder-art")!
        }
        return UIImage(named: "placeholder-art")!
    }
    
    func savePlaylistImage(image: UIImage?) {
        if let playlist = self.playlist,
            let filename = Util.getPlaylistImagesDirectory()?.appendingPathComponent("\(playlist.id!).png") {
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
    
    func stitch(images: [UIImage], isVertical: Bool) -> UIImage {
        var stitchedImages : UIImage!
        if images.count > 0 {
            var maxWidth = CGFloat(0), maxHeight = CGFloat(0)
            for image in images {
                if image.size.width > maxWidth {
                    maxWidth = image.size.width
                }
                if image.size.height > maxHeight {
                    maxHeight = image.size.height
                }
            }
            var totalSize : CGSize
            let maxSize = CGSize(width: maxWidth, height: maxHeight)
            if isVertical {
                totalSize = CGSize(width: maxSize.width, height: maxSize.height * (CGFloat)(images.count))
            } else {
                totalSize = CGSize(width: maxSize.width  * (CGFloat)(images.count), height: maxSize.height)
            }
            UIGraphicsBeginImageContext(totalSize)
            for image in images {
                var croppedImage: UIImage?
                let imageHeight = image.size.height
                let imageWidth = image.size.width
                if isVertical {
                    if imageWidth < maxSize.width {
                        croppedImage = self.image(with: image, scaledTo: maxSize.width / imageWidth)
                        croppedImage = self.cropToBounds(image: croppedImage!, width: maxSize.width, height: maxSize.height)
                    }
                    if croppedImage != nil {
                        
                        if (maxSize.width / imageWidth) * imageHeight < maxSize.height {
                            croppedImage = self.image(with: croppedImage!, scaledTo: maxSize.height / croppedImage!.size.height)
                            croppedImage = self.cropToBounds(image: croppedImage!, width: maxSize.width, height: maxSize.height)
                        }
                    } else {
                        if imageHeight < maxSize.height {
                            croppedImage = self.image(with: image, scaledTo: maxSize.height / imageHeight)
                            croppedImage = self.cropToBounds(image: croppedImage!, width: maxSize.width, height: maxSize.height)
                        }
                    }
                } else {
                    if imageHeight < maxSize.height {
                        croppedImage = self.image(with: image, scaledTo: maxSize.height / imageHeight)
                        croppedImage = self.cropToBounds(image: croppedImage!, width: maxSize.width, height: maxSize.height)
                    }
                    if croppedImage != nil {
                        if (maxSize.height / imageHeight) * imageWidth < maxSize.width {
                            croppedImage = self.image(with: croppedImage!, scaledTo: maxSize.width / croppedImage!.size.width)
                            croppedImage = self.cropToBounds(image: croppedImage!, width: maxSize.width, height: maxSize.height)
                        }
                    } else {
                        if imageWidth < maxSize.width {
                            croppedImage = self.image(with: image, scaledTo: maxSize.width / imageWidth)
                            croppedImage = self.cropToBounds(image: croppedImage!, width: maxSize.width, height: maxSize.height)
                        }
                    }
                }
                let offset = (CGFloat)(images.firstIndex(of: image)!)
                if croppedImage == nil {
                    let rect =  AVMakeRect(aspectRatio: image.size, insideRect: isVertical ?
                        CGRect(x: 0, y: maxSize.height * offset, width: maxSize.width, height: maxSize.height) :
                        CGRect(x: maxSize.width * offset, y: 0, width: maxSize.width, height: maxSize.height))
                    image.draw(in: rect)
                } else {
                    let rect =  AVMakeRect(aspectRatio: croppedImage!.size, insideRect: isVertical ?
                        CGRect(x: 0, y: maxSize.height * offset, width: maxSize.width, height: maxSize.height) :
                        CGRect(x: maxSize.width * offset, y: 0, width: maxSize.width, height: maxSize.height))
                    croppedImage!.draw(in: rect)
                }
            }
            stitchedImages = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
        }
        return stitchedImages
    }
    
    func cropToBounds(image: UIImage, width: CGFloat, height: CGFloat) -> UIImage {
        
        let contextImage: UIImage = UIImage(cgImage: image.cgImage!)
        let xOffset: CGFloat = (image.size.width - width) / 2.0
        
        let rect: CGRect = CGRect(x: xOffset, y: 0, width: width, height: height)
        
        let imageRef: CGImage = contextImage.cgImage!.cropping(to: rect)!
        
        let image: UIImage = UIImage(cgImage: imageRef, scale: image.scale, orientation: image.imageOrientation)
        
        return image
    }
    
    func image(with sourceImage: UIImage, scaledTo factor: CGFloat) -> UIImage {
        let newHeight = sourceImage.size.height * factor
        let newWidth = sourceImage.size.width * factor
        
        UIGraphicsBeginImageContext(CGSize(width:newWidth, height:newHeight))
        sourceImage.draw(in: CGRect(x:0, y:0, width:newWidth, height:newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
}

struct PlaylistView: View {
    @State var isEditMode = false
    @State private var isShowingAddModal = false
    var isNewPlaylist = false
    @ObservedObject var playlistModel: PlaylistModel = PlaylistModel()
    @EnvironmentObject var playbackState: PlaybackState
    
    init(isNewPlaylist: Bool, playlistModel: PlaylistModel) {
        self.isNewPlaylist = isNewPlaylist
        self.playlistModel = playlistModel
    }
    
    init(playlist: Playlist) {
        self.playlistModel = PlaylistModel(playlist: playlist)
    }

    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top) {
                Image(uiImage: self.playlistModel.image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 128)
                    .cornerRadius(5.0)
                    .padding()
                if self.isEditMode {
                    TextView(title:"Playlist Title", text: self.$playlistModel.titleText).padding(.vertical, 5.0)
                    .frame(height: 128)
                } else {
                    Text(self.playlistModel.titleText).font(.headline).padding(.vertical, 12.5).padding(.leading, 6.0)
                }
            }
            Divider().padding(.leading)
            if self.isEditMode {
                Button(action: {
                    self.isShowingAddModal.toggle()
                }) {
                    ZStack(alignment: .leading) {
                        Rectangle().foregroundColor(.clear)
                            .frame(height: 30.0)
                        HStack {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10).frame(width: 20.0, height: 20.0)
                                    .foregroundColor(.white)
                                Image(systemName: "plus.circle.fill")
                                    .resizable()
                                    .frame(width: 24.0, height: 24.0)
                                    .foregroundColor(Color(.systemGreen))
                            }
                            Text("Add Songs")
                        }
                    }
                }.padding(.horizontal)
                Divider().padding(.leading)
            }
            UIListView(rows: Binding(get: {
                return self.playlistModel.tracks
            }, set: { value in
                self.playlistModel.objectWillChange.send()
                self.playlistModel.tracks = value as! [Track]
                self.playbackState.currentTracklist = self.playlistModel.tracks
            }), sortType: .constant(SortType.none.rawValue), isEditing: self.$isEditMode, rowType: Track.self, keypaths: UIListViewCellKeypaths(art: \Track.system?.name, title: \Track.name, desc: \Track.game?.name), showSections: false, showSearch: false, showsHeader: !self.isEditMode, isEditable: true)
                .environmentObject(AppDelegate.playbackState)
                .offset(y: -8.0)
                .edgesIgnoringSafeArea(.bottom)
                .sheet(isPresented: self.$isShowingAddModal) {
                    AddToPlaylistView(selectedTracks: self.$playlistModel.tracks).environment(\.managedObjectContext, (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext)
            }
                .if(!self.isNewPlaylist) {
                    $0.navigationBarItems(trailing: Button(action: {
                        self.isEditMode.toggle()
                    }) {
                        Text(self.isEditMode ? "Done" : "Edit")
                    })
                }
        }.onAppear {
            if self.isNewPlaylist {
                self.isEditMode = true
            }
        }.navigationBarTitle("", displayMode: .inline)
    }
}

extension View {
    func `if`<Content: View>(_ conditional: Bool, content: (Self) -> Content) -> some View {
        if conditional {
            return AnyView(content(self))
        } else {
            return AnyView(self)
        }
    }
}

/*
struct PlaylistView_Previews: PreviewProvider {
    static var previews: some View {
        PlaylistView()
    }
}
*/
