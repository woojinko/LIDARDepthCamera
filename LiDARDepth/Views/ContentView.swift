/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The app's main user interface.
*/

import SwiftUI
import MetalKit
import Metal

struct ContentView: View {
    
    @StateObject private var manager = CameraManager()
    
    @State private var maxDepth = Float(5.0)
    @State private var minDepth = Float(0.0)
    @State private var scaleMovement = Float(1.0)
    
    @State private var image = UIImage(systemName: "placeholdertext.fill")
    
    private var url: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("image.jpg")
    }
    
    
    let maxRangeDepth = Float(15)
    let minRangeDepth = Float(0)
    
    var body: some View {
        VStack {
            HStack {
                Button {
                    manager.processingCapturedResult ? manager.resumeStream() : manager.startPhotoCapture()
                } label: {
                    Image(systemName: manager.processingCapturedResult ? "play.circle" : "camera.circle")
                        .font(.largeTitle)
                }
                
                Text("Depth Filtering")
                Toggle("Depth Filtering", isOn: $manager.isFilteringDepth).labelsHidden()
                Spacer()
            }
            SliderDepthBoundaryView(val: $maxDepth, label: "Max Depth", minVal: minRangeDepth, maxVal: maxRangeDepth)
            SliderDepthBoundaryView(val: $minDepth, label: "Min Depth", minVal: minRangeDepth, maxVal: maxRangeDepth)
            ScrollView {
                if manager.dataAvailable {
                    ZoomOnTap {
                        MetalTextureColorThresholdDepthView(
                            rotationAngle: rotationAngle,
                            maxDepth: $maxDepth,
                            minDepth: $minDepth,
                            capturedData: manager.capturedData
                        )
                        .aspectRatio(calcAspect(orientation: viewOrientation, texture: manager.capturedData.depth), contentMode: .fit)
                    }
                    ZoomOnTap {
                        Image(uiImage: image ?? UIImage())
                            .resizable()
                            .onAppear {
                                url.loadImage(&image)
                            }
                        
                        .aspectRatio(calcAspect(orientation: viewOrientation, texture: manager.capturedData.depth), contentMode: .fit)
                    }

//                        ZoomOnTap {
//                            MetalTextureColorZapView(
//                                rotationAngle: rotationAngle,
//                                maxDepth: $maxDepth,
//                                minDepth: $minDepth,
//                                capturedData: manager.capturedData
//                            )
//                            .aspectRatio(calcAspect(orientation: viewOrientation, texture: manager.capturedData.depth), contentMode: .fit)
//                        }
//                        ZoomOnTap {
//                            MetalPointCloudView(
//                                rotationAngle: rotationAngle,
//                                maxDepth: $maxDepth,
//                                minDepth: $minDepth,
//                                scaleMovement: $scaleMovement,
//                                capturedData: manager.capturedData
//                            )
//                            .aspectRatio(calcAspect(orientation: viewOrientation, texture: manager.capturedData.depth), contentMode: .fit)
//                        }
//                        ZoomOnTap {
//                            DepthOverlay(manager: manager,
//                                         maxDepth: $maxDepth,
//                                         minDepth: $minDepth
//                            )
//                                .aspectRatio(calcAspect(orientation: viewOrientation, texture: manager.capturedData.depth), contentMode: .fit)
//                        }
                }
            }
        }
    }
}

struct SliderDepthBoundaryView: View {
    @Binding var val: Float
    var label: String
    var minVal: Float
    var maxVal: Float
    let stepsCount = Float(200.0)
    var body: some View {
        HStack {
            Text(String(format: " %@: %.2f", label, val))
            Slider(
                value: $val,
                in: minVal...maxVal,
                step: (maxVal - minVal) / stepsCount
            ) {
            } minimumValueLabel: {
                Text(String(minVal))
            } maximumValueLabel: {
                Text(String(maxVal))
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .previewDevice("iPhone 12 Pro Max")
    }
}
