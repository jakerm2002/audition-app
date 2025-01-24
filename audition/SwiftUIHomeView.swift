//
//  SwiftUIHomeView.swift
//  audition
//
//  Created by Jake Medina on 1/22/25.
//

import SwiftUI

struct CardView: View {
    
    @StateObject var model: AuditionDataModel
    
    var body: some View {
        NavigationLink(destination: SwiftUIDrawingView().environmentObject(model)) {
            VStack(spacing: 0.0) {
                HStack {
                    Group {
                        if let image = model.thumbnail {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } else {
                            Image(systemName: "exclamationmark.triangle.fill").imageScale(.large)
                        }
                    }
                }
                .padding(.all)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .background(Color.white)
                VStack(alignment: .leading) {
                    Group {
                        Text("Drawing name").fontWeight(.bold)
                        Text("Last modified").foregroundStyle(.secondary).font(.subheadline)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8.0)
                .padding(.horizontal, 10.0)
                .background(Color(uiColor: .systemGray6))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipShape(.rect(cornerRadius: 12))
            .shadow(radius: 5)
        }.foregroundStyle(.primary)
    }
}

struct SwiftUIHomeView: View {
    
    let columns = [GridItem](repeating: GridItem(.flexible(), spacing: 16), count: 5)
    
    @State var models: [AuditionDataModel] = [AuditionDataModel(), AuditionDataModel(), AuditionDataModel(), AuditionDataModel(), AuditionDataModel()]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns) {
                    ForEach(models) { model in
                        CardView(model: model)
                            .frame(height: 175)
                    }
                }.padding()
            }.navigationTitle("Drawings")
        }
    }
}

#Preview {
    SwiftUIHomeView()
}
