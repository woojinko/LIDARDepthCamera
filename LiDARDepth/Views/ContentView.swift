/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The app's main user interface.
*/

import SwiftUI
import MetalKit
import Metal

fileprivate extension Comparable {
    func clamped(_ f: Self, _ t: Self)  ->  Self {
        var r = self
        if r < f { r = f }
        if r > t { r = t }
        return r
    }
}

struct ContentView: View {
    
    @StateObject private var manager = CameraManager()
    
    @State private var maxDepth = Float(5.0)
    @State private var minDepth = Float(0.0)
    @State private var scaleMovement = Float(1.0)
    
    @State private var dragHorizontalDistance = Float(0.0)
    @State private var dragVerticalDistance = Float(0.0)
    
    @State private var point = CGPoint(x: 0, y: 0)
    @State private var degrees: Double = 0
    @State private var draging: Bool = false

    
    let maxRangeDepth = Float(15)
    let minRangeDepth = Float(0)
    
    private func onDragEndedAction(gesture: DragGesture.Value) -> Void {
            withAnimation {
                point = CGPoint(x: 0, y: 0)
                degrees = 0
            }
            draging = false
        }
    

    var rotateDrag: some Gesture {
        DragGesture()
            .onChanged { value in
                self.dragHorizontalDistance = Float(value.translation.width)
                self.dragVerticalDistance = Float(value.translation.height)
            }
    }
    
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
                                MyPointCloudView(
                                    rotationAngle: rotationAngle,
                                    maxDepth: $maxDepth,
                                    minDepth: $minDepth,
                                    scaleMovement: $scaleMovement,
                                    capturedData: manager.capturedData,
                                    dragHorizontalDistance: $dragHorizontalDistance,
                                    dragVerticalDistance: $dragVerticalDistance
                                )
                                .gesture(rotateDrag)
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
