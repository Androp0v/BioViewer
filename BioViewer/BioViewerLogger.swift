//
//  BioViewerLogger.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 11/5/22.
//

import Foundation
import os

final class BioViewerLogger: Sendable {

    // MARK: - Properties
    
    private let rendererLogger = Logger(
        subsystem: "BioViewer",
        category: "ProteinRenderer"
    )
    private let computeSurfaceUtilityLogger = Logger(
        subsystem: "BioViewer",
        category: "ComputeSurfaceUtility"
    )
    
    // MARK: - Init
    
    private init() {}
    
    static let shared = BioViewerLogger()
    
    // MARK: - Functions
    
    func log(type: LogType, category: LogCategory, message: String) {
        
        #if DEBUG
        let logger = switch category {
        case .computeSurfaceUtility:
            computeSurfaceUtilityLogger
        case .proteinRenderer:
            rendererLogger
        }
        
        switch type {
        case .info:
            logger.info("\(message)")
        case .warning:
            logger.warning("\(message)")
        case .error:
            logger.critical("\(message)")
        }
        #endif
    }
    
}

enum LogType {
    case info
    case warning
    case error
}

enum LogCategory {
    case proteinRenderer
    case computeSurfaceUtility
}
