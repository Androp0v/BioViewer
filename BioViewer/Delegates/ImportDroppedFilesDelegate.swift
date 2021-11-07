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

/// Class to handle importing dropped files into the protein view.
/// Should be able to read .pdb files.
class ImportDroppedFilesDelegate: DropDelegate {

    // MARK: - Properties

    public var proteinViewModel: ProteinViewModel?

    // MARK: - Handle drag & drop events

    func performDrop(info: DropInfo) -> Bool {

        guard let itemProvider = info.itemProviders(for: [.data,
                                                          .item]).first else {
            NSLog("No itemProvider available for the given type.")
            return false
        }

        guard let typeIdentifier = itemProvider.registeredTypeIdentifiers.first else {
            NSLog("Item provider has no associated type identifier.")
            return false
        }

        itemProvider.loadDataRepresentation(forTypeIdentifier: typeIdentifier) { data, error in

            guard let data = data else { return }

            // Retrieve UTI name from the NSItemProvider
            let nameUTI = itemProvider.registeredTypeIdentifiers.first

            // Decode file extension if the data has a dynamic UTI type
            var fileExtension: String?

            if let nameUTI = nameUTI, nameUTI.starts(with: "dyn.a") {
                fileExtension = self.decodeDynamicUTI(uti: nameUTI)
            }

            // Try to read the input file as a UTF-8 string
            let rawFileText = String(decoding: data, as: UTF8.self)

            // Parse file
            self.parseTextFile(rawText: rawFileText, fileExtension: fileExtension)
        }

        return true
    }

    // MARK: - Parse files

    func parseTextFile(rawText: String, fileExtension: String?) {

        if fileExtension == "pdb"
            || fileExtension == "PDB"
            || fileExtension == "pdb1"
            || fileExtension == "PDB1"
            || fileExtension == nil {
            // If the file has a known .pdb extension, or we don't
            // know the extension, try opening it as a PDB file.
            proteinViewModel?.statusUpdate(statusText: "Importing file")
            do {
                var protein = try parsePDB(rawText: rawText, proteinViewModel: proteinViewModel)
                proteinViewModel?.dataSource.addProteinToDataSource(protein: &protein, addToScene: true)
            } catch {
                proteinViewModel?.statusFinished(withError: NSLocalizedString("Error importing file", comment: ""))
            }
            
        } else {
            // TO-DO: Open other file types
            fatalError("Not implemented!")
        }
    }

    // MARK: - Dynamic UTI decoding

    // FROM https://gist.github.com/jtbandes/19646e7457208ae9b1ad
    // There's no obvious way to recover the dropped file UTI for
    // pdb files other than reverse engineering how Apple generates
    // dynamic UTIs from file extensions.
    func decodeDynamicUTI(uti: String) -> String? {
        let vec = Array("abcdefghkmnpqrstuvwxyz0123456789")

        let encoded = Array(uti).suffix(from: 5)
        var result: [UInt8] = []
        var decoded = 0
        var decodedBits = 0
        for char in encoded {
            // Each encoded character represents 5 bits (by its
            // position in the length-32 vector).
            guard let pos = vec.firstIndex(of: char) else {
                print("Unrecognized encoded character '\(char)'")
                return nil
            }
            decoded = (decoded << 5) | pos
            decodedBits += 5

            // Every 8 decoded bits represent a UTF-8 code unit.
            if decodedBits >= 8 {
                let extra = decodedBits - 8
                result.append(UInt8(decoded >> extra))
                decoded &= (1 << extra) - 1
                decodedBits = extra
            }
        }

        if decoded != 0 {
            print("\(decodedBits) leftover bits: \(decoded)")
            return nil
        }

        let decodedString = String(decoding: result, as: UTF8.self)

        // Decoded string looks like "?0=6:1=pdb" for pdb files, we're
        // only interested in the extension.
        let fileExtension = decodedString.split(separator: "=").last

        // Dismiss nil results
        guard let fileExtension = fileExtension else { return nil }

        // Return the extracted file extension
        return String(fileExtension)
    }

}
