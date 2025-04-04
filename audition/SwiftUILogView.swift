//
//  SwiftUILogView.swift
//  audition
//
//  Created by Jake Medina on 1/22/25.
//

import SwiftUI
import PencilKit


struct SwiftUILogDetailView: View {
    
    @EnvironmentObject var dataModel: AuditionDataModel
    @State private var commitSelection: String? = nil
    
    @Binding var commits: [Commit]
    @Binding var rendition: PKDrawing
    @Binding var updatesCounter: Int
    
    @Environment(\.dismiss) var dismiss
    
    func setDrawingData(commit: Commit) {
        // grab the blob that was included in the commit
        // we're assuming there will only be one, this will NOT BE TRUE in the future
        // once we are committing individual strokes instead of the entire drawing
        do {
            let strokeBlobs = try dataModel.showBlobs(commit: commit.sha256DigestValue!)
            let newDrawing = try createDrawing(strokes: strokeBlobs)
            rendition = newDrawing
            updatesCounter += 1
            print("setDrawingData succeeded")
        } catch let error {
            print("setDrawingData FAILED to get blobs: \(error)")
        }
    }
    
    var body: some View {
        List(commits, id: \.sha256DigestValue!, selection: $commitSelection) { commit in
            LazyVStack(alignment: .leading) {
                Button(action: {
                            do {
                                try dataModel.checkout(commit: commit.sha256DigestValue!)
                                setDrawingData(commit: commit)
                                dismiss()
                            } catch let error {
                                print("ERROR in SwiftUILogView: Checking out ref failed: \(error)")
                            }
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
        .overlay {
            if commits.isEmpty {
                ContentUnavailableView("No Commits", image: "")
            }
        }
    }
}


struct SwiftUILogView: View {
    
    @EnvironmentObject var dataModel: AuditionDataModel
    @State var branches: [String : String] = [:]
    @State var commits: [Commit] = []
    @State private var sidebarSelection: String? = nil
    
    @Binding var rendition: PKDrawing
    @Binding var updatesCounter: Int
    
    @Environment(\.dismiss) var dismiss
    
    func setDrawingData(commit: Commit) {
        // grab the blob that was included in the commit
        // we're assuming there will only be one, this will NOT BE TRUE in the future
        // once we are committing individual strokes instead of the entire drawing
        do {
            let strokeBlobs = try dataModel.showBlobs(commit: commit.sha256DigestValue!)
            let newDrawing = try createDrawing(strokes: strokeBlobs)
            rendition = newDrawing
            updatesCounter += 1
            print("setDrawingData succeeded")
        } catch let error {
            print("setDrawingData FAILED to get blobs: \(error)")
        }
    }
    
    func setCommitsFromBranch(branch: String) {
        do {
            commits = try dataModel.log(branch: branch)
        } catch let error {
            print("ERROR in SwiftUILogView: Couldn't log branch \(branch): \(error)")
        }
    }
    
    func setCommitsFromHEAD() {
        do {
            commits = try dataModel.log()
        } catch let error {
            print("ERROR in SwiftUILogView: Couldn't log HEAD \(dataModel.HEAD): \(error)")
        }
    }
    
    var body: some View {
        NavigationSplitView(sidebar: {
            List (branches.sorted(by: <), id: \.key, selection: $sidebarSelection) { key, value in
                HStack {
                    NavigationLink(key, value: key)
                    Spacer()
                    Button(action: {
                        do {
                            try dataModel.checkout(branch: key)
                            guard let commit = dataModel.objects[value] as? Commit else {
                                throw AuditionError.runtimeError("Branch ref does not point to a commit.")
                            }
                            setDrawingData(commit: commit)
                            dismiss()
                        } catch let error {
                            print("ERROR in SwiftUILogView: Checking out branch failed: \(error)")
                        }
                    }, label: {
                        Image(systemName: "arrow.left")
                    })
                    .buttonStyle(.bordered)
                }
            }
            .navigationTitle("Branches")
            .onAppear {
                branches = dataModel.branches
            }
        }, detail: {
            // HEAD points to a branch that has been committed to
            if let branchName = sidebarSelection {
                SwiftUILogDetailView(commits: $commits, rendition: $rendition, updatesCounter: $updatesCounter)
                    .navigationTitle(branchName)
                    .onAppear { setCommitsFromBranch(branch: branchName) }
                    .onChange(of: branchName) { setCommitsFromBranch(branch: branchName) }
            }
            // HEAD points to a commit
            else if dataModel.objects[dataModel.HEAD] is Commit {
                SwiftUILogDetailView(commits: $commits, rendition: $rendition, updatesCounter: $updatesCounter)
                    .navigationTitle(dataModel.shortHEAD)
                    .onAppear { setCommitsFromHEAD() }
            }
            // HEAD points to a branch with no commits (it's probably the default branch, 'main')
            else {
                SwiftUILogDetailView(commits: $commits, rendition: $rendition, updatesCounter: $updatesCounter)
                    .navigationTitle(String(dataModel.HEAD))
                    .onAppear { setCommitsFromHEAD() }
            }
        })
        .onAppear {
            if let currentBranch = dataModel.currentBranch {
                sidebarSelection = currentBranch
            }
        }
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

    }
}

#Preview {
    var model: AuditionDataModel = generateSampleDataThreeCommits()
    SwiftUILogView(rendition: Binding.constant(PKDrawing()), updatesCounter: Binding.constant(0)).environmentObject(model)
}
