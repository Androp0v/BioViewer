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
    case notFound
    case downloadError
    case unknownFileExtension
    case unknownError
}

extension ImportError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .unknownFileType:
            return NSLocalizedString("Error: Unknown file type", comment: "")
        case .emptyAtomCount:
            return NSLocalizedString("Error: File does not contain any atom positions", comment: "")
        case .notFound:
            return NSLocalizedString("Error: File not found", comment: "")
        case .downloadError:
            return NSLocalizedString("Error downloading file", comment: "")
        case .unknownFileExtension:
            return NSLocalizedString("Unknown file extension", comment: "")
        case .unknownError:
            return NSLocalizedString("Error importing file", comment: "")
        }
    }
}
