//
//  PhotoModeViewModel.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 20/12/21.
//

import Foundation
import SwiftUI

class PhotoModeViewModel: ObservableObject {
    var image: CGImage?
    @Published var isPreviewCreated: Bool = false
}
