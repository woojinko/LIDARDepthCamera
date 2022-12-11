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
    
    @Binding var passed_isSavingTimelapse: Bool
    @Binding var passed_timelapseName: String
    
    @State var currentImagesArray: [TL_Image]
    
    @ObservedObject var dataProvider = DataProvider.shared
    
    let controller: CameraController
    var cancellables = Set<AnyCancellable>()
    var session: AVCaptureSession { controller.captureSession }
    
    init() {
        
        _passed_isSavingTimelapse = Binding.constant(false)
        _passed_timelapseName = Binding.constant("")
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
    
    func startPhotoCapture(isSavingTimelapse: Bool = false, timelapseName: String = "") {
        
        passed_isSavingTimelapse = isSavingTimelapse
        passed_timelapseName = timelapseName
        
        controller.capturePhoto()
        waitingForCapture = true
    }
    
    func resumeStream() {
        controller.startStream()
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
        let depthOrientation = exifOrientationFromDeviceOrientation(deviceOrientation: orientation)
        
        
        let depthDataMap = depthData.applyingExifOrientation(depthOrientation).depthDataMap
        
        // do I need this?
        //        depthDataMap.normalize()
        
        let ciImage = CIImage(cvPixelBuffer: depthDataMap)
        var depthAsUIImage = UIImage(ciImage: ciImage)
        depthAsUIImage = depthAsUIImage.rotate(radians: 0) ?? depthAsUIImage
        
        let depthUIImage = depthAsUIImage.jpegData(compressionQuality: compressionQuality)
        try? depthUIImage?.write(to: url)
        
        
        let newImage = TL_Image(raw: imageAsUIImage.pngData()!, depth: depthAsUIImage.pngData()!)
        
        if currentImagesArray.isEmpty {
            currentImagesArray = [newImage]
        }
        else {
            currentImagesArray.append(newImage)
        }
        
        
        
        // NEW CODE ENDS
        if(passed_isSavingTimelapse == true)
        {
            let newTimelapse = Timelapse(title:passed_timelapseName, images: currentImagesArray)
            dataProvider.createTimelapse(timelapse: newTimelapse)
            currentImagesArray = []
        }
        
        
        
        
        
        waitingForCapture = false
        processingCapturedResult = true
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
