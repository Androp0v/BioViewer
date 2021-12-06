//
//  ThumbnailProvider.swift
//  ProteinThumbnail
//
//  Created by Raúl Montón Pinillos on 14/11/21.
//

import UIKit
import QuickLookThumbnailing

// MARK: - ThumbnailProvider

class ThumbnailProvider: QLThumbnailProvider {
    
    override func provideThumbnail(for request: QLFileThumbnailRequest, _ handler: @escaping (QLThumbnailReply?, Error?) -> Void) {
        
        // iOS restricts max memory for file thumbnails, disable the thumbnail provider there
        handler(QLThumbnailReply(contextSize: CGSize.zero, currentContextDrawing: { () -> Bool in
            // Return false to notify that a thumbnail could not be created
            return false
        }), nil)
        
        /*
        // macOS can run the extension with more memory, so enable it there
        let proteinViewModel = ProteinViewModel()
        var proteinViewController: ProteinMetalViewController?
        
        // Render the protein
        DispatchQueue.main.sync {
            proteinViewModel.backgroundColor = .white
            proteinViewController = ProteinMetalViewController(proteinViewModel: proteinViewModel)
            proteinViewController?.view.frame = CGRect(x: 0, y: 0, width: 1941, height: 2560)
            proteinViewController?.renderedView.frame = CGRect(x: 0, y: 0, width: 1941, height: 2560)
            proteinViewController?.renderedView.drawableSize = CGSize(width: 1941, height: 2560)
        }
        
        // Retrieve the file contents
        let fileURL = request.fileURL
        
        guard let proteinData = try? Data(contentsOf: fileURL) else {
            return
        }
        let rawText = String(decoding: proteinData, as: UTF8.self)
        
        // Parse PDB
        guard var protein = try? parsePDB(rawText: rawText, proteinViewModel: proteinViewModel) else {
            return
        }
        
        // Get the drawable 
        var thumbnailTexture: MTLTexture?
        DispatchQueue.main.sync {
            guard let renderedView = proteinViewController?.renderedView else {
                return
            }
            proteinViewModel.dataSource.addProteinToDataSource(protein: &protein, addToScene: true)
            proteinViewModel.renderer.draw(in: renderedView)
            thumbnailTexture = proteinViewController?.renderedView.currentDrawable?.texture
            
        }
        
        guard let cgThumbnail = thumbnailTexture?.toImage() else {
            return
        }
        let thumbnail = UIImage(cgImage: cgThumbnail)
        
        let thumbnailOverlay = UIImage(named: "OverlayPDB")
        
        // Keep the ~3:4 aspect ratio of macOS/iOS document icons
        let thumbnailFrame = CGRect(x: 0.0,
                                    y: 0.0,
                                    width: CGFloat(690.0 / 910.0) * request.maximumSize.height,
                                    height: request.maximumSize.height)
                
        // Draw the thumbnail into the current context, set up with UIKit's coordinate system.
        handler(QLThumbnailReply(contextSize: thumbnailFrame.size, currentContextDrawing: { () -> Bool in
            // Draw the thumbnail here.
            thumbnail.draw(in: thumbnailFrame)
            // Draw the overlay here.
            thumbnailOverlay?.draw(in: thumbnailFrame)
            // Return true if the thumbnail was successfully drawn inside this block.
            return true
        }), nil)
        
        #endif
        */
    }
}

// MARK: - MTLTexture to image

extension MTLTexture {

    func bytes() -> UnsafeMutableRawPointer {
        let width = self.width
        let height   = self.height
        let rowBytes = self.width * 4
        let pointer = malloc(width * height * 4)

        self.getBytes(pointer!, bytesPerRow: rowBytes, from: MTLRegionMake2D(0, 0, width, height), mipmapLevel: 0)

        return pointer!
    }

    func toImage() -> CGImage? {
        let pointer = bytes()

        let pColorSpace = CGColorSpaceCreateDeviceRGB()

        let rawBitmapInfo = CGImageAlphaInfo.noneSkipFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        let bitmapInfo: CGBitmapInfo = CGBitmapInfo(rawValue: rawBitmapInfo)

        let selftureSize = self.width * self.height * 4
        let rowBytes = self.width * 4
        let releaseMaskImagePixelData: CGDataProviderReleaseDataCallback = { (_, _, _) -> Void in
            return
        }
        let provider = CGDataProvider(dataInfo: nil, data: pointer, size: selftureSize, releaseData: releaseMaskImagePixelData)
        let cgImageRef = CGImage(width: self.width,
                                 height: self.height,
                                 bitsPerComponent: 8,
                                 bitsPerPixel: 32,
                                 bytesPerRow: rowBytes,
                                 space: pColorSpace,
                                 bitmapInfo: bitmapInfo,
                                 provider: provider!,
                                 decode: nil,
                                 shouldInterpolate: true,
                                 intent: CGColorRenderingIntent.defaultIntent)!

        return cgImageRef
    }
}
