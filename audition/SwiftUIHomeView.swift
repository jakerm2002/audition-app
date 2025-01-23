//
//  SwiftUIHomeView.swift
//  audition
//
//  Created by Jake Medina on 1/22/25.
//

import SwiftUI

struct SwiftUIHomeView: View {
    var body: some View {
        NavigationStack {
            NavigationLink("Start") {
                SwiftUIDrawingView().environmentObject(AuditionDataModel())
            }.navigationTitle("Drawings")
        }
    }
}

#Preview {
    SwiftUIHomeView()
}
