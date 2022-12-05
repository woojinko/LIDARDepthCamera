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
    
    let controller: CameraController
    var cancellables = Set<AnyCancellable>()
    var session: AVCaptureSession { controller.captureSession }
    
    init() {
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
    
    func startPhotoCapture() {
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
    
    // Called on every photo capture
    
    func onNewPhotoData(capturedData: CameraCapturedData) {
        // Because the views hold a reference to `capturedData`, the app updates each texture separately.
        self.capturedData.depth = capturedData.depth
        self.capturedData.colorY = capturedData.colorY
        self.capturedData.colorCbCr = capturedData.colorCbCr
        self.capturedData.cameraIntrinsics = capturedData.cameraIntrinsics
        self.capturedData.cameraReferenceDimensions = capturedData.cameraReferenceDimensions
        self.capturedData.capturedPhoto = capturedData.capturedPhoto
        
        let compressionQuality: CGFloat = 0.9
        
        
        let url = getDocumentsDirectory().appendingPathComponent("image.jpg")
        
//        let URL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        
        guard let imageData = self.capturedData.capturedPhoto?.fileDataRepresentation() else { return}
        let imageAsUIImage = UIImage(data: imageData)
        let dataUIImage = imageAsUIImage?.jpegData(compressionQuality: compressionQuality)
        try? dataUIImage?.write(to: url)
        
        
        // FROM RECAPTURE UNIVERSAL
        // let data = image.jpegData(compressionQuality: compressionQuality)
        // try? data?.write(to: url)
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
    var colorY: MTLTexture?
    var colorCbCr: MTLTexture?
    var cameraIntrinsics: matrix_float3x3
    var cameraReferenceDimensions: CGSize
    var capturedPhoto: AVCapturePhoto?

    init(depth: MTLTexture? = nil,
         colorY: MTLTexture? = nil,
         colorCbCr: MTLTexture? = nil,
         cameraIntrinsics: matrix_float3x3 = matrix_float3x3(),
         cameraReferenceDimensions: CGSize = .zero,
         capturedPhoto: AVCapturePhoto? = NSObject() as? AVCapturePhoto) {
        
        self.depth = depth
        self.colorY = colorY
        self.colorCbCr = colorCbCr
        self.cameraIntrinsics = cameraIntrinsics
        self.cameraReferenceDimensions = cameraReferenceDimensions
        self.capturedPhoto = capturedPhoto ?? NSObject() as? AVCapturePhoto
    }
}
