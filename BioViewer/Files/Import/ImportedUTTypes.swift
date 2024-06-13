//
//  ImportedUTTypes.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 12/11/23.
//

import Foundation
import UniformTypeIdentifiers

extension UTType {
    static var pdbFiles: UTType {
        UTType(importedAs: "com.raulmonton.bioviewer.pdb")
    }
    static var xyzFiles: UTType {
        UTType(importedAs: "com.raulmonton.bioviewer.xyz")
    }
    static var cifFiles: UTType {
        UTType(importedAs: "com.raulmonton.bioviewer.cif")
    }
}
