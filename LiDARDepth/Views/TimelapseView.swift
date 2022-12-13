//
//  TimelapseView.swift
//  LiDARDepth
//
//  Created by Matt Franchi on 12/11/22.
//  Copyright © 2022 Apple. All rights reserved.
//

import SwiftUI
import GLKit4

func ICPFromTwoTLImages(img1: TLImage, img2: TLImage) -> GLKMatrix4 {
    
    var pointCloud1: [GLKVector3]()
    var pointCloud2: [GLKVector3]()
    
    assert(img1.depth_width == img2.depth_width, "mismatched widths")
    
    assert(img1.depth_height == img2.depth_height, "mismatched heights")
    
    assert (img1.depth_step == img2.depth_step, "mismatched steps")
    
    // at this point, all sanity checks passed
    for y in stride(from: 0, to: img1.depth_height, by: img1.depth_step) {
        
        for x in stride(from: 0, to: img1.depth_width, by: img1.depth_step) {
            
            
            pointCloud1.append(GLKVector3Make(Float(x), Float(y), Float(depthDataArray[(y * img1.depth_width) + x])))
            
        }
    }
    
    for y in stride(from: 0, to: img2.depth_height, by: img1.depth_step) {
        
        for x in stride(from: 0, to: img2.depth_width, by: img1.depth_step) {
            
            
            pointCloud2.append(GLKVector3Make(Float(x), Float(y), Float(depthDataArray[(y * img1.depth_width) + x])))
            
        }
    }
    
    var ICPInstance = ICP(pointCloud1, pointCloud2)
    var finalTransform = ICPInstance.iterate(maxIterations: 3, minErrorChange: 5.0)
    
    print(finalTransform)
    
    return finalTransform
    
    
    
    
    
}

struct TimelapseView: View {
    
    var timelapse: Timelapse
    
    @State private var timeline = 0.0
    @State private var isEditing: Bool = false
    
    var body: some View {
        
        GeometryReader { geometry in
            
            
            VStack {
                
                Text(timelapse.title)
                
                ZStack {
                    ForEach(Array(timelapse.images.enumerated()), id: \.element) { index, tl_image in
                        
                        Image(uiImage: UIImage(data: tl_image.raw)!)
                            .resizable()
                            .frame(width: geometry.size.width * 0.5, height: geometry.size.height * 0.5, alignment: .center)
                            //.opacity(Double(1 - (timeline - (index+1) * 10)/10))
                            .zIndex(Double(timelapse.images.count - index))
                            .opacity(1.0 - (Double(timeline - (Double(index) * 30.0))/30.0))
                               
                    }
                }
                
                
                Slider(
                    value: $timeline,
                    in: 0...(Double(timelapse.images.count) * 30.0),
                    step: 1
                ) {
                    Text("Timeline")
                } onEditingChanged: { editing in
                    isEditing = editing
                    
                }
                .frame(width: geometry.size.width * 0.9, height: geometry.size.height * 0.1, alignment: .center)
                
                
                Button {
                    Text("Calculate ICP")
                }{
                    
                }
                
            }
        }
        
    }
}

struct TimelapseView_Previews: PreviewProvider {
    static var previews: some View {
        TimelapseView(timelapse: Timelapse(title: "hello", images: []))
    }
}
