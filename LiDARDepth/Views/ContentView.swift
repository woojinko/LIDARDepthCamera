/*
 See LICENSE folder for this sample’s licensing information.
 
 Abstract:
 The app's main user interface.
 */

import SwiftUI
import MetalKit
import Metal

struct Gallery: Identifiable, Hashable {
    var id = UUID()
    let name: String
}

struct Settings: Identifiable, Hashable {
    var id = UUID()
    let name: String
}

struct Camera: Identifiable, Hashable {
    var id = UUID()
    let name: String
}


struct ScaleButtonStyle: ButtonStyle {
    let geometry: GeometryProxy
    
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .foregroundColor(.blue)
            .frame(width: geometry.size.width * 0.06, height: geometry.size.width * 0.06)
            .scaleEffect(configuration.isPressed ? 1.2 : 1)
    }
}



struct ContentView: View {
    
    @StateObject private var manager = CameraManager()
    
    @State private var maxDepth = Float(5.0)
    @State private var minDepth = Float(0.0)
    @State private var scaleMovement = Float(1.0)
    
    
    @State private var pointCloudMode: Bool = false
    
    @State private var timelapseNamingAlert: Bool = false
    @State private var timelapseName: String = ""
    
    @State var gallery = Gallery(name: "gallery")
    
    @State var settings = Settings(name: "settings")
    
    @State var camera = Camera(name: "camera")
    
    
    let maxRangeDepth = Float(15)
    let minRangeDepth = Float(0)
    
    @State private var dragHorizontalDistance = Float(0.0)
    @State private var dragVerticalDistance = Float(0.0)
    
    @State private var cameraOrig: simd_float4x4 = simd_float4x4(columns: ([1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1]))
    
    var rotateDrag: some Gesture {
        DragGesture()
            .onChanged { value in
                self.dragHorizontalDistance = Float(value.translation.width)
                self.dragVerticalDistance = Float(value.translation.height)
            }
            .onEnded { value in
                self.dragHorizontalDistance = Float(0)
                self.dragVerticalDistance = Float(0)
            }
    }
    
    var body: some View {
        
        GeometryReader { geometry in
            
            
            VStack {
                
                
                
                NavigationStack {
                    
                    ZStack {
                        if pointCloudMode {
                            
                            MyPointCloudView(
                                rotationAngle: rotationAngle,
                                maxDepth: $maxDepth,
                                minDepth: $minDepth,
                                scaleMovement: $scaleMovement,
                                capturedData: manager.capturedData,
                                dragHorizontalDistance: $dragHorizontalDistance,
                                dragVerticalDistance: $dragVerticalDistance,
                                cameraOrig: $cameraOrig
                            )
                            .gesture(rotateDrag)
                            
                        }
                        else {
                            
                            // Camera view
                            MetalTextureColorThresholdDepthView(
                                rotationAngle: rotationAngle,
                                maxDepth: $maxDepth,
                                minDepth: $minDepth,
                                capturedData: manager.capturedData
                            )
                            
                        }
                        
                        
                        
                        //.aspectRatio(calcAspect(orientation: viewOrientation, texture: manager.capturedData.depth), contentMode: .fit)
                        
                        // Camera button
                        HStack {
                            Button {
                                manager.startPhotoCapture()
                            } label: {
                                Image(systemName: manager.processingCapturedResult ? "play.circle" : "camera.circle")
                                    .resizable()
                                    .frame(width: geometry.size.width * 0.12, height: geometry.size.width * 0.12)
                                    .font(.largeTitle)
                            }
                            .buttonStyle(ScaleButtonStyle(geometry: geometry))
                            
                            
                            Spacer()
                            
                            Button {
                                
                                timelapseNamingAlert.toggle()
                                
                            } label: {
                                Image(systemName: "checkmark.circle")
                                    .resizable()
                                    .frame(width: geometry.size.width * 0.12, height: geometry.size.width * 0.12)
                                    .font(.largeTitle)
                            }
                            .alert("Timelapse Name", isPresented: $timelapseNamingAlert, actions: {
                                TextField("Name", text: $timelapseName)
                                
                                Button("Save", action: {
                                    manager.startPhotoCapture(isSavingTimelapse: Published.init(initialValue:true), timelapseName: Published.init(initialValue: timelapseName))
                                })
                                Button("Cancel", action: {
                                    
                                })
                            },
                                   message: {
                                Text("Please enter a name for your timelapse.")
                            }
                            
                                
                                
                            )
                            .buttonStyle(ScaleButtonStyle(geometry: geometry))
                        }
                        .frame(width: geometry.size.width * 0.88, alignment: .center)
                        .position(x: geometry.size.width / 2, y: geometry.size.height * 0.95)
                        
                        
                        VStack {
                            Toggle(isOn: $pointCloudMode) {
                                
                            }
                            .toggleStyle(.switch)
                        }
                        .rotationEffect(Angle(degrees: 270))
                        .frame(width: geometry.size.width * 0.1, height: geometry.size.height * 0.1)
                        .position(x: geometry.size.width * 0.9, y: geometry.size.height * 0.1)
                        
                        
                        
                        HStack {
                            
                            
                            
                            NavigationLink(value: gallery) {
                                HStack {
                                    Image(systemName: "photo.stack.fill")
                                        .resizable()
                                        .frame(width:geometry.size.width * 0.07, height: geometry.size.width * 0.07)
                                        .font(.title3)
                                }
                            }
                            
                            Spacer()
                            
                            NavigationLink(value: settings) {
                                HStack {
                                    Image(systemName: "gearshape.fill")
                                        .resizable()
                                        .frame(width:geometry.size.width * 0.07, height: geometry.size.width * 0.07)
                                        .font(.title3)
                                }
                            }
                            
        
                            
                        }
                        
                        .frame(width: geometry.size.width * 0.4, height: geometry.size.height * 0.03, alignment: .center)
                        .padding()
                        .overlay {
                            
                        }
                        
                        .foregroundColor(.black.opacity(1))
                        .background(Color.white.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: geometry.size.width * 0.02))
                        .position(x: geometry.size.width * 0.5, y: geometry.size.height * 0.95)
                        
                        .navigationDestination(for: Camera.self) { camera in
                            
                        }
                        
                        .navigationDestination(for: Gallery.self) { gallery in
                            GalleryView()
                        }
                        
                        .navigationDestination(for: Settings.self) { settings in
                            Text("Settings View")
                        }
                        
                        
                    }
                    .onChange(of: pointCloudMode) { newPointCloudMode in
                        if(newPointCloudMode == true)
                        {
                            manager.stopStream()
                        }
                        else
                        {
                            manager.resumeStream()
                        }
                                
                    }
                    
                    
                    
                    
                    
                }
                
                
                
            }
            .ignoresSafeArea(edges:[.top, .bottom])
        }
    }
}
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .previewDevice("iPhone 12 Pro Max")
    }
}
