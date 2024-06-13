//
//  PlatformDisplayLink.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 13/6/24.
//

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

final class PlatformDisplayLink {
    
    private var link: CADisplayLink!
    
    var isPaused: Bool {
        get {
            return link.isPaused
        }
        set {
            link.isPaused = newValue
        }
    }
    
    var preferredFrameRateRange: CAFrameRateRange? {
        didSet { 
            #if os(iOS)
            if let preferredFrameRateRange {
                self.link.preferredFrameRateRange = preferredFrameRateRange
            }
            #endif
        }
    }
    
    let callback: () -> Void
    
    // MARK: - Init
    
    #if os(iOS)
    init(callback: @escaping @Sendable () -> Void) {
        self.callback = callback
        self.link = CADisplayLink(
            target: self,
            selector: #selector(self.executeCallback)
        )
    }
    #elseif os(macOS)
    init(in screen: NSScreen? = nil, callback: @escaping @Sendable () -> Void) {
        self.callback = callback
        self.link = (screen ?? NSScreen.main!).displayLink(
            target: self,
            selector: #selector(self.executeCallback)
        )
    }
    #endif
    
    // MARK: - Methods
    
    func add(to runLoop: RunLoop, forMode mode: RunLoop.Mode) {
        self.link.add(to: runLoop, forMode: mode)
    }
    
    func remove(from runLoop: RunLoop, forMode mode: RunLoop.Mode) {
        self.link.remove(from: runLoop, forMode: mode)
    }
    
    // MARK: - Private
    
    @objc private func executeCallback() {
        callback()
    }
}
