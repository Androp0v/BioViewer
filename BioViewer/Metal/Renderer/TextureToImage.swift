//
//  TextureToImage.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 20/12/21.
//

import Accelerate
import Foundation
import Metal
import UIKit

extension MTLTexture {

    func getCGImage(clearBackground: Bool = false, depthTexture: MTLTexture? = nil) -> CGImage? {

        guard self.pixelFormat == .bgra8Unorm else {
            NSLog("Unexpected pixelFormat in MTLTexture on getCGImage from MTLTexture.")
            return nil
        }
    
        // MARK: - MTLTexture to array
        
        let rowBytes = self.width * 4
        let length = rowBytes * self.height
        let region = MTLRegionMake2D(0, 0, self.width, self.height)
        var bgraBytes = [UInt8](repeating: 0, count: length)
        
        // Fill bgraBytes with the drawable texture data.
        bgraBytes.withUnsafeMutableBytes { bgraBytesPointer in
            self.getBytes(bgraBytesPointer.baseAddress!,
                          bytesPerRow: rowBytes,
                          from: region,
                          mipmapLevel: 0)
        }
        
        // MARK: - Clear background
        
        if let depthTexture = depthTexture, clearBackground {
            let depthRowBytes = self.width * 4
            let depthRegion = MTLRegionMake2D(0, 0, self.width, self.height)
            var depthBytes = [Float](repeating: 0, count: 4 * self.width * self.height)
            
            // Fill depthBytes with the texture data.
            depthBytes.withUnsafeMutableBytes { depthBytesPointer in
                depthTexture.getBytes(depthBytesPointer.baseAddress!,
                                      bytesPerRow: depthRowBytes,
                                      from: depthRegion,
                                      mipmapLevel: 0)
                
                // Modify the bgraBytes according to depth values
                bgraBytes.withUnsafeMutableBytes { bgraBytesPointer in
                    let bgraPointer = bgraBytesPointer.baseAddress!.assumingMemoryBound(to: UInt8.self)
                    let depthPointer = depthBytesPointer.baseAddress!.assumingMemoryBound(to: Float32.self)
                    DispatchQueue.concurrentPerform(iterations: self.width * self.height) { index in
                        let bgraIndex = index * 4 + 3
                        if (depthPointer + index).pointee == 1.0 {
                            (bgraPointer + bgraIndex).pointee = 0
                        }
                    }
                }
            }
        }
        
        // MARK: - BGRA to RGBA conversion
        // Use Accelerate framework to convert from BGRA to RGBA
        
        var rgbaBytes = [UInt8](repeating: 0, count: length)
        bgraBytes.withUnsafeMutableBytes { bgraBytesPointer in
            var bgraBuffer = vImage_Buffer(data: bgraBytesPointer.baseAddress!,
                                           height: vImagePixelCount(self.height),
                                           width: vImagePixelCount(self.width),
                                           rowBytes: rowBytes)
            
            rgbaBytes.withUnsafeMutableBytes { rbgaBytesPointer in
                var rgbaBuffer = vImage_Buffer(data: rbgaBytesPointer.baseAddress!,
                                               height: vImagePixelCount(self.height),
                                               width: vImagePixelCount(self.width),
                                               rowBytes: rowBytes)
                let map: [UInt8] = [2, 1, 0, 3]
                vImagePermuteChannels_ARGB8888(&bgraBuffer, &rgbaBuffer, map, 0)
            }
        }
        
        // MARK: - CGImage
        // Create CGImage with RGBA data
        
        let colorScape = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        guard let data = CFDataCreate(nil, rgbaBytes, length) else { return nil }
        guard let dataProvider = CGDataProvider(data: data) else { return nil }
        let cgImage = CGImage(width: self.width,
                              height: self.height,
                              bitsPerComponent: 8,
                              bitsPerPixel: 32,
                              bytesPerRow: rowBytes,
                              space: colorScape,
                              bitmapInfo: bitmapInfo,
                              provider: dataProvider,
                              decode: nil,
                              shouldInterpolate: true,
                              intent: .defaultIntent)
        return cgImage
    }
}
