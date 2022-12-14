//
//  GalleryView.swift
//  LiDARDepth
//

//  Created by Matt Franchi on 12/8/22.

//  Copyright © 2022 Apple. All rights reserved.
//

import SwiftUI
import GLKit

struct TL_Image: Codable, Identifiable, Hashable {
    var id = UUID()
    let raw: Data
    let depth: [Float16]
    let depth_width: Int
    let depth_height: Int
    let depth_step: Int 
    
    //init(raw: UIImage) {
        //self.raw = raw.pngData()!
    //}
    
}

struct Timelapse: Codable, Identifiable, Hashable  {
    var id = UUID()
    let title: String
    var images: [TL_Image]
}

class DataProvider: ObservableObject {

    
    static let shared = DataProvider()
    private let dataSourceURL: URL
    @Published var allTimelapses = [Timelapse]()
    
    init() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        let timelapsesPath = documentsPath.appendingPathComponent("timelapses").appendingPathExtension("json")
        dataSourceURL = timelapsesPath
        
        _allTimelapses = Published(wrappedValue: getAllTimelapses())
    }
    
    
    private func getAllTimelapses() -> [Timelapse] {
        do {
            let decoder = PropertyListDecoder()
            let data = try Data(contentsOf: dataSourceURL)
            let decodedTimelapses = try! decoder.decode([Timelapse].self, from: data)
            
            
            return decodedTimelapses
        } catch {
            return []
        }
        
    }
    
    func getTimelapse(id: UUID) -> Timelapse? {
        let timelapses = getAllTimelapses()
        
        for tl in timelapses {
            if(tl.id == id) {
                return tl
            }
        }
        return nil
    }
    
    private func saveTimelapses() {
        do {
            let encoder = PropertyListEncoder()
            let data = try encoder.encode(allTimelapses)
            
            try data.write(to: dataSourceURL)
        } catch {
            
        }
    }
    
    func createTimelapse(timelapse: Timelapse) {
        allTimelapses.insert(timelapse, at: 0)
        saveTimelapses()
    }
    
    func changeTimelapse(timelapse: Timelapse, index: Int) {
        allTimelapses[index] = timelapse
        saveTimelapses()
    }
    
    func deleteTimelapse(_ offsets: IndexSet) {
        allTimelapses.remove(atOffsets: offsets)
        saveTimelapses()
    }
    
    func moveTimelapse(source: IndexSet, destination: Int) {
        allTimelapses.move(fromOffsets: source, toOffset: destination)
        saveTimelapses()
    }
    
    func deleteImages(_ offsets: IndexSet, id: UUID) {
        for var timelapse in allTimelapses {
            if timelapse.id == id {
                timelapse.images.remove(atOffsets: offsets)
                print(timelapse.images.count)
                saveTimelapses()
            }
        }
    }

}




struct GalleryView: View {
    
    let viewColumns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    
    @ObservedObject var dataProvider = DataProvider.shared
    
    
    
    var body: some View {
        
        
        
        GeometryReader { geometry in
            
            let columns = [
                GridItem(.adaptive(minimum: geometry.size.width * 0.3))
                ]
            
            ScrollView {
                LazyVGrid(columns: columns) {
                        ForEach(dataProvider.allTimelapses, id: \.self) { timelapse in
                            
                            NavigationLink(value: timelapse) {
                                
                                VStack {
                                    Image(uiImage: UIImage(data: timelapse.images[0].raw)!)
                                        .resizable()
                                        .frame(width: geometry.size.width * 0.28, height: geometry.size.height * 0.28, alignment: .center)
                                    
                                    Text(timelapse.title)
                                        .font(.body)
                                    
                                }
                                
                            }
                            
                        }
                        
                    }
                }
                .navigationTitle("Timelapses")
                .navigationDestination(for: Timelapse.self) { t in
                    TimelapseView(timelapse: t)
            }
            
            
            
           
        }
    }
}

struct GalleryView_Previews: PreviewProvider {
    static var previews: some View {
        GalleryView()
        
    }
}
