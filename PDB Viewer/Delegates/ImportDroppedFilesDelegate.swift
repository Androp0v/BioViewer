//
//  ImportDroppedFiles.swift
//  PDB Viewer
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

    private var sceneDelegate: ProteinViewSceneDelegate

    // MARK: - Initialization

    init(sceneDelegate: ProteinViewSceneDelegate) {
        self.sceneDelegate = sceneDelegate
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

        var atomArray = [simd_float3]()
        var atomIdentifiers = [Int]()

        rawText.enumerateLines(invoking: { line, stop in
            // We're only interested in the lines that contain atom positions
            if line.contains("ATOM") {
                // Split the lines by column, in .pdb files x, y, z coordinates
                // are on the 6, 7, 8 columns
                let columns = line.split(separator: " ",
                                         maxSplits: Int.max,
                                         omittingEmptySubsequences: true)
                // Avoid index out of range errors
                guard columns.count > 9 else { return }
                // Retrieve x, y, z data
                guard let x = Float(columns[6]),
                      let y = Float(columns[7]),
                      let z = Float(columns[8])
                else { return }
                // Save atom position to array
                atomArray.append(simd_float3(x,y,z))
                // Retrieve atom element
                let element = columns[2]
                // Save atom element to array
                atomIdentifiers.append( getAtomId(atomName: String(element)) )
            }
        })

        sceneDelegate.addProtein(atoms: atomArray, atomIdentifiers: atomIdentifiers)

    }

}
