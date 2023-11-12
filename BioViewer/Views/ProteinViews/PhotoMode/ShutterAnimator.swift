//
//  ShutterAnimator.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 21/12/21.
//

import AVFoundation
import Foundation
import SwiftUI

@Observable class ShutterAnimator {
    
    // MARK: - UI Properties
    
    var shutterAnimationRunning: Bool = false
    var showImage: Bool = true
    var showFirstShutterCurtain: Bool = true
    var showSecondShutterCurtain: Bool = false
    var image: Image?
    var cgImage: CGImage? {
        didSet {
            if let cgImage {
                self.image = Image(cgImage, scale: 1.0, label: Text("BioViewer Image"))
            }
        }
    }
    
    // MARK: - Internal properties
            
    private var isShutterOpen: Bool = false
    private var shutterOpenPlayer: AVAudioPlayer?
    private var shutterClosedPlayer: AVAudioPlayer?
    
    // MARK: - Init
    init() {
        if let soundURL = Bundle.main.url(forResource: "ShutterOpen", withExtension: "aiff") {
            self.shutterOpenPlayer = try? AVAudioPlayer(
                contentsOf: soundURL,
                fileTypeHint: AVFileType.aiff.rawValue
            )
            self.shutterOpenPlayer?.volume = 0.1
        }
        if let soundURL = Bundle.main.url(forResource: "ShutterClosed", withExtension: "aiff") {
            self.shutterClosedPlayer = try? AVAudioPlayer(
                contentsOf: soundURL,
                fileTypeHint: AVFileType.aiff.rawValue
            )
            self.shutterClosedPlayer?.volume = 0.1
        }
    }
    
    // MARK: - Shutter feedback
    
    @MainActor func mirrorImpact() {
        let hapticFeedback = UIImpactFeedbackGenerator(style: .rigid)
        hapticFeedback.prepare()
        hapticFeedback.impactOccurred()
    }
    
    @MainActor func shutterCurtainImpact() {
        let hapticFeedback = UIImpactFeedbackGenerator(style: .light)
        hapticFeedback.prepare()
        
        hapticFeedback.impactOccurred()
    }
    
    // MARK: - Shutter sound
    func playShutterOpenSound() {
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
        self.shutterOpenPlayer?.play()
    }
    
    func playShutterClosedSound() {
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
        self.shutterClosedPlayer?.play()
    }
    
    // MARK: - Shutter animation
    
    func openShutter() async {
        
        shutterOpenPlayer?.prepareToPlay()
        shutterAnimationRunning = true
                
        if image == nil {
            // Image ('mirror') goes up
            withAnimation(.easeIn(duration: 0.15)) {
                showImage = false
            }
            
            // Wait for shutter to fully open
            try? await Task.sleep(for: .seconds(0.15))
            
            // Haptics
            await mirrorImpact()
            // Sound
            playShutterOpenSound()
            
            // First shutter curtain goes down after the image + delay
            try? await Task.sleep(for: .seconds(0.10))
            withAnimation(.easeIn(duration: 0.15)) {
                showFirstShutterCurtain = false
            }
            
            try? await Task.sleep(for: .seconds(0.15))
            await shutterCurtainImpact()
        } else {
            // First shutter curtain goes down
            withAnimation(.easeIn(duration: 0.15)) {
                showImage = false
                showFirstShutterCurtain = false
            }
            
            try? await Task.sleep(for: .seconds(0.15))
            
            // Haptics
            await shutterCurtainImpact()
            // Sound
            playShutterOpenSound()
        }
        self.isShutterOpen = true
    }
    
    func closeShutter(with cgImage: CGImage?) async {
        
        shutterClosedPlayer?.prepareToPlay()
        
        withAnimation(.easeInOut(duration: 0.15)) {
            showSecondShutterCurtain = true
            self.cgImage = cgImage
        }
        try? await Task.sleep(for: .seconds(0.15))
        
        // Haptics
        await shutterCurtainImpact()
        // Sound
        playShutterClosedSound()
        
        try? await Task.sleep(for: .seconds(0.10))
        withAnimation(.easeInOut(duration: 0.35)) {
            showImage = true
        }

        try? await Task.sleep(for: .seconds(0.35))
        await mirrorImpact()
        self.showFirstShutterCurtain = true
        self.showSecondShutterCurtain = false
        self.isShutterOpen = false
        self.shutterAnimationRunning = false
    }
}
