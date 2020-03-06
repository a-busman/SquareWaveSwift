//
//  TextView.swift
//  Square Wave
//
//  Created by Alex Busman on 3/1/20.
//  Copyright © 2020 Alex Busman. All rights reserved.
//

import SwiftUI

struct TextView: UIViewRepresentable {
    var title: String
    @Binding var text: String
    var placeholder = UILabel()

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UITextView {

        let myTextView = UITextView()
        myTextView.delegate = context.coordinator
        myTextView.isScrollEnabled = true
        myTextView.isEditable = true
        myTextView.isUserInteractionEnabled = true
        myTextView.backgroundColor = .clear
        myTextView.font = UIFont.preferredFont(forTextStyle: .headline)
        myTextView.returnKeyType = .done

        self.placeholder.text = self.title
        self.placeholder.textColor = .placeholderText
        self.placeholder.font = UIFont.preferredFont(forTextStyle: .headline)
        myTextView.addSubview(self.placeholder)
        
        self.placeholder.translatesAutoresizingMaskIntoConstraints = false
        self.placeholder.isUserInteractionEnabled = false

        self.placeholder.leadingAnchor.constraint(equalTo: myTextView.leadingAnchor, constant: 6).isActive = true
        self.placeholder.topAnchor.constraint(equalTo: myTextView.topAnchor, constant: 7.5).isActive = true
        return myTextView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {

    }

    class Coordinator : NSObject, UITextViewDelegate {

        var parent: TextView

        init(_ uiTextView: TextView) {
            self.parent = uiTextView
        }

        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            if text == "\n" {
                textView.resignFirstResponder()
                return false
            }
            return true
        }

        func textViewDidChange(_ textView: UITextView) {
            self.parent.text = textView.text

            if self.parent.text.isEmpty {
                self.parent.placeholder.isHidden = false
            } else {
                self.parent.placeholder.isHidden = true
            }
        }
    }
}

struct TextView_Previews: PreviewProvider {
    static var previews: some View {
        TextView(title: "Preview", text: .constant(""))
    }
}
