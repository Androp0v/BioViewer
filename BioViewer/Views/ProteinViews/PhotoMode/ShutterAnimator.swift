//
//  ShutterAnimator.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 21/12/21.
//

import AVFoundation
import Foundation
import SwiftUI

@MainActor class ShutterAnimator: ObservableObject {
    
    @Published var shutterAnimationRunning: Bool = false
    @Published var showImage: Bool = true
    @Published var showFirstShutterCurtain: Bool = true
    @Published var showSecondShutterCurtain: Bool = false
    
    weak var photoModeViewModel: PhotoModeViewModel?
        
    private var isShutterOpen: Bool = false
    var player: AVAudioPlayer!
    
    // MARK: - Shutter feedback
    
    func mirrorImpact() {
        let hapticFeedback = UIImpactFeedbackGenerator(style: .rigid)
        hapticFeedback.prepare()
        hapticFeedback.impactOccurred()
    }
    
    func shutterCurtainImpact() {
        let hapticFeedback = UIImpactFeedbackGenerator(style: .light)
        hapticFeedback.prepare()
        
        hapticFeedback.impactOccurred()
    }
    
    // MARK: - Shutter sound
    func playShutterOpenSound() {
        if let soundURL = Bundle.main.url(forResource: "ShutterOpen", withExtension: "aiff") {
            try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try? AVAudioSession.sharedInstance().setActive(true)

            self.player = try? AVAudioPlayer(contentsOf: soundURL, fileTypeHint: AVFileType.aiff.rawValue)
            self.player.volume = 0.1
            self.player?.prepareToPlay()
        }
        
        self.player?.play()
    }
    
    func playShutterClosedSound() {
        if let soundURL = Bundle.main.url(forResource: "ShutterClosed", withExtension: "aiff") {
            try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try? AVAudioSession.sharedInstance().setActive(true)

            self.player = try? AVAudioPlayer(contentsOf: soundURL, fileTypeHint: AVFileType.aiff.rawValue)
            self.player.volume = 0.1
            self.player?.prepareToPlay()
        }
        
        self.player?.play()
    }
    
    // MARK: - Shutter animation
    
    func openShutter() async {
        
        shutterAnimationRunning = true
        
        var shutterOpenAnimationTime: Double = 0
        
        if photoModeViewModel?.isPreviewCreated ?? false {
            // Image ('mirror') goes up
            withAnimation(.easeIn(duration: 0.15)) {
                showImage = false
            }
            
            // Wait for shutter to fully open
            try? await Task.sleep(for: .seconds(0.15))
            
            // Haptics
            mirrorImpact()
            // Sound
            playShutterOpenSound()
            
            // First shutter curtain goes down after the image + delay
            try? await Task.sleep(for: .seconds(0.10))
            withAnimation(.easeIn(duration: 0.15)) {
                showFirstShutterCurtain = false
            }
            
            try? await Task.sleep(for: .seconds(0.15))
            shutterCurtainImpact()
            
            // Total mirror + shutter animation time
            shutterOpenAnimationTime = 0.4
        } else {
            // First shutter curtain goes down
            withAnimation(.easeIn(duration: 0.15)) {
                showImage = false
                showFirstShutterCurtain = false
            }
            
            try? await Task.sleep(for: .seconds(0.15))
            
            // Haptics
            shutterCurtainImpact()
            // Sound
            playShutterOpenSound()
            
            // Total shutter animation time
            shutterOpenAnimationTime = 0.15
        }
        
        try? await Task.sleep(for: .seconds(shutterOpenAnimationTime))
        self.isShutterOpen = true
    }
    
    func closeShutter() async {
        
        withAnimation(.easeInOut(duration: 0.15)) {
            showSecondShutterCurtain = true
        }
        try? await Task.sleep(for: .seconds(0.15))
        
        // Haptics
        shutterCurtainImpact()
        // Sound
        playShutterClosedSound()
        
        try? await Task.sleep(for: .seconds(0.10))
        withAnimation(.easeInOut(duration: 0.15)) {
            showImage = true
        }

        try? await Task.sleep(for: .seconds(0.15))
        mirrorImpact()
        self.showFirstShutterCurtain = true
        self.showSecondShutterCurtain = false
        self.isShutterOpen = false
        self.shutterAnimationRunning = false
    }
}
