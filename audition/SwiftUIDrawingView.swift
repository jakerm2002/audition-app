//
//  SwiftUIDrawingView.swift
//  audition
//
//  Created by Jake Medina on 1/22/25.
//

import SwiftUI
import PencilKit

struct SwiftUIDrawingView: View {
    
    @State private var canvasView = PKCanvasView()
    @State private var toolPicker = PKToolPicker()
    
    var body: some View {
        MyCanvas(canvasView: $canvasView, toolPicker: $toolPicker)
            .toolbar {
                Button("Tree") {}
                Button("Log") {}
                Button("Branch") {}
                Button("Commit") {}
            }
            .toolbarRole(.editor)
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
