//
//  SwiftUIHomeView.swift
//  audition
//
//  Created by Jake Medina on 1/22/25.
//

import SwiftUI

struct CardView: View {
    
    var image: UIImage?
    
    init(image: UIImage? = nil) {
        self.image = image
    }
    
    var body: some View {
        VStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Image(systemName: "exclamationmark.triangle.fill").imageScale(.large)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .clipShape(.rect(cornerRadius: 12))
        .clipped()
        .shadow(radius: 5)
    }
}

struct SwiftUIHomeView: View {
    
    let columns = [GridItem](repeating: GridItem(.flexible(), spacing: 16), count: 5)
    
    let models: [AuditionDataModel] = [AuditionDataModel(), AuditionDataModel(), AuditionDataModel(), AuditionDataModel(), AuditionDataModel()]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns) {
                    ForEach(models) { model in
                        if let thumbnail = model.thumbnail {
                            CardView(image: thumbnail)
                                .frame(height: 100)
                        }
                    }
                }.padding()
            }.navigationTitle("Drawings")
        }
    }
}

#Preview {
    SwiftUIHomeView()
}
