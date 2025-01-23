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
    @State private var canvas: Canvas = Canvas()
    
    @State private var toolPicker = PKToolPicker()
    
    var body: some View {
        MyCanvas(canvas: $canvas, toolPicker: $toolPicker)
            .toolbar {
                Button("Tree") {}
                NavigationLink("Log") {
                    SwiftUILogView(canvas: $canvas).environmentObject(dataModel)
                }
                Button("Branch") {
                    print("branch button pressed")
                }
                Button("Commit to '\(dataModel.currentBranch ?? dataModel.HEAD)'", action: commitButtonPressed)
            }
            .toolbarRole(.editor)
    }
    
    func storeDataModel() throws {
        try dataModel.add(AuditionFile(content: canvas.view.drawing.dataRepresentation(), name: "drawing"))
        _ = try dataModel.commit(message: "new drawing")
    }
    
    func commitButtonPressed() {
        print("commit button pressed")
        
        if canvas.view.drawing.bounds.isEmpty {
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
    @Binding var canvas: Canvas
    @Binding var toolPicker: PKToolPicker
    
    func makeUIView(context: Context) -> PKCanvasView {
        print("makeUIView")
        canvas.view.drawingPolicy = .anyInput
        canvas.view.becomeFirstResponder()
        toolPicker.setVisible(true, forFirstResponder: canvas.view)
        toolPicker.addObserver(canvas.view)
        return canvas.view
    }

    func updateUIView(_ canvasView: PKCanvasView, context: Context) { }
    
}

#Preview {
    SwiftUIDrawingView()
}
