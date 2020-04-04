//
//  MoreView.swift
//  Square Wave
//
//  Created by Alex Busman on 2/13/20.
//  Copyright © 2020 Alex Busman. All rights reserved.
//

import StoreKit
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
            view.selectRow(self.selections[i], inComponent: i, animated: true)
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
            if !((self.parent.selections[0] == 0 && row == 0 && component == 2) || (self.parent.selections[2] == 0 && row == 0 && component == 0)) {
                self.parent.selections[component] = row
            } else {
                self.parent.selections[0] = 0
                self.parent.selections[2] = 2
                self.parent.selections[2] = 1
            }
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
    var dismiss: (() -> Void)
    @EnvironmentObject var playbackState: PlaybackState
    @State var loopCount: Int = PlaybackStateProperty.loopCount.getProperty() ?? 2
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    var timesToChoose: [[String]] = [
        Array(0...20).map { "\($0)"},
        ["min"],
        Array(0...59).map { "\($0)"},
        ["sec"]
    ]
    @State var trackLength: [Int] = SettingsView.getTrackLength(from: PlaybackStateProperty.trackLength.getProperty() ?? 150000)
    @State var isShowingPicker = false
    @State var deleteShowing = false
    @State var iapFailureShowing = false
    @State var iapPrice = ""
    @State var iapProduct: SKProduct?
    @State var iapError = ""
    @State var purchased = false
    
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
                Section(footer: Text(NSLocalizedString("Track Length Description", comment: "Track Length Description")).font(.footnote)) {
                    Button(action: {self.isShowingPicker.toggle()}) {
                        HStack {
                            Text(NSLocalizedString("Track Length", comment: "Track Length"))
                            .foregroundColor(Color(.label))
                            Spacer()
                            Text(String(format: "%d:%02d", self.trackLength[0], self.trackLength[2]))
                                .foregroundColor(self.purchased ? Color(.label) : Color(.secondaryLabel))
                        }
                    }
                        .disabled(!self.purchased)
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
                Section(footer: Text(NSLocalizedString("Loop Count Description", comment: "Loop Count Description")).font(.footnote)) {
                    HStack {
                        Stepper(value: Binding(
                            get: {
                                self.loopCount
                            }, set: { (newValue) in
                                self.loopCount = newValue
                                PlaybackStateProperty.loopCount.setProperty(newValue: newValue)
                            }), in: 1...20) {
                            HStack {
                                Text(NSLocalizedString("Loop Count", comment: "Loop Count"))
                                .foregroundColor(Color(.label))
                                Spacer()
                                Text("\(self.loopCount)")
                                .foregroundColor(self.purchased ? Color(.label) : Color(.secondaryLabel))
                            }
                        }.disabled(!self.purchased)
                    }
                }
                Section(footer: self.purchased ? Text("") : Text(String.localizedStringWithFormat(NSLocalizedString("Upgrade Description %@", comment: "Upgrade Description"), "\(self.playbackState.playCountLimit)")).font(.footnote)) {
                    if !self.purchased {
                        Button(action: {
                            guard let product = self.iapProduct else { return }
                            self.purchase(product: product)
                        }) {
                            HStack {
                                Text(NSLocalizedString("Upgrade", comment: "Upgrade"))
                                Spacer()
                                Text("\(self.iapPrice)")
                            }
                        }
                        Button(action: {
                            self.restorePurchases()
                        }) {
                            Text(NSLocalizedString("Restore Purchases", comment: "Restore Purchases"))
                        }
                    } else {
                        Text(NSLocalizedString("Upgrade Purchased", comment: "Upgrade Purchased"))
                            .foregroundColor(Color(.secondaryLabel))
                    }
                }.alert(isPresented: self.$iapFailureShowing) {
                    Alert(title: Text(NSLocalizedString("Error", comment: "Error")), message: Text(String.localizedStringWithFormat(NSLocalizedString("Purchase Error Description", comment: "Purchase Error Description %@"), self.iapError)), dismissButton: Alert.Button.cancel(Text(NSLocalizedString("Okay", comment: "Okay"))))
                }
                Section {
                    Button(action: {
                        UINotificationFeedbackGenerator().notificationOccurred(.warning)
                        self.deleteShowing.toggle()
                    }) {
                        Text(NSLocalizedString("Delete All", comment: "Delete All"))
                    }.foregroundColor(.red)
                }.navigationBarTitle(Text(NSLocalizedString("Settings", comment: "Settings")), displayMode: .inline)
                    .navigationBarItems(trailing: Button(action: self.dismiss) {
                        Text(NSLocalizedString("Done", comment: "Done")).bold()
                })
                #if DEBUG
                Section(footer: Text("DEBUG OPTIONS")) {
                    Button(action: {
                        self.purchased.toggle()
                        PlaybackStateProperty.purchased.setProperty(newValue: self.purchased)
                        if self.purchased {
                            self.playbackState.restricted = false
                            self.playbackState.purchased = true
                        } else {
                            self.playbackState.purchased = false
                        }
                    }) {
                        Text("Toggle purchased")
                    }
                }
                #endif
            }
        }.alert(isPresented: self.$deleteShowing) {
            Alert(title: Text(NSLocalizedString("Delete All Question", comment: "Delete All Question")), message: Text(NSLocalizedString("Delete All Description", comment: "Delete All Description")), primaryButton: .destructive(Text(NSLocalizedString("Delete All Confirm", comment: "Delete All Confirmation"))) {
                    self.playbackState.clearCurrentPlaybackState()
                    FileEngine.clearAll()
                    }, secondaryButton: .cancel())
        }.navigationViewStyle(StackNavigationViewStyle())
            .onAppear {
                self.purchased = Util.getPurchased()
                self.getPurchasePrice()
        }
    }
    
    private func showIAPError(_ error: Error) {
        self.iapError = error.localizedDescription
        self.iapFailureShowing = true
    }
    
    @discardableResult private func purchase(product: SKProduct) -> Bool {
        if !IAPManager.shared.canMakePayments() {
            self.iapError = "Account cannot make payments"
            self.iapFailureShowing = true
            return false
        } else {
            IAPManager.shared.buy(product: product) { (result) in
                DispatchQueue.main.async {
                    switch result {
                    case .success(_):
                        PlaybackStateProperty.purchased.setProperty(newValue: true)
                        AppDelegate.playbackState.restricted = false
                        AppDelegate.playbackState.purchased = true
                        self.purchased = true
                    case .failure(let error): self.showIAPError(error)
                    }
                }
            }
            return true
        }
    }
    
    private func restorePurchases() {
        IAPManager.shared.restorePurchases { (result) in
            DispatchQueue.main.async {
                switch result {
                case .success(let success):
                    if success {
                        PlaybackStateProperty.purchased.setProperty(newValue: true)
                        AppDelegate.playbackState.restricted = false
                        self.purchased = true
                    } else {
                        NSLog("No products to be restored")
                    }

                case .failure(let error): self.showIAPError(error)
                }
            }
        }
    }
    
    private func getPurchasePrice() {
        IAPManager.shared.getProducts { (result) in
            switch result {
            case .success(let products):
                if products.count == 1 {
                    self.iapProduct = products.first
                    self.iapPrice = IAPManager.shared.getPriceFormatted(for: products.first!) ?? ""
                }
            case .failure(let error):
                NSLog("Failed to get in-app products: \(error.localizedDescription)")
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(dismiss: {})
    }
}
