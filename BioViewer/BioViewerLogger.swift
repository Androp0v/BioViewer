//
//  BioViewerLogger.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 11/5/22.
//

import Foundation
import os

class BioViewerLogger {

    static let shared = BioViewerLogger()
    
    private var rendererLogger = Logger(
        subsystem: "BioViewer",
        category: "ProteinRenderer"
    )
    private var computeSurfaceUtilityLogger = Logger(
        subsystem: "BioViewer",
        category: "ComputeSurfaceUtility"
    )
    
    private init() {
        
    }
    
    // MARK: - Functions
    func log(type: LogType, category: LogCategory, message: String) {
        
        #if DEBUG
        var logger: Logger
        switch category {
        case .computeSurfaceUtility:
            logger = computeSurfaceUtilityLogger
        case .proteinRenderer:
            logger = rendererLogger
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
