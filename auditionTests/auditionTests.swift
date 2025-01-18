//
//  auditionTests.swift
//  auditionTests
//
//  Created by Jake Medina on 1/17/25.
//

import Testing
import Foundation

@testable import audition

struct auditionTests {

    @Test func newCommit() async throws {
        let c2 = Commit(tree: "0155eb4229851634a0f03eb265b69f5a2d56f341", parents: ["fdf4fc3344e67ab068f836878b6c4951e3b15f3d"], message: "Second commit", timestamp: Date(timeIntervalSince1970: 1243041269))
        
        #expect(c2.description == "tree 0155eb4229851634a0f03eb265b69f5a2d56f341\nparent fdf4fc3344e67ab068f836878b6c4951e3b15f3d\n2009-05-23 01:14:29 +0000\n\nSecond commit")
        
        #expect(c2.sha256DigestValue == "b860f78c73c2d88b9fc751afe061ea1ea06b944dcc030820b7e893fe7ea1b028")
    }

    @Test func newTree() async throws {
        let t3 = Tree(entries: [
            TreeEntry(type: .tree, hash: "d8329fc1cc938780ffdd9f94e0d364e0ea74f579", name: "bak"),
            TreeEntry(type: .blob, hash: "fa49b077972391ad58037050f2a75f74e3671e92", name: "new.txt"),
            TreeEntry(type: .blob, hash: "1f7a7a472abf3dd9643fd615f6da379c4acb3e3a", name: "test.txt")
        ])
        
        #expect(t3.description == "tree d8329fc1cc938780ffdd9f94e0d364e0ea74f579      bak\nblob fa49b077972391ad58037050f2a75f74e3671e92      new.txt\nblob 1f7a7a472abf3dd9643fd615f6da379c4acb3e3a      test.txt")
        
        #expect(t3.sha256DigestValue == "f766552f1928a41844f69baaf8ffba74384bc1afe5df5f7a1107c83befc46f0e")
    }
    
    @Test func newBlob() async throws {
        let b3 = Blob(contents: Data(String(stringLiteral: "new file").utf8))
        
        #expect(b3.description == "8 bytes")
        
        #expect(b3.sha256DigestValue == "b37d2cbfd875891e9ed073fcbe61f35a990bee8eecbdd07f9efc51339d5ffd66")
    }
    
    @Test func updateIndex() async throws {
        let b1 = Blob(contents: Data(String(stringLiteral: "version 1").utf8))
        
        let a1 = AuditionDataModel()
        _ = a1.hash(obj: b1, write: true)
        try a1.updateIndex(sha256DigestValue: b1.sha256DigestValue!, name: "test.txt")
        
        #expect(a1.index == [TreeEntry(type: .blob, hash: b1.sha256DigestValue!, name: "test.txt")])
        
        let b2 = Blob(contents: Data(String(stringLiteral: "version 2").utf8))
        _ = a1.hash(obj: b2, write: true)
        try a1.updateIndex(sha256DigestValue: b2.sha256DigestValue!, name: "test.txt")
        
        #expect(a1.index == [TreeEntry(type: .blob, hash: b2.sha256DigestValue!, name: "test.txt")])
        
        let b3 = Blob(contents: Data(String(stringLiteral: "new file").utf8))
        _ = a1.hash(obj: b3, write: true)
        try a1.updateIndex(sha256DigestValue: b3.sha256DigestValue!, name: "new.txt")
        
        #expect(a1.index == [TreeEntry(type: .blob, hash: b2.sha256DigestValue!, name: "test.txt"), TreeEntry(type: .blob, hash: b3.sha256DigestValue!, name: "new.txt")])
    }
    
    @Test func writeTree() async throws {
        let b1 = Blob(contents: Data(String(stringLiteral: "version 1").utf8))
        let a1 = AuditionDataModel()
        _ = a1.hash(obj: b1, write: true)
        try a1.updateIndex(sha256DigestValue: b1.sha256DigestValue!, name: "test.txt")
        let b2 = Blob(contents: Data(String(stringLiteral: "version 2").utf8))
        _ = a1.hash(obj: b2, write: true)
        try a1.updateIndex(sha256DigestValue: b2.sha256DigestValue!, name: "test.txt")
        let b3 = Blob(contents: Data(String(stringLiteral: "new file").utf8))
        _ = a1.hash(obj: b3, write: true)
        try a1.updateIndex(sha256DigestValue: b3.sha256DigestValue!, name: "new.txt")
        
        let t1Hash = a1.writeTree()
        let t1 = a1.objects[t1Hash] as! Tree
        
        #expect(t1.entries.contains(TreeEntry(type: .blob, hash: b3.sha256DigestValue!, name: "new.txt")))
        #expect(t1.entries.contains(TreeEntry(type: .blob, hash: b2.sha256DigestValue!, name: "test.txt")))
    }
    
