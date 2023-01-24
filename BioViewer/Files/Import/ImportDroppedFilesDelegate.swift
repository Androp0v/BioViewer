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

    public weak var proteinViewModel: ProteinViewModel?

    // MARK: - Handle drag & drop events

    func performDrop(info: DropInfo) -> Bool {

        guard let itemProvider = info.itemProviders(for: [.data,
                                                          .item]).first else {
            self.proteinViewModel?.statusViewModel?.statusFinished(importError: ImportError.unknownFileType)
            NSLog("No itemProvider available for the given type.")
            return false
        }
        
        guard let proteinViewModel = proteinViewModel else {
            return false
        }

        // Try to obtain the type identifier as one of the explicitly supported typeIdentifiers in BioViewer
        var typeIdentifier = itemProvider.registeredTypeIdentifiers.first(where: { $0.starts(with: "com.raulmonton.bioviewer") })
        
        // Otherwise, try with whatever type is found
        if typeIdentifier == nil {
            typeIdentifier = itemProvider.registeredTypeIdentifiers.first
        }
        
        // Ensure that a type has been found at all
        guard let typeIdentifier = typeIdentifier else {
            self.proteinViewModel?.statusViewModel?.statusFinished(importError: ImportError.unknownFileType)
            NSLog("Item provider has no associated type identifier.")
            return false
        }

        itemProvider.loadDataRepresentation(forTypeIdentifier: typeIdentifier) { data, error in

            guard let data = data else {
                self.proteinViewModel?.statusViewModel?.statusFinished(importError: ImportError.unknownError)
                return
            }
            
            let itemProviderType = itemProvider.registeredTypeIdentifiers.first
            
            var fileName: String = NSLocalizedString("Unknown", comment: "")
            var fileExtension: String?
            
            if let fullFileName = itemProvider.suggestedName as NSString? {
                fileName = fullFileName.deletingPathExtension
                if !fullFileName.pathExtension.isEmpty {
                    // Prefer getting the file extension from the suggested file name.
                    fileExtension = fullFileName.pathExtension
                } else {
                    // If the suggested name foes not include the path extension, retrieve
                    // it from the ItemProvider type.
                    fileExtension = (itemProviderType as NSString?)?.pathExtension
                }
            }
            
            // Check that either the suggestedName or the itemProvider type have a valid path extension
            guard let fileExtension = fileExtension else {
                self.proteinViewModel?.statusViewModel?.statusFinished(importError: ImportError.unknownFileExtension)
                return
            }

            // Try to read the input file as a UTF-8 string
            let rawFileText = String(decoding: data, as: UTF8.self)
            
            // Get the file size
            let byteSize = (data as NSData).length

            // Parse file
            Task {
                guard let dataSource = proteinViewModel.dataSource else { return }
                guard let statusViewModel = proteinViewModel.statusViewModel else { return }
                try? await FileImporter.importFileFromRawText(
                    rawText: rawFileText,
                    proteinDataSource: dataSource,
                    statusViewModel: statusViewModel,
                    fileInfo: nil,
                    fileName: fileName,
                    fileExtension: fileExtension,
                    byteSize: byteSize
                )
            }
        }

        return true
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
