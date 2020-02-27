//
//  FilePicker.swift
//  Square Wave
//
//  Created by Alex Busman on 2/13/20.
//  Copyright © 2020 Alex Busman. All rights reserved.
//

import SwiftUI
import MobileCoreServices

struct FilePicker: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    
    var folderType: Bool
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<FilePicker>) -> UIDocumentPickerViewController {
        var documentTypes: [String] = []
        if folderType {
            documentTypes = [kUTTypeFolder as String]
        } else {
            documentTypes = [kUTTypeZipArchive as String, "com.abusman.nsf"]
        }
        let picker = UIDocumentPickerViewController(documentTypes: documentTypes, in: folderType ? .open : .import)
        picker.allowsMultipleSelection = true
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: UIViewControllerRepresentableContext<FilePicker>) {
        
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIDocumentPickerDelegate {
        var parent: FilePicker
        
        init(_ parent: FilePicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            for file in urls {
                FileEngine.addFile(file)
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
