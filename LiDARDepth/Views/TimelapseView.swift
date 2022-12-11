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
    
    var body: some View {
        
        GeometryReader { geometry in
            
            Text(timelapse.title)
            ScrollView(.horizontal) {
                HStack {
                    ForEach(timelapse.images, id: \.self) { tl_image in
                        
                        Image(uiImage: UIImage(data: tl_image.raw)!)
                            .resizable()
                            .frame(width: geometry.size.width * 0.5, height: geometry.size.height * 0.5, alignment: .center)
                        
                    }
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
