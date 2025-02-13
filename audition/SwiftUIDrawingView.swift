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
    
    @State var fromHomeView: Bool
    
    // used to force replacement of PKCanvasView (call MyCanvas.makeUIView) when a drawing is changed
    @State private var updatesCounter = 0
    @State private var toolPicker = PKToolPicker()
    
    var body: some View {
        MyCanvas(rendition: $rendition, toolPicker: $toolPicker)
            .id(updatesCounter)
            .toolbar {
                NavigationLink("Tree") {
                    SwiftUITreeView(updatesCounter: $updatesCounter).environmentObject(dataModel)
                }
                NavigationLink("Log") {
                    SwiftUILogView(rendition: $rendition, updatesCounter: $updatesCounter).environmentObject(dataModel)
                }
                Button("Branch", action: branchButtonPressed)
                Button("Commit to '\(dataModel.shortHEAD)'", action: commitButtonPressed)
            }
            .toolbarRole(.editor)
            .navigationTitle(dataModel.shortHEAD)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if fromHomeView {
                    fromHomeView = false
                    loadInitialDrawing()
                }
                print("SwiftUIDrawingView received: \(dataModel.description) with thumbnail \(dataModel.thumbnail?.size.width ?? -1)")
            }
    }
    
    func loadInitialDrawing() {
        do {
            let mostRecentBlob = try dataModel.showBlobs()[0]
            rendition = try mostRecentBlob.createDrawing()
            print("SwiftUIDrawingView found initial drawing to display")
        } catch {
            print("error: failed to load initial drawing from AuditionDataModel")
        }
    }
    
    func storeDataModel() throws {
        try dataModel.add(AuditionFile(from: rendition, name: "drawing"))
        _ = try dataModel.commit(message: "new drawing")
    }
    
    func branchButtonPressed() {
        print("branch button pressed")
        let count = dataModel.branches.count
        do {
            let branchName = "branch \(count)"
            try dataModel.checkout(branch: branchName, newBranch: true)
            print("Branch created. You are now on branch '\(branchName)'")
            
        } catch let error {
            print("\(error)")
        }
    }
    
    func commitButtonPressed() {
        print("commit button pressed")
        
        if rendition.bounds.isEmpty {
            print("Drawing is empty, skipping commit.")
        } else {
            do {
                try storeDataModel()
                print("storeDataModel succeeded")
            } catch let error{
                print("storeDataModel FAILED: \(error)")
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
        canvasView.delegate = context.coordinator // new
        canvasView.becomeFirstResponder()
        // TODO: figure out if dark mode should be supported
        // TODO: if dark mode supported, .unspecified doesn't follow system color theme, needs fix
        toolPicker.colorUserInterfaceStyle = .unspecified
        toolPicker.overrideUserInterfaceStyle = .unspecified
        // TODO: if dark mode supported, figure out if we need to convert colors that the PKInkingTool draws
//        let color = PKInkingTool.convertColor(.white, from: .light, to: .dark)
//        let tool = PKInkingTool(.pen, color: color, width: CGFloat(width.rawValue))
        toolPicker.setVisible(true, forFirstResponder: canvasView)
        toolPicker.addObserver(canvasView)
        return canvasView
    }

    func updateUIView(_ canvasView: PKCanvasView, context: Context) {
//        canvasView.delegate = nil
        // if the below line is commented out, there is a chance that the two drawings could become un-synchronized
        // however, the below line could cause slowdown due to trying to set the canvasView.drawing every time,
        // even though there is a reasonable belief that they will be the same
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
        // using DispatchQueue.main.async could cause problems if the setting of rendition
        // is delayed long enough where if the user presses 'Commit' before rendition is set,
        // then the changes will not be added to the commit
//        DispatchQueue.main.async {
            self.parent.rendition = canvasView.drawing
//        }
    }
}

#Preview {
    let sampleModel = AuditionDataModel()
    SwiftUIDrawingView(fromHomeView: true).environmentObject(sampleModel)
}
