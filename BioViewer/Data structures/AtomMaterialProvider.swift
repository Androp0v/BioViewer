//
//  AtomMaterialProvider.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 12/5/21.
//

import Foundation
import SceneKit

class AtomMaterialProvider {

    let carbonMaterial: SCNMaterial
    let nitrogenMaterial: SCNMaterial
    let oxygenMaterial: SCNMaterial
    let sulfurMaterial: SCNMaterial
    let defaultMaterial: SCNMaterial

    init() {
        // Material initialization
        self.carbonMaterial = SCNMaterial()
        self.nitrogenMaterial = SCNMaterial()
        self.oxygenMaterial = SCNMaterial()
        self.sulfurMaterial = SCNMaterial()
        self.defaultMaterial = SCNMaterial()

        // Common material setup
        self.carbonMaterial.lightingModel = .blinn
        self.carbonMaterial.reflective.contents = UIColor.black
        self.carbonMaterial.reflective.intensity = 1

        self.nitrogenMaterial.lightingModel = .blinn
        self.nitrogenMaterial.reflective.contents = UIColor.black
        self.nitrogenMaterial.reflective.intensity = 1

        self.oxygenMaterial.lightingModel = .blinn
        self.oxygenMaterial.reflective.contents = UIColor.black
        self.oxygenMaterial.reflective.intensity = 1

        self.sulfurMaterial.lightingModel = .blinn
        self.sulfurMaterial.reflective.contents = UIColor.black
        self.sulfurMaterial.reflective.intensity = 1

        self.defaultMaterial.lightingModel = .blinn
        self.defaultMaterial.reflective.contents = UIColor.black
        self.defaultMaterial.reflective.intensity = 1

        // Color configuration
        self.carbonMaterial.diffuse.contents = UIColor(red: 0, green: 1, blue: 0, alpha: 1.0)
        self.nitrogenMaterial.diffuse.contents = UIColor(red: 0, green: 0, blue: 1, alpha: 1.0)
        self.oxygenMaterial.diffuse.contents = UIColor(red: 1, green: 0, blue: 0, alpha: 1.0)
        self.oxygenMaterial.diffuse.contents = UIColor(red: 1, green: 0.368, blue: 0.074, alpha: 1.0)
        self.defaultMaterial.diffuse.contents = UIColor.gray
    }

}
