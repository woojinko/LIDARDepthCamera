/*
See LICENSE folder for this sample’s licensing information.

Abstract:
An extension to wrap a pixel buffer in an MTLTexture object.
*/

import Foundation
import AVFoundation

extension CVPixelBuffer {
    
    func texture(withFormat pixelFormat: MTLPixelFormat, planeIndex: Int, addToCache cache: CVMetalTextureCache) -> MTLTexture? {
        
        let width = CVPixelBufferGetWidthOfPlane(self, planeIndex)
        let height = CVPixelBufferGetHeightOfPlane(self, planeIndex)
        
        var cvtexture: CVMetalTexture?
        CVMetalTextureCacheCreateTextureFromImage(nil, cache, self, nil, pixelFormat, width, height, planeIndex, &cvtexture)
        guard let texture = cvtexture else { return nil }
        return CVMetalTextureGetTexture(texture)
    }
    
    func extract() -> [Float16] {
        let width = CVPixelBufferGetWidth(self)
        let height = CVPixelBufferGetHeight(self)
        
        CVPixelBufferLockBaseAddress(self, CVPixelBufferLockFlags(rawValue: 0))
        
        var type = CVPixelBufferGetPixelFormatType( self)

        if (type != kCVPixelFormatType_DepthFloat16) {
            print(type)
            print("Wrong type");
        }
        
        let floatBuffer = unsafeBitCast(CVPixelBufferGetBaseAddress(self), to: UnsafeMutablePointer<Float16>.self)
        var floatBufferArray = [Float16]()
        
        
        
        for y in stride(from: 0, to: height, by: 1) {
          for x in stride(from: 0, to: width, by: 1) {
            let pixel = floatBuffer[y * width + x]
            floatBufferArray.append(pixel)
          }
        }
        
        CVPixelBufferUnlockBaseAddress(self, CVPixelBufferLockFlags(rawValue: 0))
        
        return floatBufferArray

    }
    
}


