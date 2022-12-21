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
        
        guard let imageData = self.capturedData.capturedPhoto?.fileDataRepresentation() else { return}
        var imageAsUIImage = UIImage(data: imageData)!
        imageAsUIImage = imageAsUIImage.rotate(radians: 0) ?? imageAsUIImage
            
        
        let depthData = self.capturedData.depthData!
        
        let ciImage = CIImage(cvPixelBuffer: depthData.depthDataMap)
        var depthAsUIImage = UIImage(ciImage: ciImage)
        depthAsUIImage = depthAsUIImage.rotate(radians: Float.pi/2) ?? depthAsUIImage
        
        let depthUIImage = depthAsUIImage.jpegData(compressionQuality: compressionQuality)
        try? depthUIImage?.write(to: url)
        

        var pointCloudArray = [GLKVector3]()
        var depthDataArray = capturedData.depthData!.depthDataMap.extract()
        
        let newImage = TL_Image(raw: imageAsUIImage.pngData()!, depth: depthDataArray, depth_width: CVPixelBufferGetWidth(self.capturedData.depthData!.depthDataMap), depth_height: CVPixelBufferGetHeight(self.capturedData.depthData!.depthDataMap), depth_step: 48)
        
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
