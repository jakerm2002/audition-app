//
//  SwiftUILogView.swift
//  audition
//
//  Created by Jake Medina on 1/22/25.
//

import SwiftUI
import PencilKit

struct SwiftUILogView: View {
    
    @EnvironmentObject var dataModel: AuditionDataModel
    @ObservedObject var canvas: Canvas
    
    // Calculate the commits array once and store it in a property
    @State var commits: [Commit] = []
    @State private var singleSelection: String? = nil
    
    // Initialize the commits array in the initializer
    
    var body: some View {
        List(commits, id: \.sha256DigestValue!, selection: $singleSelection) { commit in
            LazyVStack(alignment: .leading) {
                Button(action: {setDrawingData(commit: commit)},
                       label: {
                            VStack(alignment: .leading) {
                                Text(commit.message).tint(.primary)
                                HStack {
                                    Text(commit.sha256DigestValue!.prefix(7)).tint(.primary)
                                    Text(DateFormatter.localizedString(from: commit.timestamp, dateStyle: .medium, timeStyle: .medium)).tint(.primary)
                                }
                            }
                })
                .contentShape(Rectangle())
            }
        }
        .navigationTitle(commits.isEmpty ? "Log" : "Commits from \(commits.first!.sha256DigestValue!.prefix(7))")
        .overlay {
            if commits.isEmpty {
                ContentUnavailableView("No Commits", image: "")
            }
        }
        .onAppear {
            do {
                commits = try dataModel.log()
            } catch {
                print("error: No commits yet")
                commits = []
            }
        }
    }
    
    func setDrawingData(commit: Commit) {
        // grab the blob that was included in the commit
        // we're assuming there will only be one, this will NOT BE TRUE in the future
        // once we are committing individual strokes instead of the entire drawing
        do {
            let aBlob = try dataModel.showBlobs(commit: commit.sha256DigestValue!)[0]
            let d = try PKDrawing(data: aBlob.contents)
            let new = PKCanvasView()
            new.drawing = d
//                canvas.view.removeFromSuperview()
            canvas.view = new
//            view.addSubview(canvas.view)
            print("exiting setDrawingData")
        } catch {
            print("Setting drawing data failed")
        }
    }
}

#Preview {
    SwiftUILogView(canvas: ObservedObject(wrappedValue: Canvas()).wrappedValue)
}
