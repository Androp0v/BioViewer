//
//  WorkspaceExporter.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 6/12/21.
//

import Foundation
import UIKit

class WorkspaceExporter {
    
    static func createWorkspace(proteinViewModel: ProteinViewModel) {
        // Write to cache
        let cachesDir = FileManager.default.urls(for: FileManager.SearchPathDirectory.cachesDirectory, in: .allDomainsMask).first!
        let dataDir = cachesDir.appendingPathComponent("export", isDirectory: true)
        try? FileManager.default.createDirectory(at: dataDir, withIntermediateDirectories: true, attributes: nil)

        let fileURL = dataDir.appendingPathComponent("Workspace").appendingPathExtension("bioviewer")

        let archive = BioViewerWorkspace(fileURL: fileURL)
        archive.testContent = proteinViewModel.dataSource?.files.first?.fileInfo.pdbID ?? "Unknown PDB ID"
        
        Task {
            let success = await archive.save(to: archive.fileURL, for: .forCreating)
            
            await MainActor.run {
                guard success else {
                    return
                }

                let documentPicker = UIDocumentPickerViewController(forExporting: [fileURL])
                let delegate = BioViewerWorkspaceDelegate()
                documentPicker.delegate = delegate
                
                // TO-DO: Improve how the current window is located. This is a hacky workaround.
                for scene in UIApplication.shared.connectedScenes where scene.activationState == .foregroundActive {
                    guard let windowSceneDelegate = ((scene as? UIWindowScene)?.delegate as? UIWindowSceneDelegate) else {
                        return
                    }
                    guard let window = windowSceneDelegate.window else {
                        return
                    }
                    guard let rootViewController = window?.rootViewController else {
                        return
                    }
                    
                    rootViewController.present(documentPicker, animated: true)
                }
            }
        }
    }
}
