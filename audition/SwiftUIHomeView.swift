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
        VStack(spacing: 0.0) {
            HStack {
                Group {
                    if let image {
                        Image("mclaren")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else {
                        Image(systemName: "exclamationmark.triangle.fill").imageScale(.large)
                    }
                }
            }
            .frame(alignment: .center)
            VStack(alignment: .leading) {
                Group {
                    Text("Drawing name").fontWeight(.bold)
                    Text("Last modified").foregroundStyle(.secondary).font(.subheadline)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8.0)
            .padding(.horizontal, 10.0)
            .background(.quinary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .clipShape(.rect(cornerRadius: 12))
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
                                .frame(height: 175)
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
