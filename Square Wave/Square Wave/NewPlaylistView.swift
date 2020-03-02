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
    var body: some View {
        NavigationView {
            PlaylistView()
                .navigationBarTitle(Text("New Playlist"), displayMode: .inline)
                .navigationBarItems(leading: Button(action: {
                    self.presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Cancel")
                }, trailing: Button(action: {
                    self.presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Done")
                    .bold()
                })
        }
    }
}

struct NewPlaylistView_Previews: PreviewProvider {
    static var previews: some View {
        NewPlaylistView()
    }
}
