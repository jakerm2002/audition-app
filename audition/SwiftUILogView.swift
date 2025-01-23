//
//  SwiftUILogView.swift
//  audition
//
//  Created by Jake Medina on 1/22/25.
//

import SwiftUI

struct SwiftUILogView: View {
    
    @EnvironmentObject var dataModel: AuditionDataModel
    
    // Calculate the commits array once and store it in a property
    @State var commits: [Commit] = []
    @State private var singleSelection: String? = nil
    
    // Initialize the commits array in the initializer
    
    var body: some View {
        List(commits, id: \.sha256DigestValue!, selection: $singleSelection) { commit in
            LazyVStack(alignment: .leading) {
                Button(action: {
                            print("Perform action here...")
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
}

#Preview {
    SwiftUILogView()
}
