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
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<FilePicker>) -> UIDocumentPickerViewController {
        let documentTypes: [String] = [kUTTypeZipArchive as String, "com.abusman.nsf", "com.abusman.ay", "com.abusman.gbs", "com.abusman.gym", "com.abusman.hes", "com.abusman.kss", "com.abusman.sap", "com.abusman.spc", "com.abusman.vgm"]

        let picker = UIDocumentPickerViewController(documentTypes: documentTypes, in: .import)
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
                if FileManager.default.fileExists(atPath: file.path) {
                    FileEngine.addFile(file, removeOriginal: true)
                }
            }
        }
    }
}


