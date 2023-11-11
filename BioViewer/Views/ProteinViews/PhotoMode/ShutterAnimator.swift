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
    var shutterOpenPlayer: AVAudioPlayer?
    var shutterClosedPlayer: AVAudioPlayer?
    
    // MARK: - Init
    init() {
        Task{ @MainActor [weak self] in
            guard let self else { return }
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
    }
    
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
        }
        self.isShutterOpen = true
    }
    
    func closeShutter() async {
        
        shutterClosedPlayer?.prepareToPlay()
        
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
