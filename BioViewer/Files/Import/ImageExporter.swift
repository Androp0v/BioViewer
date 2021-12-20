//
//  ImageExporter.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 20/12/21.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

class ImageExporter {
    func showImageExportSheet(cgImage: CGImage?, preferredFileName: String?) {
        guard let cgImage = cgImage else {
            return
        }
        
        // Create image metadata
        let pngProperties = [
            // Software used to create the image
            kCGImagePropertyPNGSoftware as String: "BioViewer"
        ] as CFDictionary
        
        let properties = [
            kCGImagePropertyExifDictionary as String: pngProperties
        ] as CFDictionary
        
        // Write image to file
        guard let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            return
        }
        var filename: String = "BioViewer Image"
        if let preferredFileName = preferredFileName {
            filename = preferredFileName
        }
        let fileURL = cacheDirectory.appendingPathComponent("\(filename).png")
        
        guard let imageDestination = CGImageDestinationCreateWithURL(fileURL as CFURL,
                                                                     "public.png" as CFString,
                                                                     1,
                                                                     nil) else {
            return
        }
        CGImageDestinationAddImage(imageDestination, cgImage, properties)
        CGImageDestinationFinalize(imageDestination)
        
        // TO-DO: Improve how the current window is located. This is a hacky workaround.
        for scene in UIApplication.shared.connectedScenes where scene.activationState == .foregroundActive {
            guard let windowSceneDelegate = ((scene as? UIWindowScene)?.delegate as? UIWindowSceneDelegate) else {
                return
            }
            guard let window = windowSceneDelegate.window else {
                return
            }
            guard let presentedViewController = window?.rootViewController?.presentedViewController else {
                return
            }
            let shareSheet = UIActivityViewController(activityItems: [fileURL],
                                                      applicationActivities: nil)
            presentedViewController.present(shareSheet, animated: true)
        }
    }
}
