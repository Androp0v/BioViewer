//
//  StatusAction.swift
//
//
//  Created by Raúl Montón Pinillos on 12/11/23.
//

import Foundation

enum StatusActionType: Sendable, Equatable {
    case importFile
    case geometryGeneration
    case benchmark(proteinName: String)
    
    var title: String {
        switch self {
        case .importFile:
            return "Import file"
        case .geometryGeneration:
            return "Ball and stick"
        case .benchmark(proteinName: let name):
            return "Benchmark \(name)"
        }
    }
    
    var blocksRendering: Bool {
        switch self {
        case .importFile:
            true
        case .geometryGeneration:
            false
        case .benchmark:
            false
        }
    }
}

struct StatusActionUI: Identifiable, Sendable {
    public let id: UUID
    public let type: StatusActionType
    public var description: String?
    public var progress: Double?
    public var error: Error?
    
    init(statusAction: StatusAction) {
        self.id = statusAction.id
        self.type = statusAction.type
        self.description = statusAction.description
        self.progress = statusAction.progress?.fractionCompleted
        self.error = statusAction.error
    }
}

struct StatusAction: Identifiable, Sendable {
    public let id = UUID()
    public let type: StatusActionType
    public var description: String?
    public var progress: Progress?
    public var error: Error?
    
    public init(type: StatusActionType, description: String? = nil, progress: Progress?, error: Error? = nil) {
        self.type = type
        self.description = description
        self.progress = progress
        self.error = error
    }
}
