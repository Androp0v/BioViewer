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

        assert(self.pixelFormat == .bgra8Unorm)
    
        // Read texture as byte array
        let rowBytes = self.width * 4
        let length = rowBytes * self.height
        var bgraBytes = [UInt8](repeating: 0, count: length)
        let region = MTLRegionMake2D(0, 0, self.width, self.height)
        self.getBytes(UnsafeMutableRawPointer(mutating: bgraBytes),
                      bytesPerRow: rowBytes,
                      from: region,
                      mipmapLevel: 0)
        
        // Clear background
        if let depthTexture = depthTexture, clearBackground {
            let depthRowBytes = self.width * 4
            let depthBytes = [Float](repeating: 0, count: 4 * self.width * self.height)
            let depthRegion = MTLRegionMake2D(0, 0, self.width, self.height)
            depthTexture.getBytes(UnsafeMutableRawPointer(mutating: depthBytes),
                                  bytesPerRow: depthRowBytes,
                                  from: depthRegion,
                                  mipmapLevel: 0)
            let bgraPointer = UnsafeMutableRawPointer(mutating: bgraBytes).assumingMemoryBound(to: UInt8.self)
            let depthPointer = UnsafeMutableRawPointer(mutating: depthBytes).assumingMemoryBound(to: Float32.self)
            for index in 0..<(self.width * self.height) {
                let bgraIndex = index * 4 + 3
                if (depthPointer + index).pointee == 1.0 {
                    (bgraPointer + bgraIndex).pointee = 0
                }
            }
        }
        
        // Use Accelerate framework to convert from BGRA to RGBA
        var bgraBuffer = vImage_Buffer(data: UnsafeMutableRawPointer(mutating: bgraBytes),
                                       height: vImagePixelCount(self.height),
                                       width: vImagePixelCount(self.width),
                                       rowBytes: rowBytes)
        let rgbaBytes = [UInt8](repeating: 0, count: length)
        var rgbaBuffer = vImage_Buffer(data: UnsafeMutableRawPointer(mutating: rgbaBytes),
                                       height: vImagePixelCount(self.height),
                                       width: vImagePixelCount(self.width),
                                       rowBytes: rowBytes)
        let map: [UInt8] = [2, 1, 0, 3]
        vImagePermuteChannels_ARGB8888(&bgraBuffer, &rgbaBuffer, map, 0)

        // Create CGImage with RGBA
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
