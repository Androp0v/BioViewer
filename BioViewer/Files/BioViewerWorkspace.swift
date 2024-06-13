//
//  BioViewerWorkspace.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 6/12/21.
//

import Foundation

#if os(iOS)
import UIKit

class BioViewerWorkspace: UIDocument {
    
    // TO-DO: Saved contents
    var testContent = "Test"
    
    // MARK: - Inner files
    var infoFileName = "Info.txt"

    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        guard let topFileWrapper = contents as? FileWrapper,
            let textData = topFileWrapper.fileWrappers?[infoFileName]?.regularFileContents else {
                return
        }
        testContent = String(data: textData, encoding: .utf8)!
    }

    override func contents(forType typeName: String) throws -> Any {
        guard let workspaceData = testContent.data(using: .utf8) else {
            throw ExportError.unknownError
        }

        return FileWrapper(regularFileWithContents: workspaceData)
    }
}

/*
 class BioViewerWorkspaceDelegate: DocumentPickerDelegate {
 
 }
 */
#endif
