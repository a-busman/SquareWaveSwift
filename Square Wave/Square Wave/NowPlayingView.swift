//
//  NowPlayingView.swift
//  Square Wave
//
//  Created by Alex Busman on 2/14/20.
//  Copyright © 2020 Alex Busman. All rights reserved.
//

import SwiftUI
import MediaPlayer

class ScrubBar: UISlider {
    override func trackRect(forBounds bounds: CGRect) -> CGRect {
        var newBounds = super.trackRect(forBounds: bounds)
        newBounds.size.height = 3
        return newBounds
    }
}

extension UIImage {
    class func circle(diameter: CGFloat, fillColor: UIColor, strokeColor: UIColor? = nil, offset: CGPoint? = nil) -> UIImage {
        var x: CGFloat = 0.0
        var y: CGFloat = 0.0
        if let _offset = offset {
            x = _offset.x
            y = _offset.y
        }
        UIGraphicsBeginImageContextWithOptions(CGSize(width: diameter + x, height: diameter + y), false, 0)
        let ctx = UIGraphicsGetCurrentContext()!
        ctx.saveGState()
        let rect = CGRect(x: x, y: y, width: diameter, height: diameter)
        ctx.setFillColor(fillColor.cgColor)
        ctx.fillEllipse(in: rect)
        if strokeColor != nil {
            ctx.setStrokeColor(strokeColor!.cgColor)
            ctx.setLineWidth(3.0)
            ctx.strokeEllipse(in: rect)
        }
        ctx.restoreGState()
        let img = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return img
    }
}

struct VolumeView: UIViewRepresentable {

    func makeUIView(context: Context) -> MPVolumeView {
        let view = MPVolumeView(frame: .zero)
        view.tintColor = UIColor.systemGray
        view.showsRouteButton = false
        return view
    }

    func updateUIView(_ view: MPVolumeView, context: Context) {

    }
}

struct ScrubBarView: UIViewRepresentable {
    typealias UIViewType = ScrubBar
    @Binding var value: Float

    func makeUIView(context: UIViewRepresentableContext<ScrubBarView>) -> ScrubBar {
        let bar = ScrubBar()
        let activeImage = UIImage.circle(diameter: 31.0, fillColor: UIColor.systemGray)
        bar.minimumTrackTintColor = UIColor.systemGray
        bar.setThumbImage(UIImage.circle(diameter: 6.0, fillColor: UIColor.systemGray, offset: CGPoint(x: 0.5, y: 0.5)), for: .normal)
        bar.setThumbImage(activeImage, for: .highlighted)
        bar.setThumbImage(activeImage, for: .selected)
        bar.setThumbImage(activeImage, for: .focused)
        return bar
    }
    
    func updateUIView(_ uiView: ScrubBar, context: UIViewRepresentableContext<ScrubBarView>) {
        uiView.value = self.value
    }
}

struct NowPlayingView: View {
    @EnvironmentObject var playbackState: PlaybackState
    @State var scrubTime: Float = 0.0
    var body: some View {
        VStack {
            RoundedRectangle(cornerRadius: 2.5)
                .frame(width: 40.0, height: 5.0)
                .foregroundColor(Color(.systemGray3))
                .padding()
            Spacer()
            Image(uiImage: ListArtView.getImage(for: self.playbackState.nowPlayingTrack?.system?.name ?? "") ?? UIImage())
                .cornerRadius(10.0)
                .overlay(RoundedRectangle(cornerRadius: 10.0).stroke(Color(.systemGray4), lineWidth: 0.5))
                .padding()
            HStack {
                VStack(alignment: .leading) {
                    Text(self.playbackState.nowPlayingTrack?.name ?? "Not Playing")
                        .font(.system(size: 24.0, weight: .bold, design: .default))
                    Text(self.playbackState.nowPlayingTrack?.game?.name ?? "")
                        .font(.system(size: 24.0))
                }.padding()
                Spacer()
                if self.playbackState.nowPlayingTrack != nil {
                    Button(action: {
                        
                    }) {
                        Image(systemName: "ellipsis")
                    }
                    .frame(width: 30, height: 30)
                    .background(Color(.systemGray5))
                    .cornerRadius(15.0)
                    .padding()
                }
            }.padding()
            VStack {
                ScrubBarView(value: self.$scrubTime)
                    .disabled(self.playbackState.nowPlayingTrack == nil)

                HStack {
                    Text("--:--")
                    Spacer()
                    Text("--:--")
                }
            }
            .padding()
            Spacer()
            HStack {
                Spacer()
                Button(action: {
                    self.playbackState.prevTrack()
                }) {
                    Image(systemName: "backward.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 30.0)
                }
                .padding()
                Spacer()
                Button(action: {
                    if !self.playbackState.isNowPlaying {
                        self.playbackState.play()
                    } else {
                        self.playbackState.pause()
                    }
                }) {
                    Image(systemName: self.playbackState.isNowPlaying ? "pause.fill" : "play.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 42.0)
                }
                .padding()
                Spacer()
                Button(action: {
                    self.playbackState.nextTrack()
                }) {
                    Image(systemName: "forward.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 30.0)
                }
                .padding()
                Spacer()
            }
            .foregroundColor(Color(.label))
            .padding()
            Spacer()
            HStack(alignment: .top) {
                Image(systemName: "speaker.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 10.0)
                    .foregroundColor(Color(.systemGray))
                    .offset(x: 0.0, y: 4.0)
                VolumeView()
                Image(systemName: "speaker.3.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 10.0)
                    .foregroundColor(Color(.systemGray))
                    .offset(x: 0.0, y: 4.0)
            }.padding()
        }
    }
}

struct NowPlayingView_Previews: PreviewProvider {
    static var previews: some View {
        NowPlayingView()
    }
}
