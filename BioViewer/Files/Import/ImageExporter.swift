//
//  ImageExporter.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 20/12/21.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct ExportableImage: Transferable {
    
    let cgImage: CGImage?
    let preferredFileName: String?
    
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { @MainActor exportableImage in
            return try ImageExporter().actuallyExportImage(
                cgImage: exportableImage.cgImage,
                preferredFileName: exportableImage.preferredFileName
            )
        }
    }
}

class ImageExporter {
    
    func actuallyExportImage(cgImage: CGImage?, preferredFileName: String?) throws -> Data {
        guard let cgImage = cgImage else {
            throw ExportError.unknownError
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
            throw ExportError.unknownError
        }
        var filename: String = "BioViewer Image"
        if let preferredFileName = preferredFileName {
            filename = preferredFileName
        }
        let fileURL = cacheDirectory.appendingPathComponent("\(filename).png")
        
        let imageDestination = CGImageDestinationCreateWithURL(
            fileURL as CFURL,
            "public.png" as CFString,
            1,
            nil
        )
        guard let imageDestination else {
            throw ExportError.unknownError
        }
        CGImageDestinationAddImage(imageDestination, cgImage, properties)
        CGImageDestinationFinalize(imageDestination)
        return try Data(contentsOf: fileURL)
    }
    
    func createExportableImage(cgImage: CGImage?, preferredFileName: String?) -> ExportableImage {
        return ExportableImage(cgImage: cgImage, preferredFileName: preferredFileName)
    }
}
