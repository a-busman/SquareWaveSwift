//
//  PlaylistsView.swift
//  Square Wave
//
//  Created by Alex Busman on 2/13/20.
//  Copyright © 2020 Alex Busman. All rights reserved.
//

import SwiftUI

struct PlaylistBlurView: UIViewRepresentable {
    
    func makeUIView(context: UIViewRepresentableContext<PlaylistBlurView>) -> UIVisualEffectView {
        let blurBg = UIVisualEffectView(effect: UIBlurEffect(style: .extraLight))
        let vibrancyView = UIVisualEffectView(effect: UIVibrancyEffect(blurEffect: UIBlurEffect(style: .extraLight), style: .label))
        let imageView = UIImageView(image: UIImage(systemName: "plus"))
        
        blurBg.contentView.addSubview(vibrancyView)
        vibrancyView.translatesAutoresizingMaskIntoConstraints = false
        
        vibrancyView.bottomAnchor.constraint(equalTo: blurBg.contentView.bottomAnchor).isActive = true
        vibrancyView.topAnchor.constraint(equalTo: blurBg.contentView.topAnchor).isActive = true
        vibrancyView.leadingAnchor.constraint(equalTo: blurBg.contentView.leadingAnchor).isActive = true
        vibrancyView.trailingAnchor.constraint(equalTo: blurBg.contentView.trailingAnchor).isActive = true
        
        vibrancyView.contentView.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false

        imageView.widthAnchor.constraint(equalToConstant: 48.0).isActive = true
        imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor).isActive = true
        
        imageView.centerXAnchor.constraint(equalTo: vibrancyView.contentView.centerXAnchor).isActive = true
        imageView.centerYAnchor.constraint(equalTo: vibrancyView.contentView.centerYAnchor).isActive = true

        return blurBg
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: UIViewRepresentableContext<PlaylistBlurView>) {
        
    }
}

struct PlaylistRowView: View {
    @State private var image: Image?
    @Binding var uiImage: UIImage
    @Binding var text: String
    @State var blurViewVisible: Bool = false
    
    var body: some View {
        HStack {
            ZStack {
                self.image?
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .overlay(RoundedRectangle(cornerRadius: 5.0).stroke(Color(.systemGray4)))
                    .cornerRadius(5.0)
                if self.blurViewVisible {
                    PlaylistBlurView().cornerRadius(5.0)
                }
            }.frame(width: 128.0, height: 128.0)

            Text(self.text)
                .foregroundColor(Color(.systemBlue))
                .padding()
            
        }.onAppear() {
            self.image = Image(uiImage: self.uiImage)
        }
    }
}

struct PlaylistsView: View {
    @Environment(\.managedObjectContext) var context
    @EnvironmentObject var playbackState: PlaybackState
    @State var newPlaylistShowing = false
    @State var purchased = false
    @FetchRequest(entity: Playlist.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \Playlist.dateAdded, ascending: true)], predicate: NSPredicate(format: "isNowPlaying != true")) var playlists: FetchedResults<Playlist>
    var body: some View {
        Group {
            if self.purchased || self.playbackState.purchased{
                List {
                    Button(action: {
                        self.newPlaylistShowing.toggle()
                    }) {
                        PlaylistRowView(uiImage: Binding(get: {
                            UIImage(named: "placeholder-playlist") ?? UIImage()
                        }, set: { _ in
                            
                        }), text: .constant("\(NSLocalizedString("New Playlist", comment: "New Playlist"))..."), blurViewVisible: true)
                    }
                    ForEach(self.playlists, id: \.self) { (playlist: Playlist) in
                        NavigationLink(destination: PlaylistView(playlist: playlist)) {
                            PlaylistRowView(uiImage: Binding(get: {
                                self.getPlaylistImage(playlist)
                            }, set: { _ in
                                
                            }), text: Binding(get: {
                                playlist.name ?? ""
                            }, set: { _ in
                                
                            }))
                        }
                    }.onDelete(perform: { indexSet in
                        for index in indexSet {
                            let playlist = self.playlists[index]
                            if let imageUrl = playlist.art,
                                let fullUrl = Util.getPlaylistImagesDirectory()?.appendingPathComponent(imageUrl.lastPathComponent) {
                                if FileManager.default.isDeletableFile(atPath: fullUrl.path) {
                                    do {
                                        try FileManager.default.removeItem(at: fullUrl)
                                    } catch {
                                        NSLog("Failed to delete playlist art at \(fullUrl.path)")
                                    }
                                }
                            }
                            self.context.delete(playlist)
                            try? self.context.save()
                        }
                    })
                }.navigationBarTitle(Text(NSLocalizedString("Playlists", comment: "Playlists")))
                .sheet(isPresented: self.$newPlaylistShowing) {
                    NewPlaylistView()
                }
            } else {
                VStack {
                    Spacer()
                    Text(NSLocalizedString("Playlists Premium", comment: "Playlists Premium")).multilineTextAlignment(.center).padding()
                    Button(action: {self.playbackState.delegate?.openSettings()}) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10).foregroundColor(.blue)
                            Text(NSLocalizedString("Confirm Playlists", comment: "Confirm Playlists")).foregroundColor(.white)
                        }.frame(maxWidth: 200, maxHeight: 50)
                    }.padding().padding(Edge.Set(arrayLiteral: .bottom), 125)
                    Spacer()
                }.navigationBarTitle(Text(NSLocalizedString("Playlists", comment: "Playlists")))
            }
        }
        .onAppear {
            self.purchased = Util.getPurchased()
        }
    }
    
    func getPlaylistImage(_ playlist: Playlist) -> UIImage {
        if playlist.art != nil {
            let image = UIImage(contentsOfFile: Util.getPlaylistImagesDirectory()!.appendingPathComponent(playlist.art?.lastPathComponent ?? "").path) ?? UIImage(named: "placeholder-art")!
            return image
        }
        return UIImage(named: "placeholder-art")!
    }
}

struct PlaylistsView_Previews: PreviewProvider {
    static var previews: some View {
        PlaylistsView()
    }
}
