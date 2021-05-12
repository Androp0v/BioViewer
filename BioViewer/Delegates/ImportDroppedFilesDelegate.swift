//
//  ImportDroppedFiles.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 5/5/21.
//

import Foundation
import simd
import SwiftUI
import UniformTypeIdentifiers

/// Class to handle importing dropped files into the SceneKit view.
/// Should be able to read .pdb files.
class ImportDroppedFilesDelegate: DropDelegate {

    // MARK: - Properties

    private var dataSource: ProteinViewDataSource

    // MARK: - Initialization

    init(dataSource: ProteinViewDataSource) {
        self.dataSource = dataSource
    }

    // MARK: - Handle drag & drop events

    func performDrop(info: DropInfo) -> Bool {

        guard let itemProvider = info.itemProviders(for: [.data, .item, .fileURL]).first else {
            NSLog("No itemProvider available for the given type.")
            return false
        }

        guard let typeIdentifier = itemProvider.registeredTypeIdentifiers.first else {
            NSLog("Item provider has no associated type identifier.")
            return false
        }

        itemProvider.loadDataRepresentation(forTypeIdentifier: typeIdentifier) { data, error in
            guard let data = data else { return }
            // Try to read the input file as a UTF-8 string
            let rawFileText = String(decoding: data, as: UTF8.self)
            // Parse file
            self.parseTextFile(rawText: rawFileText)
        }

        return true
    }

    // MARK: - Parse files

    func parseTextFile(rawText: String) {
        let (atomArray, atomIdentifiers) = parsePDB(rawText: rawText)
        dataSource.addProteinToDataSource(atoms: atomArray, atomIdentifiers: atomIdentifiers, addToScene: true)
    }

}
