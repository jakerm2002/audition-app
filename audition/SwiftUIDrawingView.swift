//
//  SwiftUIDrawingView.swift
//  audition
//
//  Created by Jake Medina on 1/22/25.
//

import SwiftUI
import PencilKit

struct Canvas {
    var view: PKCanvasView = PKCanvasView()
    var id: Int = 0
    
    mutating func changeDrawing(data: Data) {
        do {
            let d = try PKDrawing(data: data)
            let new = PKCanvasView()
            new.drawing = d
            view = new
            id += 1
            print("changing drawing")
        }
        catch {
            print("changeDrawing failed")
        }
    }
}

struct SwiftUIDrawingView: View {
    
    @EnvironmentObject var dataModel: AuditionDataModel
    @State private var rendition = PKDrawing()
    @State private var toolPicker = PKToolPicker()
    
    var body: some View {
        MyCanvas(rendition: $rendition, toolPicker: $toolPicker)
            .toolbar {
                Button("Tree") {}
                NavigationLink("Log") {
                    SwiftUILogView(rendition: $rendition).environmentObject(dataModel)
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
                print("Data model stored succesfully")
            } catch {
                print("Storing data model failed")
            }
        }
    }
}

struct MyCanvas: UIViewRepresentable {
    @Binding var rendition: PKDrawing
    @Binding var toolPicker: PKToolPicker
    
    func makeUIView(context: Context) -> PKCanvasView {
        print("makeUIView")
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
