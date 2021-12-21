//
//  ShutterAnimator.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 21/12/21.
//

import AVFoundation
import Foundation
import SwiftUI
import UIKit

class ShutterAnimator: ObservableObject {
    
    @Published var shutterAnimationRunning: Bool = false
    @Published var showImage: Bool = true
    @Published var showFirstShutterCurtain: Bool = true
    @Published var showSecondShutterCurtain: Bool = false
    
    weak var photoModeViewModel: PhotoModeViewModel?
    
    // Shutter is initially closed.
    var shutterOpenSemaphore = DispatchSemaphore(value: 0)
    var shutterClosedSemaphore = DispatchSemaphore(value: 1)
    
    private var isShutterOpen: Bool = false
    var player: AVAudioPlayer!
    
    // MARK: - Shutter feedback
    
    func mirrorImpact(after: DispatchTime) {
        let hapticFeedback = UIImpactFeedbackGenerator(style: .rigid)
        hapticFeedback.prepare()
        
        DispatchQueue.main.asyncAfter(deadline: after) {
            hapticFeedback.impactOccurred()
        }
    }
    
    func shutterCurtainImpact(after: DispatchTime) {
        let hapticFeedback = UIImpactFeedbackGenerator(style: .light)
        hapticFeedback.prepare()
        
        DispatchQueue.main.asyncAfter(deadline: after) {
            hapticFeedback.impactOccurred()
        }
    }
    
    // MARK: - Shutter sound
    func playShutterOpenSound(after: DispatchTime) {
        if let soundURL = Bundle.main.url(forResource: "ShutterOpen", withExtension: "aiff") {
            try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try? AVAudioSession.sharedInstance().setActive(true)

            self.player = try? AVAudioPlayer(contentsOf: soundURL, fileTypeHint: AVFileType.aiff.rawValue)
            self.player.volume = 0.1
            self.player?.prepareToPlay()
        }
        
        DispatchQueue.global(qos: .userInteractive).asyncAfter(deadline: after) {
            self.player?.play()
        }
    }
    
    func playShutterClosedSound(after: DispatchTime) {
        if let soundURL = Bundle.main.url(forResource: "ShutterClosed", withExtension: "aiff") {
            try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try? AVAudioSession.sharedInstance().setActive(true)

            self.player = try? AVAudioPlayer(contentsOf: soundURL, fileTypeHint: AVFileType.aiff.rawValue)
            self.player.volume = 0.1
            self.player?.prepareToPlay()
        }
        
        DispatchQueue.global(qos: .userInteractive).asyncAfter(deadline: after) {
            self.player?.play()
        }
    }
    
    // MARK: - Shutter animation
    
    func openShutter() {
        
        shutterAnimationRunning = true
        
        // Wait until shutter is fully closed to start opening animation
        _ = shutterClosedSemaphore.wait(timeout: .distantFuture)

        var shutterOpenAnimationTime: Double = 0
        
        if photoModeViewModel?.isPreviewCreated ?? false {
            // Image ('mirror') goes up
            withAnimation(.easeIn(duration: 0.15)) {
                showImage = false
            }
            mirrorImpact(after: .now() + 0.15)
            
            // Sound
            playShutterOpenSound(after: .now() + 0.15)
            
            // First shutter curtain goes down after the image + delay
            withAnimation(.easeIn(duration: 0.15).delay(0.25)) {
                showFirstShutterCurtain = false
            }
            shutterCurtainImpact(after: .now() + 0.4)
            
            // Total mirror + shutter animation time
            shutterOpenAnimationTime = 0.4
        } else {
            // First shutter curtain goes down
            withAnimation(.easeIn(duration: 0.15)) {
                showImage = false
                showFirstShutterCurtain = false
            }
            shutterCurtainImpact(after: .now() + 0.15)
            
            // Sound
            playShutterOpenSound(after: .now() + 0.15)
            
            // Total shutter animation time
            shutterOpenAnimationTime = 0.15
        }
        
        DispatchQueue.global().asyncAfter(deadline: .now() + shutterOpenAnimationTime) {
            self.isShutterOpen = true
            self.shutterOpenSemaphore.signal()
        }
    }
    
    func closeShutter() {
        // Wait until shutter is fully closed to start opening animation
        _ = shutterOpenSemaphore.wait(timeout: .distantFuture)
        
        DispatchQueue.main.sync {
            withAnimation(.easeInOut(duration: 0.15)) {
                showSecondShutterCurtain = true
            }
            shutterCurtainImpact(after: .now() + 0.15)
            
            // Sound
            playShutterClosedSound(after: .now() + 0.15)
            
            withAnimation(.easeInOut(duration: 0.15).delay(0.25)) {
                showImage = true
            }
            mirrorImpact(after: .now() + 0.4)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.showFirstShutterCurtain = true
            self.showSecondShutterCurtain = false
            self.isShutterOpen = false
            self.shutterAnimationRunning = false
            self.shutterClosedSemaphore.signal()
        }
    }
}
