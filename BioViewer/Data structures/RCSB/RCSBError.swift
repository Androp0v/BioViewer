//
//  RCSBError.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 15/11/21.
//

import Foundation

enum RCSBError: Error {
    case invalidID
    case malformedURL
    case notFound
    case internalServerError
    case badImageData
    case malformedInput
    case unknown
}

extension RCSBError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidID, .malformedURL:
            // Malformed URLs are likely due to an invalid PDB ID. If there's another
            // cause, it's unlikely that the user has any other way to fix it.
            return NSLocalizedString("Invalid RCSB ID", comment: "")
        case .notFound:
            return NSLocalizedString("No structure found with the given RCSB ID", comment: "")
        case .internalServerError:
            return NSLocalizedString("There seems to be a problem with the server", comment: "")
        case .badImageData:
            return NSLocalizedString("Invalid image data", comment: "")
        case .malformedInput:
            return NSLocalizedString("Invalid input", comment: "")
        case .unknown:
            return NSLocalizedString("Unknown error", comment: "")
        }
    }
}
