//
//  SampleDataModels.swift
//  audition
//
//  Created by Jake Medina on 2/17/25.
//

import Foundation

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

func generateSampleDataThreeStaticCommits() -> AuditionDataModel {
    let c1 = Commit(tree: "", parents: [], message: "", timestamp: .init(timeIntervalSince1970: 0))
    let c2 = Commit(tree: "", parents: [c1.sha256DigestValue!], message: "", timestamp: .init(timeIntervalSince1970: 1))
    let c3 = Commit(tree: "", parents: [c1.sha256DigestValue!], message: "", timestamp: .init(timeIntervalSince1970: 2))
    
    let a1 = AuditionDataModel()
    a1.unsafeSetObject(key: c1.sha256DigestValue!, value: c1)
    a1.unsafeSetObject(key: c2.sha256DigestValue!, value: c2)
    a1.unsafeSetObject(key: c3.sha256DigestValue!, value: c3)
    
    a1.unsafeSetBranch(branchName: "main", commitHash: c2.sha256DigestValue!)
    a1.unsafeSetBranch(branchName: "branch1", commitHash: c3.sha256DigestValue!)
    a1.unsafeSetBranch(branchName: "branch2", commitHash: c3.sha256DigestValue!)
    a1.unsafeSetBranch(branchName: "branch4", commitHash: c3.sha256DigestValue!)
    a1.unsafeSetBranch(branchName: "branch5", commitHash: c3.sha256DigestValue!)
    
    return a1
}
