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
    @State private var rendition = PKDrawing()
    
    // used to force replacement of PKCanvasView (call MyCanvas.makeUIView) when a drawing is changed
    @State private var updatesCounter = 0
    @State private var toolPicker = PKToolPicker()
    
    var body: some View {
        MyCanvas(rendition: $rendition, toolPicker: $toolPicker)
            .id(updatesCounter)
            .toolbar {
                Button("Tree") {}
                NavigationLink("Log") {
                    SwiftUILogView(rendition: $rendition, updatesCounter: $updatesCounter).environmentObject(dataModel)
                }
                Button("Branch") {
                    print("branch button pressed")
                }
                Button("Commit to '\(dataModel.currentBranch ?? dataModel.HEAD)'", action: commitButtonPressed)
            }
            .toolbarRole(.editor)
    }
    
    func storeDataModel() throws {
        try dataModel.add(AuditionFile(content: rendition.dataRepresentation(), name: "drawing"))
        _ = try dataModel.commit(message: "new drawing")
    }
    
    func commitButtonPressed() {
        print("commit button pressed")
        
        if rendition.bounds.isEmpty {
            print("Drawing is empty, skipping commit.")
        } else {
            do {
                try storeDataModel()
                print("storeDataModel succeeded")
            } catch {
                print("storeDataModel FAILED")
            }
        }
    }
}

struct MyCanvas: UIViewRepresentable {
    @Binding var rendition: PKDrawing
    @Binding var toolPicker: PKToolPicker
    
    func makeUIView(context: Context) -> PKCanvasView {
        print("makeUIView called")
        let canvasView = PKCanvasView()
        canvasView.drawing = rendition
        canvasView.drawingPolicy = .anyInput
        canvasView.delegate = context.coordinator // new
        canvasView.becomeFirstResponder()
        toolPicker.setVisible(true, forFirstResponder: canvasView)
        toolPicker.addObserver(canvasView)
        return canvasView
    }

    func updateUIView(_ canvasView: PKCanvasView, context: Context) {
        canvasView.delegate = nil
        canvasView.drawing = rendition
        canvasView.delegate = context.coordinator
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
}

// MARK: - Coordinator
class Coordinator: NSObject {
    let parent: MyCanvas

    // MARK: - Initializers
    init(parent: MyCanvas) {
        self.parent = parent
    }
}

// MARK: - PKCanvasViewDelegate
extension Coordinator: PKCanvasViewDelegate {
    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        DispatchQueue.main.async {
            self.parent.rendition = canvasView.drawing
        }
    }
}

#Preview {
    SwiftUIDrawingView()
}
