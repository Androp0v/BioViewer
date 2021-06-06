//
//  AppState.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 5/6/21.
//

import Foundation

class AppState {

    static let shared = AppState()

    // Use Metal or SceneKit for rendering proteins
    var useMetal: Bool = true
}