    @Test func treeSortedAlphabetically() async throws {
        let b1 = Blob(contents: Data(String(stringLiteral: "version 1").utf8))
        let a1 = AuditionDataModel()
        _ = a1.hash(obj: b1, write: true)
        try a1.updateIndex(sha256DigestValue: b1.sha256DigestValue!, name: "test.txt")
        let b2 = Blob(contents: Data(String(stringLiteral: "version 2").utf8))
        _ = a1.hash(obj: b2, write: true)
        try a1.updateIndex(sha256DigestValue: b2.sha256DigestValue!, name: "test.txt")
        let b3 = Blob(contents: Data(String(stringLiteral: "new file").utf8))
        _ = a1.hash(obj: b3, write: true)
        try a1.updateIndex(sha256DigestValue: b3.sha256DigestValue!, name: "new.txt")
        
        let t1Hash = a1.writeTree()
        let t1 = a1.objects[t1Hash] as! Tree
        #expect(t1.entries == [
            TreeEntry(type: .blob, hash: b3.sha256DigestValue!, name: "new.txt"),
            TreeEntry(type: .blob, hash: b2.sha256DigestValue!, name: "test.txt")
        ])
    }
    
    @Test func commitTree() async throws {
        let b1 = Blob(contents: Data(String(stringLiteral: "version 1").utf8))
        let a1 = AuditionDataModel()
        _ = a1.hash(obj: b1, write: true)
        try a1.updateIndex(sha256DigestValue: b1.sha256DigestValue!, name: "test.txt")
        let b2 = Blob(contents: Data(String(stringLiteral: "version 2").utf8))
        _ = a1.hash(obj: b2, write: true)
        try a1.updateIndex(sha256DigestValue: b2.sha256DigestValue!, name: "test.txt")
        let b3 = Blob(contents: Data(String(stringLiteral: "new file").utf8))
        _ = a1.hash(obj: b3, write: true)
        try a1.updateIndex(sha256DigestValue: b3.sha256DigestValue!, name: "new.txt")
        
        let t1Hash = a1.writeTree()

        let c1Hash = try a1.commitTree(tree: t1Hash, message: "commit number one")
        let c1 = a1.objects[c1Hash] as! Commit
        
        #expect(c1.type == .commit)
        #expect(c1.tree == t1Hash)
        #expect(c1.parents == [])
        #expect(c1.message == "commit number one")
        #expect(c1.timestamp.distance(to: .now) < TimeInterval(1))
    }
    
    @Test func plistOfTree() async throws {
        
    }
    
    @Test func plistOfCommit() async throws {
        
    }
    
    @Test func headExistsAndPointsToMainBranch() async throws {
        let a1 = AuditionDataModel()
        #expect(a1.HEAD != nil)
        #expect(a1.HEAD == "main")
    }
    
    @Test func mainBranchNonexistentBeforeCommit() async throws {
        let a1 = AuditionDataModel()
        #expect(a1.branches == [:])
    }
    
    @Test func addOneFile() async throws {
        let content = Data(String(stringLiteral: "you're reading me!").utf8)
        
        let f1 = AuditionFile(
            content: content,
            name: "README.md"
        )
        
        let a1 = AuditionDataModel()
        // confirm objects empty
        #expect(a1.objects.count == 0)
        // confirm index empty
        #expect(a1.index.count == 0)
        
        try a1.add(f1)
        
        // check blob exists
        #expect(a1.objects.count == 1)
        
        // check index points to blob only
        #expect(a1.index.count == 1)
        
        // check blob has correct hash+contents
        let b1 = Blob(contents: content)
        #expect(a1.objects[b1.sha256DigestValue!] != nil)
    }
    
    @Test func commitOneFile() async throws {
        let content = Data(String(stringLiteral: "you're reading me!").utf8)
        let filename = "README.md"
        
        let f1 = AuditionFile(
            content: content,
            name: filename
        )
        
        let a1 = AuditionDataModel()
        try a1.add(f1)
        
        let commitMessage = "initial commit"
        let commit: String = try a1.commit(message: commitMessage)
        
        // check objects has correct count
        #expect(a1.objects.count == 3)
        
        // check objects has blob
        let b1 = Blob(contents: content)
        #expect(a1.objects[b1.sha256DigestValue!] != nil)
        
        // check objects has tree
        let t1 = Tree(entries: [TreeEntry(type: .blob, hash: b1.sha256DigestValue!, name: filename)])
        #expect(a1.objects[t1.sha256DigestValue!] != nil)
        
        // check objects has commit
        #expect(a1.objects[commit] != nil)
        
        let commitObj = a1.objects[commit] as! Commit
        // check correct commit data
        #expect(commitObj.type == .commit)
        #expect(commitObj.tree == t1.sha256DigestValue!)
        #expect(commitObj.parents == [])
        #expect(commitObj.message == commitMessage)
        #expect(commitObj.timestamp.distance(to: .now) < TimeInterval(1))
        
        // check index points to blob only
        #expect(a1.index.count == 1)
        #expect(a1.index[0] == TreeEntry(type: .blob, hash: b1.sha256DigestValue!, name: filename))
        
        // check main branch exists
        #expect(a1.branches["main"] != nil)
        
        // check main branch points to correct commit
        #expect(a1.branches["main"] == commit)
    }
    
    @Test func addOneMoreFile() async throws {
        let content1 = Data(String(stringLiteral: "you're reading me!").utf8)
        let filename1 = "README.md"
        
        let f1 = AuditionFile(
            content: content1,
            name: filename1
        )
        
        let a1 = AuditionDataModel()
        try a1.add(f1)
        
        let commitMessage = "initial commit"
        let commit: String = try a1.commit(message: commitMessage)
        
        let b1 = Blob(contents: content1)
        let t1 = Tree(entries: [TreeEntry(type: .blob, hash: b1.sha256DigestValue!, name: filename1)])
        let commitObj = a1.objects[commit] as! Commit
        
        let content2 = Data(String(stringLiteral: "hi how are you?").utf8)
        let filename2 = "hello.txt"
        
        let f2 = AuditionFile(
            content: content2,
            name: filename2
        )
        
        // confirm state before add
        #expect(a1.objects.count == 3)
        #expect(a1.index.count == 1)
        #expect(a1.objects[b1.sha256DigestValue!] != nil)
        
        try a1.add(f2)
        
        // check blob exists
        #expect(a1.objects.count == 4)
        
        // check index points to two blobs
        #expect(a1.index.count == 2)
        
        // check blob has correct hash+contents
        let b2 = Blob(contents: content2)
        #expect(a1.objects[b2.sha256DigestValue!] != nil)
    }
    
    @Test func commitOneMoreFile() async throws {
        let content1 = Data(String(stringLiteral: "you're reading me!").utf8)
        let filename1 = "README.md"
        
        let f1 = AuditionFile(
            content: content1,
            name: filename1
        )
        
        let a1 = AuditionDataModel()
        try a1.add(f1)
        
        let commitMessage1 = "initial commit"
        let commit1: String = try a1.commit(message: commitMessage1)
        
        let b1 = Blob(contents: content1)
        let t1 = Tree(entries: [TreeEntry(type: .blob, hash: b1.sha256DigestValue!, name: filename1)])
        let commitObj1 = a1.objects[commit1] as! Commit
        
        let content2 = Data(String(stringLiteral: "hi how are you?").utf8)
        let filename2 = "hello.txt"
        
        let f2 = AuditionFile(
            content: content2,
            name: filename2
        )
        
        try a1.add(f2)
        
        let commitMessage2 = "second commit"
        let commit2: String = try a1.commit(message: commitMessage2)
        
        // check objects has correct count
        #expect(a1.objects.count == 6)
        
        // check objects has blob
        let b2 = Blob(contents: content2)
        #expect(a1.objects[b2.sha256DigestValue!] != nil)
        
        // check objects has tree
        let t2 = Tree(entries: [TreeEntry(type: .blob, hash: b2.sha256DigestValue!, name: filename2), TreeEntry(type: .blob, hash: b1.sha256DigestValue!, name: filename1)])
        #expect(a1.objects[t2.sha256DigestValue!] != nil)
        
        // check objects has commit
        #expect(a1.objects[commit2] != nil)
        
        let commitObj2 = a1.objects[commit2] as! Commit
        // check correct commit data
        #expect(commitObj2.type == .commit)
        #expect(commitObj2.tree == t2.sha256DigestValue!)
        #expect(commitObj2.parents == [commit1])
        #expect(commitObj2.message == commitMessage2)
        #expect(commitObj2.timestamp.distance(to: .now) < TimeInterval(1))
        
        // check index points to two blobs
        #expect(a1.index.count == 2)
        
        // index (at the moment) is not sorted by filename
        #expect(a1.index.contains(TreeEntry(type: .blob, hash: b2.sha256DigestValue!, name: filename2)))
        #expect(a1.index.contains(TreeEntry(type: .blob, hash: b1.sha256DigestValue!, name: filename1)))
        
        // check main branch exists
        #expect(a1.branches["main"] != nil)
        
        // check main branch points to correct commit
        #expect(a1.branches["main"] == commit2)
        
    }
}
