//
//  ContentView.swift
//  Square Wave
//
//  Created by Alex Busman on 2/10/20.
//  Copyright © 2020 Alex Busman. All rights reserved.
//

import SwiftUI

struct TestPlaybackView: View {
    @State private var muteMask = 0
    @State private var toggles = [ true, true, true, true, true ] {
        didSet {
            var mask: Int32 = 0
            for (i, toggle) in toggles.enumerated() {
                if !toggle {
                    mask |= 1 << i
                }
            }
            AudioEngine.sharedInstance()?.setMuteVoices(mask)
        }
    }
    var body: some View {
        VStack(spacing: 20.0) {
            Button(action: {AudioEngine.sharedInstance()?.play()}) {
                Text("Play")
            }
            Button(action: {AudioEngine.sharedInstance()?.pause()}) {
                Text("Pause")
            }
            Button(action: {AudioEngine.sharedInstance()?.stop()}) {
                Text("Stop")
            }
            HStack {
                Button(action: {AudioEngine.sharedInstance()?.prevTrack()}) {
                    Text("Prev")
                }
                Button(action: {AudioEngine.sharedInstance()?.nextTrack()}) {
                    Text("Next")
                }
            }
            HStack {
                ForEach(0...4, id: \.self) { index in
                    Toggle(isOn: Binding(
                        get: { return self.toggles[index] },
                        set: { (newValue) in return self.toggles[index] = newValue }
                    )) {
                        Text("\(index)")
                    }
                }
                
            }
        }
    }
}

struct TestPlaybackView_Previews: PreviewProvider {
    static var previews: some View {
        TestPlaybackView()
    }
}
