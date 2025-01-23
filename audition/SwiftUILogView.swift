//
//  SwiftUILogView.swift
//  audition
//
//  Created by Jake Medina on 1/22/25.
//

import SwiftUI

struct SwiftUILogView: View {
    
//    var commits = [Commit]()
    @State var commits: [Commit] = [Commit(tree: "0155eb4229851634a0f03eb265b69f5a2d56f341", parents: ["fdf4fc3344e67ab068f836878b6c4951e3b15f3d"], message: "Second commit", timestamp: .now)]
    
    
    var body: some View {
        List(commits, id: \.sha256DigestValue!) { commit in
            LazyVStack(alignment: .leading) {
                Text(commit.message)
                HStack {
                    Text(commit.sha256DigestValue!.prefix(7))
                    Text(DateFormatter.localizedString(from: commit.timestamp, dateStyle: .medium, timeStyle: .medium))
                }
            }
        }.onAppear {
            navigationTitle("Commits from \(commits.first!.sha256DigestValue!.prefix(7))")
        }
    }
}

#Preview {
    SwiftUILogView()
}
