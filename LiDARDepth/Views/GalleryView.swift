//
//  GalleryView.swift
//  LiDARDepth
//
<<<<<<< HEAD
//  Created by Matt Franchi on 12/8/22.

//  Copyright © 2022 Apple. All rights reserved.
//

import SwiftUI

<<<<<<< HEAD
struct TL_Image: Codable, Identifiable {
    var id = UUID()
    let raw: Data
    let depth: Data
    
    //init(raw: UIImage) {
        //self.raw = raw.pngData()!
    //}
    
}

struct Timelapse: Codable, Identifiable {
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
            var decodedTimelapses = try! decoder.decode([Timelapse].self, from: data)
            
            for var decodedTimelapse in decodedTimelapses {
                decodedTimelapse.images = try! decoder.decode([TL_Image].self, from:data)
            }
            
            return decodedTimelapses
        } catch {
            return []
        }
        
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

}




struct GalleryView: View {
    
    let viewColumns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    
    @ObservedObject var dataProvider = DataProvider.shared
    
    
    
    var body: some View {
        NavigationView {
            List {
                
                ForEach(dataProvider.allTimelapses) { timelapse in
                    
                    LazyVGrid(columns: viewColumns) {
                        
                        Text("\(timelapse.title)")
                            .font(.headline)
                        
                        Image(uiImage: (UIImage(data: timelapse.images[0].raw)!))
                        
                        
                        
                    }
                    
                }
                
            }
        }
        .navigationTitle(Text("Timelapses"))
        .listStyle(InsetListStyle())
    }
}

struct GalleryView_Previews: PreviewProvider {
    static var previews: some View {
        GalleryView()
=======
struct GalleryView: View {
    @State private var blankImage = UIImage(systemName: "placeholdertext.fill")
    
    private var url: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("image.jpg")
    }

    var body: some View {
        Image(uiImage: blankImage ?? UIImage())
            .resizable()
            .onAppear {
                url.loadImage(&blankImage)
            }
>>>>>>> 7a567770b02262fe9cae3d0c6bcc2dc2c0881f69
    }
}
