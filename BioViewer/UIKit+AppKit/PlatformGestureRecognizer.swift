//
//  PlatformGestureRecognizer.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 13/6/24.
//

protocol PlatformPanGestureRecognizer {
    @MainActor var stateChanged: Bool { get }
    @MainActor func velocity(in view: PlatformView?) -> CGPoint
}

#if os(iOS)
import UIKit

extension UIPanGestureRecognizer: PlatformPanGestureRecognizer {
    var stateChanged: Bool {
        return self.state == .changed
    }
}
#elseif os(macOS)
import AppKit

extension NSPanGestureRecognizer: PlatformPanGestureRecognizer {
    nonisolated var stateChanged: Bool {
        MainActor.assumeIsolated {
            return self.state == .changed
        }
    }
}
#endif
