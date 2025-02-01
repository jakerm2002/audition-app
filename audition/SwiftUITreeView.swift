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

struct RoundedCircleStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(width: 100, height: 100)
            .background(Circle().stroke())
            .padding(10)
    }
}

struct NodeView: View {
    let commitID: String
    let model: AuditionDataModel
    @Binding var commitInfo: [String : AuditionDataModel.CommitWalkInfo]
    
    func getParentsToRender() -> [String] {
        let commitObj = model.objects[commitID] as! Commit
        let parents = commitObj.parents
        var result: [String] = []
        for parent in parents {
            let currentParentInfo = commitInfo[parent]
            print("CURRENT IN DEGREE FOR COMMIT \(parent.prefix(7)) IS \(currentParentInfo!.inDegree)")
            let newInDegree = currentParentInfo!.inDegree - 1
            print("NEW IN DEGREE FOR COMMIT \(parent.prefix(7)) IS \(newInDegree)")
            if newInDegree == 0 {
                result.append(parent)
            }
            commitInfo[parent] = AuditionDataModel.CommitWalkInfo(visited: currentParentInfo!.visited, inDegree: newInDegree)
            print("CONFIRM UPDATING INDEGREE FOR COMMIT \(parent.prefix(7)): \(commitInfo[parent]!)")
        }
        print("parents to render are \(result)")
        return result
    }

    var body: some View {
        VStack {
//            Text(commitID.prefix(7)).modifier(RoundedCircleStyle())
            Text("\(commitInfo[commitID]!.inDegree)").modifier(RoundedCircleStyle())
            HStack { //HStack may not be necessary
                ForEach(getParentsToRender(), id: \.self) { parent in
                    NodeView(commitID: parent, model: model, commitInfo: $commitInfo)
                }
            }
        }
    }
}

struct SwiftUITreeView: View {
    let model: AuditionDataModel
    @State var commitInfo: [String : AuditionDataModel.CommitWalkInfo]
    
    init(model: AuditionDataModel) {
        self.model = model
        do {
            self.commitInfo = try model.computeInDegreeDict()
        } catch {
            print("error: generating commit information about indegrees failed, returning empty commit info")
            self.commitInfo = [:]
        }
    }
    
    var body: some View {
        HStack {
            ForEach(Array(model.branches.values), id: \.self) { branchRef in
                if let info = commitInfo[branchRef], info.inDegree == 0 {
                    NodeView(commitID: branchRef, model: model, commitInfo: $commitInfo)
                }
            }
        }
    }
}

func generateSampleData() -> AuditionDataModel{
    do {
        let content1 = Data(String(stringLiteral: "test one").utf8)
        let filename1 = "test1.txt"
        
        let f1 = AuditionFile(
            content: content1,
            name: filename1
        )
        
        let a1 = AuditionDataModel()
        try a1.add(f1)
        
        let commitMessage1 = "initial commit"
        var commit1: String = try a1.commit(message: commitMessage1)
        print("commit1 \(commit1)")
        
        let content2 = Data(String(stringLiteral: "test two").utf8)
        let filename2 = "test2.txt"
        
        let f2 = AuditionFile(
            content: content2,
            name: filename2
        )
        
        try a1.add(f2)
        
        let commitMessage2 = "second commit"
        var commit2: String = try a1.commit(message: commitMessage2)
        print("commit2 \(commit2)")
        
        return a1
    } catch {
        print("error: prevew of SwiftUITreeView failed, returning an empty model")
        return AuditionDataModel()
    }
}

func generateSampleDataThreeCommits() -> AuditionDataModel {
    do {
        let content1 = Data(String(stringLiteral: "test one").utf8)
        let filename1 = "test1.txt"
        let f1 = AuditionFile(
            content: content1,
            name: filename1
        )
        
        let content2 = Data(String(stringLiteral: "test two").utf8)
        let filename2 = "test2.txt"
        
        let f2 = AuditionFile(
            content: content2,
            name: filename2
        )
        
        let content3 = Data(String(stringLiteral: "test three").utf8)
        let filename3 = "test3.txt"
        
        let f3 = AuditionFile(
            content: content3,
            name: filename3
        )
        
        let commitMessage1 = "initial commit"
        let commitMessage2 = "second commit"
        let commitMessage3 = "third commit"
        
        // CREATE A NEW MODEL
        let a2 = AuditionDataModel()
        try a2.add(f1)
        
        let commit1 = try a2.commit(message: commitMessage1)
        print("commit1 \(commit1)")
        
        // add a branch from the initial commit
        try a2.createBranch(branchName: "b1")
        try a2.createBranch(branchName: "b2")
        
        try a2.checkout(branch: "b1")
        try a2.add(f2)
        let commit2 = try a2.commit(message: commitMessage2)
        print("commit2 \(commit2)")
        
        try a2.checkout(branch: "b2")
        try a2.add(f3)
        var commit3: String = try a2.commit(message: commitMessage3)
        print("commit3 \(commit3)")
        
        return a2
    } catch {
        print("error: prevew of SwiftUITreeView failed, returning an empty model")
        return AuditionDataModel()
    }
}

#Preview {
//    SwiftUITreeView(model: generateSampleData())
    SwiftUITreeView(model: generateSampleDataThreeCommits())
}
