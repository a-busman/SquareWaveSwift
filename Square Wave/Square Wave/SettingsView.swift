//
//  MoreView.swift
//  Square Wave
//
//  Created by Alex Busman on 2/13/20.
//  Copyright © 2020 Alex Busman. All rights reserved.
//

import SwiftUI

struct PickerView: UIViewRepresentable {
    var data: [[String]]
    @Binding var selections: [Int]

    //makeCoordinator()
    func makeCoordinator() -> PickerView.Coordinator {
        Coordinator(self)
    }

    //makeUIView(context:)
    func makeUIView(context: UIViewRepresentableContext<PickerView>) -> UIPickerView {
        let picker = UIPickerView(frame: .zero)

        picker.dataSource = context.coordinator
        picker.delegate = context.coordinator

        return picker
    }

    //updateUIView(_:context:)
    func updateUIView(_ view: UIPickerView, context: UIViewRepresentableContext<PickerView>) {
        for i in 0...(self.selections.count - 1) {
            view.selectRow(self.selections[i], inComponent: i, animated: false)
        }
    }

    // MARK: Coordinator
    class Coordinator: NSObject, UIPickerViewDataSource, UIPickerViewDelegate {
        var parent: PickerView

        //init(_:)
        init(_ pickerView: PickerView) {
            self.parent = pickerView
        }

        //numberOfComponents(in:)
        func numberOfComponents(in pickerView: UIPickerView) -> Int {
            return self.parent.data.count
        }

        //pickerView(_:numberOfRowsInComponent:)
        func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
            return self.parent.data[component].count
        }

        //pickerView(_:didSelectRow:inComponent:)
        func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
            self.parent.selections[component] = row
        }
        
        func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
            let style = NSMutableParagraphStyle()
            if component % 2 == 1 {
                style.alignment = .left
            } else {
                style.alignment = .right
            }
            return NSAttributedString(string: self.parent.data[component][row], attributes: [NSAttributedString.Key.paragraphStyle : style])
        }
    }
}

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var playbackState: PlaybackState
    @State var loopCount = PlaybackStateProperty.loopCount.getProperty() ?? 2
    var timesToChoose: [[String]] = [
        Array(0...20).map { "\($0)"},
        ["min"],
        Array(0...59).map { "\($0)"},
        ["sec"]
    ]
    @State var trackLength: [Int] = SettingsView.getTrackLength(from: PlaybackStateProperty.trackLength.getProperty() ?? 150000)
    @State var isShowingPicker = false
    @Binding var isDisplayed: Bool
    
    static func getTrackLength(from ms: Int) -> [Int] {
        var ret: [Int] = []
        
        ret.append(ms / 60000)
        ret.append(0)
        ret.append((ms / 1000) % 60)
        ret.append(0)
        
        return ret
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(footer: Text("For tracks without loop information, you can choose how long you want the track to play for before moving on to the next track.")) {
                    Button(action: {self.isShowingPicker.toggle()}) {
                        HStack {
                            Text("Track Length")
                            Spacer()
                            Text(String(format: "%d:%02d", self.trackLength[0], self.trackLength[2]))
                        }
                    }.foregroundColor(Color(.label))
                    if self.isShowingPicker {
                        PickerView(data: self.timesToChoose, selections: Binding(
                            get: {
                                self.trackLength
                            }, set: { (newValue) in
                                self.trackLength = newValue
                                let value = (newValue[0] * 60000) + (newValue[2] * 1000)
                                PlaybackStateProperty.trackLength.setProperty(newValue: value)
                            }
                        ))
                    }
                }
                Section(footer: Text("For tracks with loop information, you can choose how many times you want the track to loop before moving on to the next track.")) {
                    HStack {
                        Stepper(value: Binding(
                            get: {
                                self.loopCount
                            }, set: { (newValue) in
                                self.loopCount = newValue
                                PlaybackStateProperty.loopCount.setProperty(newValue: newValue)
                            }), in: 0...20) {
                            HStack {
                                Text("Loop Count")
                                Spacer()
                                Text("\(self.loopCount)")
                            }
                        }
                    }
                }
                Section {
                    Button(action: {
                        self.playbackState.clearCurrentPlaybackState()
                        FileEngine.clearAll()
                    }) {
                        Text("Delete All")
                    }.foregroundColor(.red)
                }.navigationBarTitle("Settings", displayMode: .inline)
                    .navigationBarItems(trailing: Button(action: {
                        self.presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Done")
                })
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(isDisplayed: .constant(true))
    }
}
