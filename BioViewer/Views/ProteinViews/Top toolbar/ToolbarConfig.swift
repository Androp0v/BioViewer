//
//  ToolbarConfig.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 19/12/21.
//

import Foundation

enum CameraControlTool {
    static let rotate: Int = 0
    static let move: Int = 1
}

class ToolbarConfig: ObservableObject {
    
    @Published var selectedTool: Int = CameraControlTool.rotate
}
