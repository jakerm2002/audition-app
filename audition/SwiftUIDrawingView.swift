//
//  SwiftUIDrawingView.swift
//  audition
//
//  Created by Jake Medina on 1/22/25.
//

import SwiftUI
import PencilKit

struct SwiftUIDrawingView: View {
    
    @EnvironmentObject var dataModel: AuditionDataModel
    
    @State private var canvasView = PKCanvasView()
    @State private var toolPicker = PKToolPicker()
    
    var body: some View {
        MyCanvas(canvasView: $canvasView, toolPicker: $toolPicker)
            .toolbar {
                Button("Tree") {}
                NavigationLink("Log") {
                    SwiftUILogView().environmentObject(dataModel)
                }
                Button("Branch") {
                    print("branch button pressed")
                }
                Button("Commit to '\(dataModel.currentBranch ?? dataModel.HEAD)'", action: commitButtonPressed)
            }
            .toolbarRole(.editor)
    }
    
    func storeDataModel() throws {
        try dataModel.add(AuditionFile(content: canvasView.drawing.dataRepresentation(), name: "drawing"))
        _ = try dataModel.commit(message: "new drawing")
    }
    
    func commitButtonPressed() {
        print("commit button pressed")
        
        if canvasView.drawing.bounds.isEmpty {
            print("Drawing is empty, skipping commit.")
        } else {
            do {
                try storeDataModel()
                print("Data model stored succesfully")
            } catch {
                print("Storing data model failed")
            }
        }
    }
}

struct MyCanvas: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    @Binding var toolPicker: PKToolPicker
    
    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.drawingPolicy = .anyInput
        canvasView.becomeFirstResponder()
        toolPicker.setVisible(true, forFirstResponder: canvasView)
        toolPicker.addObserver(canvasView)
        return canvasView
    }

    func updateUIView(_ canvasView: PKCanvasView, context: Context) { }
    
}

#Preview {
    SwiftUIDrawingView()
}
