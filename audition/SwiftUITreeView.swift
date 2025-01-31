//
//  SwiftUITreeView.swift
//  audition
//
//  Created by Jake Medina on 1/30/25.
//

import Foundation
import SwiftUI

/*
struct SwiftUITreeView: View {
    var root: Commit
    
    var body: some View {
        Diagram(node: root) { value in
            Text("\(value.sha256DigestValue!)")
        }
    }
}

struct Diagram<V: View>: View {
    let node: Commit
    let view: (Commit) -> V
    
    var body: some View {
        VStack {
            view(node)
            HStack {
                
            }
        }
    }
}
 */

/*
// return the commit hashes of all branch refs
func getAllBranchRefs(model: AuditionDataModel) -> [String] {
    return Array(model.branches.values
}
*/

struct CommitWalkInfo {
    var visited: Bool = true
    var inDegree: Int = 0
}

func computeInDegreeDict(model: AuditionDataModel) throws -> [String : CommitWalkInfo] {
    var commits: [String : CommitWalkInfo] = [:]
    
    for branchRef in model.branches.values {
        try countInDegreesFromCommit(id: branchRef, commits: &commits, model: model)
    }
    
    return commits
}

// call this function on all branch refs
func countInDegreesFromCommit(id: String, commits: inout [String : CommitWalkInfo], model: AuditionDataModel) throws {
    if commits[id]?.visited == false {
        commits[id] = CommitWalkInfo()
        guard let commitObj: Commit = model.objects[id] as? Commit else {
            throw AuditionError.runtimeError("error: countInDegreesFromCommit looking at a branchRef that does not point to a valid commit.")
        }
        let parents: [String] = commitObj.parents
        for p in parents {
            commits[p, default: CommitWalkInfo(visited: false)].inDegree += 1
            try countInDegreesFromCommit(id: p, commits: &commits, model: model)
        }
    }
}

#Preview {
//    let sampleModel = AuditionDataModel()
//    SwiftUITreeView(root: <#T##Commit#>)
}
