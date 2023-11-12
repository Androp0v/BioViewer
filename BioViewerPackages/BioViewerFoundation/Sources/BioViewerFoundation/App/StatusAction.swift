//
//  StatusAction.swift
//
//
//  Created by Raúl Montón Pinillos on 12/11/23.
//

import Foundation

public enum StatusActionType {
    case importFile
    case geometryGeneration
    
    public var title: String {
        switch self {
        case .importFile:
            return "Import file"
        case .geometryGeneration:
            return "Ball and stick"
        }
    }
    
    public var blocksRendering: Bool {
        switch self {
        case .importFile:
            true
        case .geometryGeneration:
            false
        }
    }
}

public struct StatusAction: Identifiable {
    public let id = UUID()
    public let type: StatusActionType
    public var description: String?
    public var progress: Double?
    public var error: Error?
    
    public init(type: StatusActionType, description: String? = nil, progress: Double? = nil, error: Error? = nil) {
        self.type = type
        self.description = description
        self.progress = progress
        self.error = error
    }
}
