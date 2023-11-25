//
//  ProteinFile.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 6/12/21.
//

import Foundation

// MARK: - ProteinFileType

public enum ProteinFileType: Sendable {
    case staticStructure
    case dynamicStructure
}

// MARK: - ProteinFile

public struct ProteinFile: Hashable, Sendable {
    
    /// Unique ID for the file (only used internally).
    public let id = UUID()
    /// The type of protein file type (whether it contains a static structure or several configurations of the same protein).
    public let fileType: ProteinFileType
    /// Name of the protein file.
    public let fileName: String
    /// Extension of the protein file (.pdb, .cif...).
    public let fileExtension: String
    /// Size of the stored file, in bytes.
    public let byteSize: Int?
    /// File metadata.
    public let fileInfo: ProteinFileInfo
    /// Protein contained in the file.
    public var models: [Protein]
    
    // MARK: - Init
    
    public init(fileType: ProteinFileType, fileName: String, fileExtension: String, models: [Protein], fileInfo: ProteinFileInfo, byteSize: Int?) {
        self.fileType = fileType
        self.fileName = fileName
        self.fileExtension = fileExtension
        self.models = models
        self.fileInfo = fileInfo
        self.byteSize = byteSize
    }
    
    // MARK: - Hashable
    
    public static func == (lhs: ProteinFile, rhs: ProteinFile) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
