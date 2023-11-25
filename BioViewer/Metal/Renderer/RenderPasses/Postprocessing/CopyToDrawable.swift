//
//  CopyToDrawable.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 9/4/23.
//

import Foundation
import MetalKit

extension MutableState {
    
    /// Blits the final, upscaled from renderer texture to the drawable size.
    func copyToDrawable(
        commandBuffer: MTLCommandBuffer,
        finalRenderedTexture: MTLTexture,
        drawableTexture: MTLTexture
    ) {
        guard finalRenderedTexture.width == drawableTexture.width else {
            return
        }
        guard finalRenderedTexture.height == drawableTexture.height else {
            return
        }
        let blitCommandEncoder = commandBuffer.makeBlitCommandEncoder()
        blitCommandEncoder?.copy(from: finalRenderedTexture, to: drawableTexture)
        blitCommandEncoder?.endEncoding()
    }
}
