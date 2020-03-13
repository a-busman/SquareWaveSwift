//
//  NowPlayingView.swift
//  Square Wave
//
//  Created by Alex Busman on 2/14/20.
//  Copyright © 2020 Alex Busman. All rights reserved.
//

import SwiftUI
import MediaPlayer
import AVKit

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

struct AirplayView: UIViewRepresentable {
    
    func makeUIView(context: Context) -> AVRoutePickerView {
        let view = AVRoutePickerView()
        view.activeTintColor = .label
        view.tintColor = .systemGray
        return view
    }
    
    func updateUIView(_ view: AVRoutePickerView, context: Context) {
        
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
    @State var elapsedTime: Int = 0
    @State var totalTime: Int = 0
    @State var remainingTime: Int = 0
    @State var elapsedString: String = "--:--"
    @State var remainingString: String = "--:--"
    @State var optionsShowing: Bool = false
    @State var playbackRate: Double = 2
    @State var elapsedTimer: Timer?
    var showsHandle = true
    let impactGenerator = UIImpactFeedbackGenerator()
    let selectionGenerator = UISelectionFeedbackGenerator()
    var body: some View {
        VStack {
            // MARK: - Drag Handle
            if self.showsHandle {
                RoundedRectangle(cornerRadius: 2.5)
                    .frame(width: 40.0, height: 5.0)
                    .foregroundColor(Color(.systemGray3))
                    .padding(.top)
            }
            Spacer()
            // MARK: - Album Art
            HStack {
                Image(uiImage: ListArtView.getImage(for: self.playbackState.nowPlayingTrack?.system?.name ?? "") ?? UIImage(named: "placeholder-art")!)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: self.getArtSize(), height: self.getArtSize())
                    .cornerRadius(10.0)
                    .overlay(RoundedRectangle(cornerRadius: 10.0).stroke(Color(.systemGray4), lineWidth: 0.5))
                    .shadow(radius: 5.0)
                    .animation(.spring())
                if self.optionsShowing {
                    VStack(alignment: .leading) {
                        Text(self.playbackState.nowPlayingTrack?.name ?? "Not Playing")
                            .font(.system(size: 20.0, weight: .bold, design: .default))
                        Text(self.playbackState.nowPlayingTrack?.game?.name ?? " ")
                            .font(.system(size: 20.0))
                    }.padding(.vertical)
                    Spacer()
                    if self.playbackState.nowPlayingTrack != nil {
                        Button(action: {
                            self.selectionGenerator.selectionChanged()
                            withAnimation {
                                self.optionsShowing.toggle()
                            }
                        }) {
                            Image(systemName: "ellipsis")
                        }
                        .frame(width: 30, height: 30)
                        .background(Color(.systemGray5))
                        .cornerRadius(15.0)
                        .padding(.top)
                    }
                }
            }.padding(.horizontal)
            if self.optionsShowing {
                // MARK: - Playback options
                Divider()
                VStack(alignment: .leading) {
                    Text("Playback Rate")
                        .font(.callout)
                        .foregroundColor(Color(.tertiaryLabel))
                        .padding(.vertical)
                    Text(self.getPlaybackRateText())
                        .padding(.horizontal)
                        .frame(maxWidth: .infinity, alignment: .center)
                    Slider(value: Binding(
                    get: {
                        switch self.playbackState.currentTempo {
                        case 0.5:
                            return 0.0
                        case 0.75:
                            return 1.0
                        case 1.0:
                            return 2.0
                        case 1.5:
                            return 3.0
                        case 2.0:
                            return 4.0
                        default:
                            return 2.0
                        }
                    }, set: { (newValue) in
                        if self.playbackRate != newValue {
                            UISelectionFeedbackGenerator().selectionChanged()
                            self.playbackRate = newValue
                            switch newValue {
                            case 0.0:
                                self.playbackState.set(tempo: 0.5)
                            case 1.0:
                                self.playbackState.set(tempo: 0.75)
                            case 2.0:
                                self.playbackState.set(tempo: 1.0)
                            case 3.0:
                                self.playbackState.set(tempo: 1.5)
                            case 4.0:
                                self.playbackState.set(tempo: 2.0)
                            default:
                                self.playbackState.set(tempo: 1.0)
                            }
                        }

                    }
                    ), in: 0...4, step: 1.0)
                        .accentColor(Color(.label))
                        .padding(.horizontal)
                    Text("Voices")
                        .font(.callout)
                        .foregroundColor(Color(.tertiaryLabel))
                    List {
                        ForEach(0..<(AudioEngine.sharedInstance()?.getVoiceCount() ?? 0), id: \.self) { index in
                            Button(action: {
                                self.selectionGenerator.selectionChanged()
                                if (self.playbackState.muteMask & (1 << index)) == 0 {
                                    self.playbackState.muteMask |= (1 << index)
                                } else {
                                    self.playbackState.muteMask &= ~(1 << index)
                                }
                                AudioEngine.sharedInstance()?.setMuteVoices(Int32(self.playbackState.muteMask))
                            }) {
                                HStack {
                                    Text(String(cString: (AudioEngine.sharedInstance()!.getVoiceName(index as Int32))))
                                    Spacer()
                                    if (self.playbackState.muteMask & (1 << index)) == 0 {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    }
                }.padding(.horizontal)
                Spacer()
                
            // MARK: - Track Info
            } else {
                Spacer()
                HStack {
                    VStack(alignment: .leading) {
                        Text(self.playbackState.nowPlayingTrack?.name ?? "Not Playing")
                            .font(.system(size: 24.0, weight: .bold, design: .default))
                            .lineLimit(1)
                        Text(self.playbackState.nowPlayingTrack?.game?.name ?? " ")
                            .font(.system(size: 24.0))
                            .lineLimit(1)
                    }
                    Spacer()
                    if self.playbackState.nowPlayingTrack != nil {
                        Button(action: {
                            self.selectionGenerator.selectionChanged()
                            withAnimation {
                                self.optionsShowing.toggle()
                            }
                        }) {
                            Image(systemName: "ellipsis")
                        }
                        .frame(width: 30, height: 30)
                        .background(Color(.systemGray5))
                        .cornerRadius(15.0)
                    }
                }.padding()
                // MARK: - Scrub Bar
                VStack {
                    ScrubBarView(value: self.$scrubTime)
                        .disabled(true)
                        .frame(height: 10.0)

                    HStack {
                        Text(self.elapsedString)
                        Spacer()
                        Text(self.remainingString)
                    }
                    .font(.system(size: 14.0, weight: .semibold, design: .default))
                    .foregroundColor(Color(.systemGray3))

                }
                .padding(.horizontal)
                // MARK: - Playback Controls
                HStack {
                    Spacer()
                    Button(action: {
                        self.impactGenerator.impactOccurred(intensity: 0.5)
                        self.playbackState.prevTrack()
                    }) {
                        Image(systemName: "backward.end.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 30.0)
                    }
                    .padding(.horizontal)
                    Spacer()
                    Button(action: {
                        self.impactGenerator.impactOccurred(intensity: 1.0)
                        if !self.playbackState.isNowPlaying {
                            self.playbackState.play()
                        } else {
                            self.playbackState.pause()
                        }
                    }) {
                        Image(systemName: self.playbackState.isNowPlaying ? "pause.fill" : "play.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 42.0, height: 42.0)
                    }
                    .padding(.horizontal)
                    Spacer()
                    Button(action: {
                        self.impactGenerator.impactOccurred(intensity: 0.5)
                        self.playbackState.nextTrack()
                    }) {
                        Image(systemName: "forward.end.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 30.0)
                    }
                    .padding(.horizontal)
                    Spacer()
                }
                .foregroundColor(Color(.label))
                .padding(.vertical)
                // MARK: - Volume Controls
                HStack(alignment: .top) {
                    Image(systemName: "speaker.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 10.0)
                        .foregroundColor(Color(.systemGray))
                        .offset(x: 0.0, y: 4.0)
                    VolumeView()
                        .frame(height: 10.0)
                    Image(systemName: "speaker.3.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 10.0)
                        .foregroundColor(Color(.systemGray))
                        .offset(x: 0.0, y: 4.0)
                }.padding()
                // MARK: - Playback Modifiers
                HStack {
                    Spacer()
                    Button(action: {
                        self.selectionGenerator.selectionChanged()
                        self.playbackState.loop()
                    }) {
                        ZStack {
                            if self.playbackState.loopTrack {
                                RoundedRectangle(cornerRadius: 25.0)
                                    .foregroundColor(Color(.systemGray4))
                            }
                            Image(systemName: "repeat")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 20.0)
                                .foregroundColor(self.playbackState.loopTrack ? Color(.label) : Color(.systemGray))
                        }
                    }
                        .frame(width: 50.0, height: 50.0)
                        .padding()
                    AirplayView()
                        .frame(height: 30.0)
                        .padding()
                    Button(action: {
                        self.selectionGenerator.selectionChanged()
                        self.playbackState.shuffle()
                    }) {
                        ZStack {
                            if self.playbackState.shuffleTracks {
                                RoundedRectangle(cornerRadius: 25.0)
                                    .foregroundColor(Color(.systemGray4))
                            }
                            Image(systemName: "shuffle")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 20.0)
                                .foregroundColor(self.playbackState.shuffleTracks ? Color(.label) : Color(.systemGray))
                        }
                    }
                        .frame(width: 50.0, height: 50.0)
                        .padding()
                }.padding(Edge.Set(arrayLiteral: [.bottom, .horizontal]))
            }
        }.onReceive(self.playbackState.objectWillChange) {
            if self.playbackState.isNowPlaying {
                self.elapsedTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true, block: { _ in
                    self.updateTimes()
                })
            } else {
                self.elapsedTimer?.invalidate()
            }
            self.updateTimes()
            
        }.onAppear {
            self.impactGenerator.prepare()
            self.selectionGenerator.prepare()
            if self.playbackState.isNowPlaying {
                self.elapsedTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true, block: { _ in
                    self.updateTimes()
                })
            } else {
                self.elapsedTimer?.invalidate()
            }
            self.updateTimes()
        }
    }
    
    func updateTimes() {
        self.elapsedTime = self.playbackState.elapsedTime
        if self.playbackState.nowPlayingTrack?.loopLength ?? 0 > 0 {
            let loopCount: Int = PlaybackStateProperty.loopCount.getProperty() ?? 2
            let loopLength = self.playbackState.nowPlayingTrack!.loopLength * Int32(loopCount)
            self.totalTime = Int(self.playbackState.nowPlayingTrack!.introLength + loopLength)
        } else if self.playbackState.nowPlayingTrack?.length ?? 0 > 0 {
            self.totalTime = Int(self.playbackState.nowPlayingTrack!.length)
        } else {
            self.totalTime = PlaybackStateProperty.trackLength.getProperty() ?? 150000
        }
        self.remainingTime = self.totalTime - self.elapsedTime
        if !self.playbackState.loopTrack {
            self.scrubTime = Float(self.elapsedTime) / Float(self.totalTime)
            self.elapsedString = String(format: "%d:%02d", (self.elapsedTime / 1000) / 60, (self.elapsedTime / 1000) % 60)
            self.remainingString = String(format: "-%d:%02d", (self.remainingTime / 1000) / 60, max(((self.remainingTime / 1000) % 60), 0))
        } else {
            self.scrubTime = 0.0
            self.elapsedString = "∞"
            self.remainingString = "-∞"
        }
    }
    
    func getPlaybackRateText() -> String {
        switch self.playbackState.currentTempo {
        case 0.5:
            return "½×"
        case 0.75:
            return "¾×"
        case 1.0:
            return "1×"
        case 1.5:
            return "1½×"
        case 2.0:
            return "2×"
        default:
            return "1×"
        }
    }
    
    func getArtSize() -> CGFloat {
        if self.optionsShowing {
            return 64.0
        } else if self.playbackState.isNowPlaying {
            if self.showsHandle {
                return 288.0
            } else {
                return 400.0
            }
        } else {
            if self.showsHandle {
                return 256.0
            } else {
                return 384.0
            }
        }
    }
}

struct NowPlayingView_Previews: PreviewProvider {
    static var previews: some View {
        NowPlayingView()
    }
}
