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
            }
            ScrollView {
                if manager.dataAvailable {
                    MetalTextureColorThresholdDepthView(
                        rotationAngle: rotationAngle,
                        maxDepth: $maxDepth,
                        minDepth: $minDepth,
                        capturedData: manager.capturedData
                    )
                    .aspectRatio(calcAspect(orientation: viewOrientation, texture: manager.capturedData.depth), contentMode: .fit)
                    NavigationView {
                        VStack {
                            NavigationLink(destination: {
                                GalleryView()
                            }){
                                VStack{
                                    Image(systemName: "eyes").resizable().aspectRatio(contentMode: .fit).frame(maxWidth:.infinity, maxHeight: 200)
                                    Text("Gallery View")
                                }.frame(maxHeight:200)
                            } .aspectRatio(calcAspect(orientation: viewOrientation, texture: manager.capturedData.depth), contentMode: .fit)
                        }
                    }
                    NavigationView {
                        VStack {
                            NavigationLink(destination: {
                                MetalPointCloudView(
                                    rotationAngle: rotationAngle,
                                    maxDepth: $maxDepth,
                                    minDepth: $minDepth,
                                    scaleMovement: $scaleMovement,
                                    capturedData: manager.capturedData
                                )
                            }){
                                VStack{
                                    Image(systemName: "allergens").resizable().aspectRatio(contentMode: .fit).frame(maxWidth:.infinity, maxHeight: 200)
                                    Text("Point Cloud")
                                }.frame(maxHeight:200)
                            }
                            .aspectRatio(calcAspect(orientation: viewOrientation, texture: manager.capturedData.depth), contentMode: .fit)
                        }
                    }
                    
                    NavigationView {
                        VStack {
                            NavigationLink(destination: {
                                MyPointCloudView(capturedData: manager.capturedData)
                            }){
                                VStack{
                                    Image(systemName: "cloud").resizable().aspectRatio(contentMode: .fit).frame(maxWidth:.infinity, maxHeight: 200)
                                    Text("My Point Cloud")
                                }.frame(maxHeight:200)
                            }
                            .aspectRatio(calcAspect(orientation: viewOrientation, texture: manager.capturedData.depth), contentMode: .fit)
                        }
                    }
                }
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
