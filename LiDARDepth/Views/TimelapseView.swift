//
//  TimelapseView.swift
//  LiDARDepth
//
//  Created by Matt Franchi on 12/11/22.
//  Copyright © 2022 Apple. All rights reserved.
//

import SwiftUI

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
                
            }
        }
        
    }
}

struct TimelapseView_Previews: PreviewProvider {
    static var previews: some View {
        TimelapseView(timelapse: Timelapse(title: "hello", images: []))
    }
}
