//
//  DocumentPickerViewController.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 22/11/21.
//

import Foundation
import UIKit
import UniformTypeIdentifiers

class DocumentPickerViewController: UIDocumentPickerViewController {
    
}

class DocumentPickerDelegate: NSObject, UIDocumentPickerDelegate {
    
    var onDismiss: (() -> Void)?
    var onPick: ((URL) -> Void)?
        
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let onPick = onPick else {
            return
        }
        guard let url = urls.first else {
            return
        }
        onPick(url)
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        guard let onDismiss = onDismiss else {
            return
        }
        onDismiss()
    }
}

extension UTType {
    static var pdbFiles: UTType {
        UTType(importedAs: "com.raulmonton.bioviewer.pdb")
    }
}
