//
//  PhotoModeConfig.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 20/12/21.
//

import Foundation

class PhotoModeConfig: ObservableObject {
    @Published var finalTextureSize: Int = 2048
    @Published var shadowTextureSize: Int = 8192
    @Published var clearBackground: Bool = true
}
