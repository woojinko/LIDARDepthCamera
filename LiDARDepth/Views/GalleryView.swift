//
//  GalleryView.swift
//  LiDARDepth
//
//  Created by Woojin Ko on 12/7/22.
//  Copyright © 2022 Apple. All rights reserved.
//

import SwiftUI

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
    }
}
