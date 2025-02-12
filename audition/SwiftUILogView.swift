//
//  SwiftUILogView.swift
//  audition
//
//  Created by Jake Medina on 1/22/25.
//

import SwiftUI
import PencilKit

/*
struct SwiftUILogDetailView: View {
    
    @EnvironmentObject var dataModel: AuditionDataModel
    
    var body: some View {
        List(commits, id: \.sha256DigestValue!, selection: $singleSelection) { commit in
            LazyVStack(alignment: .leading) {
                Button(action: {
                            do {
                                try dataModel.checkout(commit: commit.sha256DigestValue!)
                            } catch {
                                print("ERROR: Checking out ref failed")
                            }
                            setDrawingData(commit: commit)
                            dismiss()
                        },
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
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    updatesCounter += 1
                    dismiss()
                } label: {
                    Image(systemName: "chevron.backward")
                }
            }
        }
        .overlay {
            if commits.isEmpty {
                ContentUnavailableView("No Commits", image: "")
            }
        }
        .onAppear {
            do {
                commits = try dataModel.log()
            } catch let error{
                print("ERROR: Error showing log: \(error)")
                commits = []
            }
        }
    }
}
 */

struct SwiftUILogView: View {
    
    @EnvironmentObject var dataModel: AuditionDataModel
    @Binding var rendition: PKDrawing
    @Binding var updatesCounter: Int
    
    @State var branches: [String : String] = [:]
    @State var commits: [Commit] = []
    @State private var singleSelection: String? = nil
    @State private var sidebarSelection: String? = nil
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationSplitView(sidebar: {
            List (branches.sorted(by: >), id: \.key, selection: $sidebarSelection) { key, value in
                NavigationLink(key, value: key)
            }
            .navigationTitle("Branches")
            .onAppear {
                branches = dataModel.branches
            }
        }, detail: {
            if let branchName = sidebarSelection {
                Text(branchName)
                    .onChange(of: branchName) {
                        print("branch changed")
                    }
            } else {
                
            }
        })

    }
    
    func setDrawingData(commit: Commit) {
        // grab the blob that was included in the commit
        // we're assuming there will only be one, this will NOT BE TRUE in the future
        // once we are committing individual strokes instead of the entire drawing
        do {
            let aBlob = try dataModel.showBlobs(commit: commit.sha256DigestValue!)[0]
            let newDrawing = try PKDrawing(data: aBlob.contents)
            rendition = newDrawing
            updatesCounter += 1
            print("setDrawingData succeeded")
        } catch let error {
            print("setDrawingData FAILED to get blobs: \(error)")
        }
    }
}

#Preview {
    var model: AuditionDataModel = generateSampleDataThreeCommits()
    SwiftUILogView(rendition: Binding.constant(PKDrawing()), updatesCounter: Binding.constant(0)).environmentObject(model)
}
