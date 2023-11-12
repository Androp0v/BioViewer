//
//  File.swift
//  
//
//  Created by Raúl Montón Pinillos on 12/11/23.
//

import Foundation

public protocol StatusViewModelProtocol {
    func updateProgress(_ statusAction: StatusAction, progress: Double?)
}
