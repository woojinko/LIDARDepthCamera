/*
See LICENSE folder for this sample’s licensing information.

Abstract:
An object that connects the CameraController and the views.
*/

import Foundation
import SwiftUI
import Combine
import simd
import AVFoundation
import GLKit

class CameraManager: ObservableObject, CaptureDataReceiver {

    var capturedData: CameraCapturedData
    @Published var isFilteringDepth: Bool {
        didSet {
            controller.isFilteringEnabled = isFilteringDepth
        }
    }
    @Published var orientation = UIDevice.current.orientation
    @Published var waitingForCapture = false
    @Published var processingCapturedResult = false
    @Published var dataAvailable = false
    
    @Published var passed_isSavingTimelapse: Bool
    @Published var passed_timelapseName: String
    
    var currentImagesArray: [TL_Image]
    
    @ObservedObject var dataProvider = DataProvider.shared
    
    let controller: CameraController
    var cancellables = Set<AnyCancellable>()
    var session: AVCaptureSession { controller.captureSession }
    
    init() {
        
        _passed_isSavingTimelapse = Published.init(initialValue: false)
        _passed_timelapseName = Published.init(initialValue: "")
        currentImagesArray = []
        
        // Create an object to store the captured data for the views to present.
        capturedData = CameraCapturedData()
        controller = CameraController()
        controller.isFilteringEnabled = true
        controller.startStream()
        isFilteringDepth = controller.isFilteringEnabled
        
        NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification).sink { _ in
            self.orientation = UIDevice.current.orientation
        }.store(in: &cancellables)
        controller.delegate = self
        
        
    }
    
    func startPhotoCapture(isSavingTimelapse: Published<Bool> = Published.init(initialValue:false), timelapseName: Published<String> = Published.init(initialValue:"")) {
        
        
        _passed_isSavingTimelapse = isSavingTimelapse
        print(_passed_isSavingTimelapse)
        _passed_timelapseName = timelapseName
        
        controller.capturePhoto()
        waitingForCapture = true
    }
    
    func resumeStream() {
        controller.startStream()
        processingCapturedResult = false
        waitingForCapture = false
    }
    
    func stopStream() {
        controller.stopStream()
        processingCapturedResult = false
        waitingForCapture = false
    }
    
    func getDocumentsDirectory() -> URL {
        // find all possible documents directories for this user
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)

        // just send back the first one, which ought to be the only one
        return paths[0]
    }
    
    func exifOrientationFromDeviceOrientation(deviceOrientation: UIDeviceOrientation) -> CGImagePropertyOrientation {
        let curDeviceOrientation = deviceOrientation
        let exifOrientation: CGImagePropertyOrientation

        switch curDeviceOrientation {
        case UIDeviceOrientation.portraitUpsideDown:  // Device oriented vertically, home button on the top
            exifOrientation = .left
        case UIDeviceOrientation.landscapeLeft:       // Device oriented horizontally, home button on the right
            exifOrientation = .upMirrored
        case UIDeviceOrientation.landscapeRight:      // Device oriented horizontally, home button on the left
            exifOrientation = .down
        case UIDeviceOrientation.portrait:            // Device oriented vertically, home button on the bottom
            exifOrientation = .up
        default:
            exifOrientation = .up
        }
        return exifOrientation
    }
    
    // Called on every photo capture
    
    func onNewPhotoData(capturedData: CameraCapturedData) {
        // Because the views hold a reference to `capturedData`, the app updates each texture separately.
        self.capturedData.depth = capturedData.depth
        self.capturedData.colorY = capturedData.colorY
        self.capturedData.colorCbCr = capturedData.colorCbCr
        self.capturedData.cameraIntrinsics = capturedData.cameraIntrinsics
        self.capturedData.cameraReferenceDimensions = capturedData.cameraReferenceDimensions
        
        // NEW CODE BEGINS
        
        self.capturedData.capturedPhoto = capturedData.capturedPhoto
        self.capturedData.depthData = capturedData.depthData
        
        
        let compressionQuality: CGFloat = 0.9
        
        let url = getDocumentsDirectory().appendingPathComponent("image.jpg")
        
        //        let URL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        
        guard let imageData = self.capturedData.capturedPhoto?.fileDataRepresentation() else { return}
        var imageAsUIImage = UIImage(data: imageData)!
        imageAsUIImage = imageAsUIImage.rotate(radians: 0) ?? imageAsUIImage
        //        let dataUIImage = imageAsUIImage?.jpegData(compressionQuality: compressionQuality)
        //        try? dataUIImage?.write(to: url)
        
        
        
        
        
        let depthData = self.capturedData.depthData!
        //let depthOrientation = exifOrientationFromDeviceOrientation(deviceOrientation: orientation)
        
        
        //let depthDataMap = depthData.applyingExifOrientation(depthOrientation).depthDataMap
        
        // do I need this?
        //        depthDataMap.normalize()
        
        let ciImage = CIImage(cvPixelBuffer: depthData.depthDataMap)
        var depthAsUIImage = UIImage(ciImage: ciImage)
        depthAsUIImage = depthAsUIImage.rotate(radians: Float.pi/2) ?? depthAsUIImage
        
        let depthUIImage = depthAsUIImage.jpegData(compressionQuality: compressionQuality)
        try? depthUIImage?.write(to: url)
        
        
        // using depth texture data
        
        let bytesPerPixel = 2
        let imageByteCount = self.capturedData.depth!.width * self.capturedData.depth!.height * self.capturedData.depth!.depth * bytesPerPixel
        
        let bytesPerRow = self.capturedData.depth!.width * bytesPerPixel

        var src = [Float](repeating: 0, count: Int(imageByteCount))

        let region = MTLRegionMake3D(0, 0, 0, self.capturedData.depth!.width, self.capturedData.depth!.height, self.capturedData.depth!.depth)

        self.capturedData.depth!.getBytes(&src, bytesPerRow: bytesPerRow, from: region, mipmapLevel: 0)
        
        //print(src[0...36])
        //print(capturedData.depthData[0...36])
        
        var depthArray = [GLKVector3]()
        
        print(self.capturedData.depth!)
        
        for y in 0..<(self.capturedData.depth!.height/2) {
            
            for x in 0..<(self.capturedData.depth!.width/2) {
                
                //depthArray.append(GLKVector3Make(Float(x), Float(y), Float(src[y * self.capturedData.depth!.width + x])))
                depthArray.append(GLKVector3Make(Float(x), Float(y), 2.0))
                
            }
        }
        
        assert(self.capturedData.depth!.width * self.capturedData.depth!.height * 2 == src.count, "mismatched arrays")
        
        var depthArray_subset = [GLKVector3]()
        
        for y in stride(from: 0, to: capturedData.depth!.height, by: 40) {
            
            for x in stride(from: 0, to: capturedData.depth!.width, by: 40) {
                
                depthArray_subset.append(GLKVector3Make(Float(x),Float(y),src[y * capturedData.depth!.width + x]))
                
            }
            
        }
        
        var test_points = [GLKVector3]()
        
        for y in 0..<(99) {
            
            for x in 0..<(99) {
                
                for z in 0..<(99) {
                    
                    test_points.append(GLKVector3Make(Float(x), Float(y), Float(z)))
                    
                }
                
                
                
            }
            
        }
        
        //for i in stride(from: 0, to: 3000, by: 1) {
            //print("\(depthArray[i].x) \(depthArray[i].y) \(depthArray[i].z)")
        // transform by inverse of intrinsic matrix
        
        for i in stride(from: 0, to: 3000, by: 1) {
            print("\(depthArray[i].x) \(depthArray[i].y) \(depthArray[i].z)")

            
        }
        
        var points = [GLKVector3]()
        for i in 0...99 {
            for j in 0...99 {
                let x = (Float(i) / 10.0) - 6.0
                let y = (Float(j) / 10.0) - 6.0
                var z: Float = 0.0
                let sphereSurf = (9 - (x * x) - (y * y))
                if sphereSurf > 0 {
                    z = sphereSurf.squareRoot() - 1.5
                    if z < 0 { z = 0 }
                }
                // Add a bit of noise to Z, between -0.1 and 0.1
                let noise = ((Float(arc4random_uniform(10000)) / 10000) * 0.2) - 0.1
                let point = GLKVector3Make(Float(i)/10.0, Float(j)/10.0, z + noise)
                points.append(point)
                
            }
        }
        
        var pointsOffset = [GLKVector3]()
        for i in 0...99 {
            for j in 0...99 {
                let x = (Float(i) / 10.0) - 5.0
                let y = (Float(j) / 10.0) - 5.0
                var z: Float = 0.0
                let sphereSurf = (9 - (x * x) - (y * y))
                if sphereSurf > 0 {
                    z = sphereSurf.squareRoot() - 1.5
                    if z < 0 { z = 0 }
                }
                // Add a bit of noise to Z, between -0.1 and 0.1
                let noise = ((Float(arc4random_uniform(10000)) / 10000) * 0.2) - 0.1
                let point = GLKVector3Make(Float(i)/10.0, Float(j)/10.0, z + noise)
                pointsOffset.append(point)
            }
        }
        
        print(depthArray.count)
        
        var ICPInstance = ICP(test_points, test_points)
        var finalTransform = ICPInstance.iterate(maxIterations: 3, minErrorChange: 5.0)
        
        print(finalTransform)
=======
//        var ICPInstance = ICP(depthArray, depthArray)
//        var finalTransform = ICPInstance.iterate(maxIterations: 10, minErrorChange: 0.0)
//        
//        print(finalTransform)
>>>>>>> 01c3103 (trying to fix rotation)
        
        
//        for ()
//
//        let pointCloudGLK = GLKVector3MakeWithArray(&src)
//
//        let ICPInstance = ICP(pointCloudGLK, pointCloudGLK)
//        let finalTransform = ICPInstance.iterate(maxIterations: 100, minErrorChange: 0.0)
//
        //print(src.count)
        //print(src[20...40])
        //print(src.count)
        //print(src[0...36])
        
        
        
        let newImage = TL_Image(raw: imageAsUIImage.pngData()!, depth: depthAsUIImage.pngData()!)
        
        if currentImagesArray.isEmpty {
            print("is empty")
            currentImagesArray = [newImage]
            print(currentImagesArray.count)
        }
        else {
            print("not empty")
            currentImagesArray.append(newImage)
            print(currentImagesArray.count)
        }
        
        
        // NEW CODE ENDS
        if(passed_isSavingTimelapse == true)
        {
            let newTimelapse = Timelapse(title:passed_timelapseName, images: currentImagesArray)
            dataProvider.createTimelapse(timelapse: newTimelapse)
            print(newTimelapse.images.count)
            print("created timelapse")
            currentImagesArray = []
        }
        
        
        
        
        
        waitingForCapture = false
        processingCapturedResult = true
        
        resumeStream()
    }
    
    func onNewData(capturedData: CameraCapturedData) {
        DispatchQueue.main.async {
            if !self.processingCapturedResult {
                // Because the views hold a reference to `capturedData`, the app updates each texture separately.
                self.capturedData.depth = capturedData.depth
                self.capturedData.colorY = capturedData.colorY
                self.capturedData.colorCbCr = capturedData.colorCbCr
                self.capturedData.cameraIntrinsics = capturedData.cameraIntrinsics
                self.capturedData.cameraReferenceDimensions = capturedData.cameraReferenceDimensions
                if self.dataAvailable == false {
                    self.dataAvailable = true
                }
            }
        }
    }
   
}

class CameraCapturedData {
    
    var depth: MTLTexture?
    var depthData: AVDepthData?

    var colorY: MTLTexture?
    var colorCbCr: MTLTexture?
    var cameraIntrinsics: matrix_float3x3
    var cameraReferenceDimensions: CGSize
    var capturedPhoto: AVCapturePhoto?

    init(depth: MTLTexture? = nil,
         depthData: AVDepthData? = nil,
         colorY: MTLTexture? = nil,
         colorCbCr: MTLTexture? = nil,
         cameraIntrinsics: matrix_float3x3 = matrix_float3x3(),
         cameraReferenceDimensions: CGSize = .zero,
         capturedPhoto: AVCapturePhoto? = NSObject() as? AVCapturePhoto) {
        
        
        
        self.depth = depth
        self.depthData = depthData
        self.colorY = colorY
        self.colorCbCr = colorCbCr
        self.cameraIntrinsics = cameraIntrinsics
        self.cameraReferenceDimensions = cameraReferenceDimensions
        self.capturedPhoto = capturedPhoto ?? NSObject() as? AVCapturePhoto
    }
}
