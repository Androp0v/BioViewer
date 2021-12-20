//
//  ProteinHighQualityRender.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 20/12/21.
//

import Accelerate
import CoreGraphics
import Foundation
import Metal
import UIKit
import SwiftUI

enum HQRenderingError: Error {
    case nonLoadedBuffer
    case unknownError
}

extension ProteinRenderer {
    
    func drawHighQualityFrame(size: CGSize, photoModeViewModel: PhotoModeViewModel) throws {
        
        // Create the textures required for HQ rendering
        var hqTextures = HQTextures()
        hqTextures.makeTextures(device: device)
        
        // Change the image aspect ratio
        self.scene.camera.updateProjection(drawableSize: CGSize(width: HQTextures.textureWidth,
                                                                height: HQTextures.textureHeight))
        self.scene.aspectRatio = 1.0
        
        // Assure buffers are loaded
        guard self.subunitBuffer != nil else { throw HQRenderingError.nonLoadedBuffer }
        guard self.atomTypeBuffer != nil else { throw HQRenderingError.nonLoadedBuffer }
        guard let uniformBuffers = self.uniformBuffers else { throw HQRenderingError.nonLoadedBuffer }
        
        // Wait until the inflight command buffer has completed its work
        _ = frameBoundarySemaphore.wait(timeout: .distantFuture)

        // MARK: - Update uniforms buffer
        
        // Ensure the uniform buffer is loaded
        var uniformBuffer = uniformBuffers[currentFrameIndex]
        
        // Update current frame index
        currentFrameIndex = (currentFrameIndex + 1) % maxBuffersInFlight
                
        // Update uniform buffer
        self.scene.updateScene()
        withUnsafePointer(to: self.scene.frameData) {
            uniformBuffer.contents()
                .copyMemory(from: $0, byteCount: MemoryLayout<FrameData>.stride)
        }
        
        // MARK: - Command buffer & depth
        
        guard let commandQueue = commandQueue else {
            NSLog("Command queue is nil.")
            throw HQRenderingError.unknownError
        }
        
        // Create command buffer
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {
            NSLog("Unable to create command buffer.")
            throw HQRenderingError.unknownError
        }
        
        // MARK: - Shadow Map pass
        
        shadowRenderPass(commandBuffer: commandBuffer, uniformBuffer: &uniformBuffer)
        
        // MARK: - Getting drawable
        // The final pass can only render if a drawable is available, otherwise it needs to skip
        // rendering this frame. Get the drawable as late as possible.
                
        // MARK: - Transparent geometry pass
        impostorRenderPass(commandBuffer: commandBuffer,
                           uniformBuffer: &uniformBuffer,
                           drawableTexture: hqTextures.hqTexture,
                           depthTexture: hqTextures.hqDepthTexture)
        
        // MARK: - Completion handler
        commandBuffer.addCompletedHandler({ [weak self] commandBuffer in
            guard let self = self else { return }
            // GPU work is complete, signal the semaphore to start the CPU work
            self.frameBoundarySemaphore.signal()
            // Display the image
            DispatchQueue.main.async {
                let hqImage = hqTextures.hqTexture.cgImage
                photoModeViewModel.image = hqImage
                photoModeViewModel.isPreviewCreated = true
            }
        })
        
        // MARK: - Commit buffer
        // Commit command buffer
        commandBuffer.commit()
    }
}

// MARK: - Texture to image

extension MTLTexture {

    #if os(iOS)
    typealias XImage = UIImage
    #elseif os(macOS)
    typealias XImage = NSImage
    #endif

    var cgImage: CGImage? {

        assert(self.pixelFormat == .bgra8Unorm)
    
        // Read texture as byte array
        let rowBytes = self.width * 4
        let length = rowBytes * self.height
        let bgraBytes = [UInt8](repeating: 0, count: length)
        let region = MTLRegionMake2D(0, 0, self.width, self.height)
        self.getBytes(UnsafeMutableRawPointer(mutating: bgraBytes), bytesPerRow: rowBytes, from: region, mipmapLevel: 0)

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

        // Flipping image vertically
        let flippedBytes = bgraBytes // share the buffer
        var flippedBuffer = vImage_Buffer(data: UnsafeMutableRawPointer(mutating: flippedBytes),
                                          height: vImagePixelCount(self.height),
                                          width: vImagePixelCount(self.width),
                                          rowBytes: rowBytes)
        vImageVerticalReflect_ARGB8888(&rgbaBuffer, &flippedBuffer, 0)

        // create CGImage with RGBA
        let colorScape = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        guard let data = CFDataCreate(nil, flippedBytes, length) else { return nil }
        guard let dataProvider = CGDataProvider(data: data) else { return nil }
        let cgImage = CGImage(width: self.width, height: self.height, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: rowBytes,
                    space: colorScape, bitmapInfo: bitmapInfo, provider: dataProvider,
                    decode: nil, shouldInterpolate: true, intent: .defaultIntent)
        return cgImage
    }

    var image: XImage? {
        guard let cgImage = self.cgImage else { return nil }
        #if os(iOS)
        return UIImage(cgImage: cgImage)
        #elseif os(macOS)
        return NSImage(cgImage: cgImage, size: CGSize(width: cgImage.width, height: cgImage.height))
        #endif
    }

}
