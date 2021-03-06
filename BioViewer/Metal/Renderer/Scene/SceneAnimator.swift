//
//  SceneAnimator.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 11/1/22.
//

import Foundation
import QuartzCore

class SceneAnimator {
    
    weak var scene: MetalScene?
    weak var bufferLoader: VisualizationBufferLoader?
    
    struct RunningAnimation {
        var initialTime: Double?
        var currentTime: Double
        let initialValue: Any
        let finalValue: Any
        let duration: Double
    }
    
    var displayLink: CADisplayLink?
    var radiiAnimation: RunningAnimation?
    var colorAnimation: RunningAnimation?
    var isBusy: Bool = false
    
    init(scene: MetalScene) {
        self.scene = scene
    }
    
    func animateRadiiChange(finalRadii: AtomRadii, duration: Double) {
        guard let scene = scene else { return }
        radiiAnimation = RunningAnimation(currentTime: CACurrentMediaTime(),
                                          initialValue: scene.frameData.atom_radii,
                                          finalValue: finalRadii,
                                          duration: duration)
        createDisplayLinkIfNeeded()
    }
    
    func animatedFillColorChange(initialColors: FillColorInput, finalColors: FillColorInput, duration: Double) {
        colorAnimation = RunningAnimation(currentTime: CACurrentMediaTime(),
                                          initialValue: initialColors,
                                          finalValue: finalColors,
                                          duration: duration)
        createDisplayLinkIfNeeded()
    }
    
    // MARK: - Private
    
    private func createDisplayLinkIfNeeded() {
        self.displayLink = CADisplayLink(target: self, selector: #selector(updateAllAnimations))
        displayLink?.add(to: .main, forMode: .default)
    }
    
    private func getAnimationProgress(animation: inout RunningAnimation?) -> Double {
        if let initialTime = animation?.initialTime {
            guard let animation = animation else {
                NSLog("Error in animation")
                return 0.0
            }
            return max(0.0, min(1.0, (animation.currentTime - initialTime) / animation.duration ))
        } else {
            animation?.initialTime = CACurrentMediaTime()
            return 0.0
        }
    }
    
    @objc private func updateAllAnimations() {
        guard !isBusy else { return }
        isBusy = true
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if self.radiiAnimation != nil {
                self.updateRadiiAnimation()
            }
            if self.colorAnimation != nil {
                self.updateColorAnimation()
            }
            self.isBusy = false
        }
    }
    
    // MARK: - Update animations
    
    private func updateRadiiAnimation() {
        
        self.radiiAnimation?.currentTime = CACurrentMediaTime()

        guard let scene = scene else {
            return
        }
        guard let radiiAnimation = radiiAnimation else {
            return
        }
        guard let initialRadii = radiiAnimation.initialValue as? AtomRadii else {
            return
        }
        guard let finalRadii = radiiAnimation.finalValue as? AtomRadii else {
            return
        }
        
        let progress = getAnimationProgress(animation: &self.radiiAnimation)
                
        scene.frameData.atom_radii = AtomRadiiGenerator.interpolatedRadii(initial: initialRadii, final: finalRadii, progress: Float(progress))
        
        bufferLoader?.populateImpostorSphereBuffers(atomRadii: scene.frameData.atom_radii)
        
        if progress == 1 {
            self.radiiAnimation = nil
        }
    }
    
    private func updateColorAnimation() {
        
        self.colorAnimation?.currentTime = CACurrentMediaTime()
        
        guard let scene = scene else {
            return
        }
        guard let colorAnimation = colorAnimation else {
            return
        }
        guard let initialFill = colorAnimation.initialValue as? FillColorInput else {
            return
        }
        guard let finalFill = colorAnimation.finalValue as? FillColorInput else {
            return
        }
        
        let progress = getAnimationProgress(animation: &self.colorAnimation)
        
        scene.colorFill = FillColorInputUtility.interpolateFillColorInput(start: initialFill,
                                                                          end: finalFill,
                                                                          fraction: Float(progress))
        if progress >= 1 {
            scene.colorFill = finalFill
            self.colorAnimation = nil
        }
    }

}
