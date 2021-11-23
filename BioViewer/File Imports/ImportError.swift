//
//  ImportErrors.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 23/11/21.
//

import Foundation

enum ImportError: Error {
    case unknownFileType
    case emptyAtomCount
    case unknownError
}

extension ImportError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .unknownFileType:
            return NSLocalizedString("Error: Unknown file type", comment: "")
        case .emptyAtomCount:
            return NSLocalizedString("Error: File does not contain any atom positions", comment: "")
        case .unknownError:
            return NSLocalizedString("Error importing file", comment: "")
        }
    }
}
