//
//  File.swift
//  
//
//  Created by Raúl Montón Pinillos on 12/11/23.
//

import Foundation

public enum XYZParserError: Error {
    case noConfiguration
    case emptyAtomCount
}

extension XYZParserError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .noConfiguration:
            return NSLocalizedString("There are no configurations in this file", comment: "")
        case .emptyAtomCount:
            return NSLocalizedString("Error: File does not contain any atom positions", comment: "")
        }
    }
}
