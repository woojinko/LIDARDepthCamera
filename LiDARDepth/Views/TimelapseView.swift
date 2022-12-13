//
//  TimelapseView.swift
//  LiDARDepth
//
//  Created by Matt Franchi on 12/11/22.
//  Copyright © 2022 Apple. All rights reserved.
//

import SwiftUI
import GLKit


struct TimelapseView: View {
    
    @ObservedObject var dataProvider = DataProvider.shared
    
    @State var timelapse: Timelapse
    
    @State private var timeline = 0.0
    @State private var isEditing: Bool = false
    
    @State var deleteAvailable: Bool = false
    @State var alignTwoAvailable: Bool = false
    @State var alignAllAvailable: Bool = false
    
    @State var selected: [Bool]

    @State var selectedIdxs = IndexSet()
    
    init(timelapse: Timelapse)
    {
        _timelapse = State(initialValue: timelapse)
        let s = [Bool](repeating: false, count: timelapse.images.count)
        //print(s)
        _selected = State(initialValue: s)
        print(self.selected)
    }
    
    var body: some View {
        
        GeometryReader { geometry in
            
            ScrollView(.vertical) {
                
                VStack {
                    
                    Text(timelapse.title)
                    
                    HStack {
                        
                        Button {
                            
                            dataProvider.deleteImages(selectedIdxs, id: timelapse.id)
                            timelapse = dataProvider.getTimelapse(id: timelapse.id) ?? timelapse
                            
                        } label: {
                            Text("Delete")
                        }
                        .disabled(deleteAvailable ? false : true)
                        
                        Button {
                            
                            //ICPFromTwoTLImages(img1: timelapse.images[selectedIdxs[0]], img2: timelapse.images[selectedIdxs[1]])
                            
                        } label: {
                            Text("Align Two")
                        }
                        .disabled(alignTwoAvailable ? false : true)
                        
                        Button {
                            
                            
                            
                        } label: {
                            Text("Align All")
                        }
                        .disabled(alignAllAvailable ? false : true)
                        

                    }
                    
                    ScrollView(.horizontal) {
                        
                        HStack(spacing: geometry.size.width * 0.24) {
                            
                            ForEach(Array(timelapse.images.enumerated()), id: \.element) { index, tl_image in
                                
                                GeometryReader { cardGeometry in
                                    
                                    ZStack {
                                        
                                        Image(uiImage: UIImage(data: tl_image.raw)!)
                                            .resizable()
                                            .frame(width:geometry.size.width * 0.25, height: geometry.size.height * 0.25)
                                        
                                        Button {
                                            
                                            selected[index].toggle()
                                            if(selectedIdxs.contains(index)) {
                                                selectedIdxs.remove(index)
                                            }
                                            else
                                            {
                                                selectedIdxs.insert(index)
                                            }
                                            
                                            
                                        } label: {
                                            
                                            selected[index] ? Image(systemName:"circle.fill")
                                                .resizable()
                                            : Image(systemName:"circle")
                                                .resizable()
                                            
                                            
                                            
                                            
                                        }
                                        .frame(width: geometry.size.width * 0.05, height: geometry.size.width * 0.05)
                                        .offset(x: geometry.size.width * 0.1, y: -1*geometry.size.height * 0.11)
                                        //.position(x: cardGeometry.size.width * 0.95, y: cardGeometry.size.height * 0.05)
                                        
                                    }
                                    
                                }
                                
                                
                                
                            }
                            
                            
                        }
                        
                    }
                    .frame(height: geometry.size.height * 0.33)
                    
                    //Spacer()
                    
                    ZoomOnTap {
                        ZStack {
                            ForEach(Array(timelapse.images.enumerated()), id: \.element) { index, tl_image in
                                
                                Image(uiImage: UIImage(data: tl_image.raw)!)
                                    .resizable()
                                    .frame(width: geometry.size.width * 0.8, height: geometry.size.height * 0.8, alignment: .center)
                                //.opacity(Double(1 - (timeline - (index+1) * 10)/10))
                                    .zIndex(Double(timelapse.images.count - index))
                                    .opacity(1.0 - (Double(timeline - (Double(index) * 30.0))/30.0))
                                
                                
                                
                            }
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
                        
                        ICPFromTwoTLImages(img1: timelapse.images[0], img2: timelapse.images[1])
                        
                    } label: {
                        Image(systemName: "checkmark.circle")
                            .resizable()
                            .frame(width: geometry.size.width * 0.12, height: geometry.size.width * 0.12)
                            .font(.largeTitle)
                    }
                    
                    
                }
                .onChange(of: selectedIdxs) { _ in
                    let countPressed = selectedIdxs.count
                    if(countPressed) > 0 {
                        deleteAvailable = true
                    }
                    else {
                        deleteAvailable = false
                    }
                    
                    if(countPressed) == 2 {
                        alignTwoAvailable = true
                    }
                    else {
                        alignTwoAvailable = false
                    }
                    
                    if(countPressed > 1) {
                        alignAllAvailable = true
                    }
                    else {
                        alignAllAvailable = false
                    }
                }
                .onAppear {
                    
                }
                
            }
            .frame(width:geometry.size.width, height: geometry.size.height, alignment:.center)
            //.onChange(of: dataProvider) { _ in
                //print("data provider changed")
            
        }
        
    }
}

struct TimelapseView_Previews: PreviewProvider {
    static var previews: some View {
        TimelapseView(timelapse: Timelapse(title: "hello", images: []))
    }
}
