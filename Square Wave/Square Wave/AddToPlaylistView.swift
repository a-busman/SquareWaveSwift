//
//  AddToPlaylistView.swift
//  Square Wave
//
//  Created by Alex Busman on 3/1/20.
//  Copyright © 2020 Alex Busman. All rights reserved.
//

import SwiftUI

struct AddToPlaylistView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @FetchRequest(entity: Track.entity(), sortDescriptors: []) var tracks: FetchedResults<Track>
    @State private var searchText = ""
    @State private var showCancelButton: Bool = false
    @Binding var selectedTracks: [Track]
    @State var tempTracks: [Track] = []
    
    var body: some View {
        NavigationView {
            VStack {
                // Search view
                HStack {
                    HStack {
                        Image(systemName: "magnifyingglass")

                        TextField(NSLocalizedString("Search", comment: "Search"), text: self.$searchText, onEditingChanged: { isEditing in
                            self.showCancelButton = true
                        }, onCommit: {
                            print("onCommit")
                        }).foregroundColor(.primary)

                        Button(action: {
                            self.searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill").opacity(self.searchText == "" ? 0 : 1)
                        }
                    }
                    .padding(EdgeInsets(top: 8, leading: 6, bottom: 8, trailing: 6))
                    .foregroundColor(.secondary)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10.0)

                    if self.showCancelButton  {
                        Button("Cancel") {
                                UIApplication.shared.endEditing(true) // this must be placed before the other commands here
                                self.searchText = ""
                                self.showCancelButton = false
                        }
                        .foregroundColor(Color(.systemBlue))
                    }
                }
                .padding(Edge.Set(arrayLiteral: [.horizontal, .top]))
                    .navigationBarHidden(self.showCancelButton) // .animation(.default) // animation does not work properly

                List {
                    // Filtered list of names
                    ForEach(self.tracks.filter{
                        $0.name!.contains(self.searchText) || self.searchText == "" || $0.game!.name!.contains(self.searchText)
                    }, id:\.self) { (track: Track) in
                        Button(action: {
                            let index = self.tempTracks.firstIndex(of: track)
                            if index == nil {
                                self.tempTracks.append(track)
                            } else {
                                self.tempTracks.remove(at: index!)
                            }
                        }) {
                            HStack {
                                Image(uiImage: ListArtView.getImage(for: track.system?.name ?? "") ?? UIImage())
                                    .resizable()
                                    .frame(width: 32.0, height: 32.0)
                                    .cornerRadius(3.0)
                                VStack(alignment: .leading) {
                                    Text(track.name!)
                                    Text(track.game!.name!).font(.subheadline).foregroundColor(Color(.secondaryLabel))
                                }
                                Spacer()
                                Image(systemName: self.tempTracks.firstIndex(of: track) == nil ? "plus.circle" : "checkmark")
                            }
                        }
                    }
                }
                .navigationBarTitle(Text(NSLocalizedString("Add To Playlist", comment: "Add To Playlist")), displayMode: .inline)
                .navigationBarItems(leading: Button(action: {
                    self.presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Cancel")
                    }, trailing: Button(action: {
                        self.selectedTracks = self.tempTracks
                        self.presentationMode.wrappedValue.dismiss()
                    }) {
                        Text(NSLocalizedString("Done", comment: "Done")).bold()
                })
                .resignKeyboardOnDragGesture()
            }
        }.onAppear {
            self.tempTracks = self.selectedTracks
        }
    }
}

/*
struct AddToPlaylistView_Previews: PreviewProvider {
    static var previews: some View {
        AddToPlaylistView(selectedTracks: .constant([]))
    }
}*/

extension UIApplication {
    func endEditing(_ force: Bool) {
        self.windows
            .filter{$0.isKeyWindow}
            .first?
            .endEditing(force)
    }
}

struct ResignKeyboardOnDragGesture: ViewModifier {
    var gesture = DragGesture().onChanged{_ in
        UIApplication.shared.endEditing(true)
    }
    func body(content: Content) -> some View {
        content.gesture(gesture)
    }
}

extension View {
    func resignKeyboardOnDragGesture() -> some View {
        return modifier(ResignKeyboardOnDragGesture())
    }
}
