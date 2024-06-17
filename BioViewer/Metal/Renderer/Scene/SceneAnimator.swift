//
//  SceneAnimator.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 11/1/22.
//

import BioViewerFoundation
import Foundation
import QuartzCore

protocol RunningAnimation {
    var initialTime: Double? { get set }
    var currentTime: Double { get set }
    var initialValue: Any { get }
    var finalValue: Any { get }
    var duration: Double { get }
}

struct RadiiAnimation: RunningAnimation {
    var initialTime: Double?
    var currentTime: Double
    let initialValue: Any
    let finalValue: Any
    let duration: Double
    
    let colorBy: ProteinColorByOption
    let proteins: [Protein]
}
struct ColorAnimation: RunningAnimation {
    var initialTime: Double?
    var currentTime: Double
    let initialValue: Any
    let finalValue: Any
    let duration: Double
}

actor SceneAnimator {
    
    weak var renderer: ProteinRenderer?
    
    var displayLink: PlatformDisplayLink?
    var radiiAnimation: RadiiAnimation?
    var colorAnimation: ColorAnimation?
    var isBusy: Bool = false
    
    init() {
        Task {
            await startDisplayLink()
        }
    }
    
    func animateRadiiChange(
        renderer: ProteinRenderer,
        finalRadii: AtomRadii,
        duration: Double,
        colorBy: ProteinColorByOption,
        proteins: [Protein]
    ) async {
        self.renderer = renderer
        let initialAtomRadii = await renderer.getAtomRadii()
        radiiAnimation = RadiiAnimation(
            currentTime: CACurrentMediaTime(),
            initialValue: initialAtomRadii,
            finalValue: finalRadii,
            duration: duration, 
            colorBy: colorBy,
            proteins: proteins
        )
        resumeDisplayLinkIfNeeded()
    }
    
    func animatedFillColorChange(
        renderer: ProteinRenderer,
        initialColors: FillColorInput,
        finalColors: FillColorInput,
        duration: Double
    ) async {
        self.renderer = renderer
        colorAnimation = ColorAnimation(
            currentTime: CACurrentMediaTime(),
            initialValue: initialColors,
            finalValue: finalColors,
            duration: duration
        )
        resumeDisplayLinkIfNeeded()
    }
    
    // MARK: - Private
    
    private func startDisplayLink() {
        self.displayLink = PlatformDisplayLink {
            Task {
                await self.updateAllAnimations()
            }
        }
        displayLink?.add(to: .main, forMode: .default)
    }
    
    private func resumeDisplayLinkIfNeeded() {
        displayLink?.isPaused = false
    }
    private func pauseDisplayLinkIfNeeded() {
        guard radiiAnimation == nil else { return }
        guard colorAnimation == nil else { return }
        self.displayLink?.isPaused = true
    }
    
    private func getAnimationProgress(animation: inout some RunningAnimation) -> Double {
        if let initialTime = animation.initialTime {
            return max(0.0, min(1.0, (animation.currentTime - initialTime) / animation.duration ))
        } else {
            animation.initialTime = CACurrentMediaTime()
            return 0.0
        }
    }
    
    // MARK: - Update animations

    private func updateAllAnimations() async {
        guard !isBusy else { return }
        isBusy = true
        
        if self.radiiAnimation != nil {
            await self.updateRadiiAnimation()
        }
        if self.colorAnimation != nil {
            await self.updateColorAnimation()
        }
        self.isBusy = false
    }
        
    // MARK: - Radii animation
    
    private func updateRadiiAnimation() async {
        
        self.radiiAnimation?.currentTime = CACurrentMediaTime()

        guard let radiiAnimation = radiiAnimation else {
            return
        }
        guard let initialRadii = radiiAnimation.initialValue as? AtomRadii else {
            return
        }
        guard let finalRadii = radiiAnimation.finalValue as? AtomRadii else {
            return
        }
        
        let progress = getAnimationProgress(animation: &self.radiiAnimation!)
        let newRadii: AtomRadii = .interpolated(initial: initialRadii, final: finalRadii, progress: Float(progress))
        
        await renderer?.setAtomRadii(newRadii)
        await renderer?.sceneAnimatorCallback(
            atomRadii: newRadii,
            colorBy: radiiAnimation.colorBy,
            proteins: radiiAnimation.proteins
        )
        
        if progress >= 1 {
            self.radiiAnimation = nil
            pauseDisplayLinkIfNeeded()
        }
    }
    
    // MARK: - Color animation
    
    private func updateColorAnimation() async {
        
        self.colorAnimation?.currentTime = CACurrentMediaTime()

        guard let renderer else { return }
        guard let colorAnimation = colorAnimation else { return }
        guard let initialFill = colorAnimation.initialValue as? FillColorInput else { return }
        guard let finalFill = colorAnimation.finalValue as? FillColorInput else { return }
        
        let progress = getAnimationProgress(animation: &self.colorAnimation!)
        let newColorFill = FillColorInputUtility.interpolateFillColorInput(
            start: initialFill,
            end: finalFill,
            fraction: Float(progress)
        )
        await renderer.setColorFill(newColorFill)
        if progress >= 1 {
            await renderer.setColorFill(finalFill)
            self.colorAnimation = nil
            pauseDisplayLinkIfNeeded()
        }
    }

}
