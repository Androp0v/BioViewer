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
        var currentTime: Double
        let initialTime: Double
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
                                          initialTime: CACurrentMediaTime(),
                                          initialValue: scene.frameData.atom_radii,
                                          finalValue: finalRadii,
                                          duration: duration)
        createDisplayLinkIfNeeded()
    }
    
    // MARK: - Private
    
    private func createDisplayLinkIfNeeded() {
        self.displayLink = CADisplayLink(target: self, selector: #selector(updateAllAnimations))
        displayLink?.add(to: .main, forMode: .default)
    }
    
    private func getAnimationProgress(animation: RunningAnimation) -> Double {
        return max(0.0, min(1.0, (animation.currentTime - animation.initialTime) / animation.duration ))
    }
    
    @objc private func updateAllAnimations() {
        guard !isBusy else { return }
        isBusy = true
        
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            guard let self = self else { return }
            if self.radiiAnimation != nil {
                self.updateRadiiAnimation()
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
        
        let progress = getAnimationProgress(animation: radiiAnimation)
                
        scene.frameData.atom_radii.atomRadius.0 = (finalRadii.atomRadius.0 - initialRadii.atomRadius.0) * Float(progress) + initialRadii.atomRadius.0
        scene.frameData.atom_radii.atomRadius.1 = (finalRadii.atomRadius.1 - initialRadii.atomRadius.1) * Float(progress) + initialRadii.atomRadius.1
        scene.frameData.atom_radii.atomRadius.2 = (finalRadii.atomRadius.2 - initialRadii.atomRadius.2) * Float(progress) + initialRadii.atomRadius.2
        scene.frameData.atom_radii.atomRadius.3 = (finalRadii.atomRadius.3 - initialRadii.atomRadius.3) * Float(progress) + initialRadii.atomRadius.3
        scene.frameData.atom_radii.atomRadius.4 = (finalRadii.atomRadius.4 - initialRadii.atomRadius.4) * Float(progress) + initialRadii.atomRadius.4
        scene.frameData.atom_radii.atomRadius.5 = (finalRadii.atomRadius.5 - initialRadii.atomRadius.5) * Float(progress) + initialRadii.atomRadius.5
        
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
        
        let progress = getAnimationProgress(animation: colorAnimation)
        if progress == 1 {
            self.colorAnimation = nil
        }
    }

}
