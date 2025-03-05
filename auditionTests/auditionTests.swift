//
//  auditionTests.swift
//  auditionTests
//
//  Created by Jake Medina on 1/17/25.
//

import Testing
import Foundation
import PencilKit

@testable import audition

struct auditionTests {

    @Test func newCommit() async throws {
        let c2 = Commit(tree: "0155eb4229851634a0f03eb265b69f5a2d56f341", parents: ["fdf4fc3344e67ab068f836878b6c4951e3b15f3d"], message: "Second commit", timestamp: Date(timeIntervalSince1970: 1243041269))
        
        #expect(c2.description == "tree 0155eb4229851634a0f03eb265b69f5a2d56f341\nparent fdf4fc3344e67ab068f836878b6c4951e3b15f3d\n2009-05-23 01:14:29 +0000\n\nSecond commit")
        
        #expect(c2.sha256DigestValue == "82a75ed7dd3992f8bb683caeaa4b7e20f681be317544d0bb76ef405ca2d133d7")
        
        // confirm hash does not change
        
        let c2v2 = Commit(tree: "0155eb4229851634a0f03eb265b69f5a2d56f341", parents: ["fdf4fc3344e67ab068f836878b6c4951e3b15f3d"], message: "Second commit", timestamp: Date(timeIntervalSince1970: 1243041269))
        
        #expect(c2v2.description == "tree 0155eb4229851634a0f03eb265b69f5a2d56f341\nparent fdf4fc3344e67ab068f836878b6c4951e3b15f3d\n2009-05-23 01:14:29 +0000\n\nSecond commit")
        
        #expect(c2v2.sha256DigestValue == "82a75ed7dd3992f8bb683caeaa4b7e20f681be317544d0bb76ef405ca2d133d7")
    }

    @Test func newTree() async throws {
        let t3 = Tree(entries: [
            TreeEntry(type: .tree, hash: "d8329fc1cc938780ffdd9f94e0d364e0ea74f579", name: "bak"),
            TreeEntry(type: .blob, hash: "fa49b077972391ad58037050f2a75f74e3671e92", name: "new.txt"),
            TreeEntry(type: .blob, hash: "1f7a7a472abf3dd9643fd615f6da379c4acb3e3a", name: "test.txt")
        ])
        
        #expect(t3.description == "tree d8329fc1cc938780ffdd9f94e0d364e0ea74f579      bak\nblob fa49b077972391ad58037050f2a75f74e3671e92      new.txt\nblob 1f7a7a472abf3dd9643fd615f6da379c4acb3e3a      test.txt")
        
        #expect(t3.sha256DigestValue == "90ae292581fa5bdf0aeb679510347ba42f4f05a528eac848a2f4b8abcb774d20")
        
        // confirm hash does not change
        
        let t3v2 = Tree(entries: [
            TreeEntry(type: .tree, hash: "d8329fc1cc938780ffdd9f94e0d364e0ea74f579", name: "bak"),
            TreeEntry(type: .blob, hash: "fa49b077972391ad58037050f2a75f74e3671e92", name: "new.txt"),
            TreeEntry(type: .blob, hash: "1f7a7a472abf3dd9643fd615f6da379c4acb3e3a", name: "test.txt")
        ])
        
        #expect(t3v2.description == "tree d8329fc1cc938780ffdd9f94e0d364e0ea74f579      bak\nblob fa49b077972391ad58037050f2a75f74e3671e92      new.txt\nblob 1f7a7a472abf3dd9643fd615f6da379c4acb3e3a      test.txt")
        
        #expect(t3v2.sha256DigestValue == "90ae292581fa5bdf0aeb679510347ba42f4f05a528eac848a2f4b8abcb774d20")
    }
    
    @Test func newBlob() async throws {
        let b3 = Blob(contents: Data(String(stringLiteral: "new file").utf8))
        
        #expect(b3.description == "8 bytes")
        
        #expect(b3.sha256DigestValue == "d0c263267dfbad0da8ab575283a3604661e00cceebcf20207ec1cee843725637")
        
        // confirm hash does not change
        
        let b3v2 = Blob(contents: Data(String(stringLiteral: "new file").utf8))
        
        #expect(b3v2.description == "8 bytes")
        
        #expect(b3v2.sha256DigestValue == "d0c263267dfbad0da8ab575283a3604661e00cceebcf20207ec1cee843725637")
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
    
    @Test func addAndReplaceFile() async throws {
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
        
        let content2 = Data(String(stringLiteral: "hi how are you?").utf8)
        let filename2 = "README.md"
        
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
        
        // check blob has correct hash+contents
        let b2 = Blob(contents: content2)
        #expect(a1.objects[b2.sha256DigestValue!] != nil)
        
        // check index points to one blob (the previous blob should be replaced due to the new content having the same filename when added)
        try #require(a1.index.count == 1)
        #expect(a1.index[0].name == filename2)
        #expect(a1.index[0].hash == b2.sha256DigestValue!)
        #expect(a1.index[0].type == .blob)
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
    
    @Test func testEncodeAndDecodeAuditionObjectWrapper() async throws {
        let c1tree = "0155eb4229851634a0f03eb265b69f5a2d56f341"
        let c1parents = ["fdf4fc3344e67ab068f836878b6c4951e3b15f3d"]
        let c1message = "Second commit"
        let c1timestamp = Date(timeIntervalSince1970: 1243041269)
        
        let c1expectedSHA = "82a75ed7dd3992f8bb683caeaa4b7e20f681be317544d0bb76ef405ca2d133d7"
        
        let c1 = Commit(tree: c1tree, parents: c1parents, message: c1message, timestamp: c1timestamp)
        #expect(c1.sha256DigestValue == c1expectedSHA)
        
        let w1 = AuditionObjectWrapper(object: c1)
        
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        
        let w1encoded = try encoder.encode(w1)
        
        let w1decoded = try PropertyListDecoder().decode(AuditionObjectWrapper.self, from: w1encoded)
        
        let c1decoded = w1decoded.object as! Commit
        
        #expect(c1decoded.sha256DigestValue == c1expectedSHA)
    }
    
    @Test func testEncodeAndDecodeAuditionDataModel() async throws {
        let content1 = Data(String(stringLiteral: "you're reading me!").utf8)
        let filename1 = "README.md"
        
        let f1 = AuditionFile(
            content: content1,
            name: filename1
        )
        
        var a1 = AuditionDataModel()
        try a1.add(f1)
        
        let commitMessage1 = "initial commit"
        let commit1: String = try a1.commit(message: commitMessage1)
        
        let b1 = Blob(contents: content1)
        
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
        
        var commitObj2 = a1.objects[commit2] as! Commit
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
        
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        
        let a1encoded = try encoder.encode(a1)
        
        a1 = try PropertyListDecoder().decode(AuditionDataModel.self, from: a1encoded)
        
        // check objects has correct count
        #expect(a1.objects.count == 6)
        
        // check objects has blob
        #expect(a1.objects[b2.sha256DigestValue!] != nil)
        
        // check objects has tree
        #expect(a1.objects[t2.sha256DigestValue!] != nil)
        
        // check objects has commit
        #expect(a1.objects[commit2] != nil)
        
        commitObj2 = a1.objects[commit2] as! Commit
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
    
    @Test func testLog() async throws {
        let content1 = Data(String(stringLiteral: "you're reading me!").utf8)
        let filename1 = "README.md"
        
        let f1 = AuditionFile(
            content: content1,
            name: filename1
        )
        
        let a1 = AuditionDataModel()
        
        #expect(throws: AuditionError.self) {
            try a1.log()
        }
        
        #expect(throws: AuditionError.self) {
            try a1.log(branch: "main")
        }
        
        #expect(throws: AuditionError.self) {
            try a1.log(commit: "abcdef012345")
        }
        
        try a1.add(f1)
        
        let commitMessage1 = "initial commit"
        let commit1: String = try a1.commit(message: commitMessage1)
        
        let b1 = Blob(contents: content1)
        let t1 = Tree(entries: [TreeEntry(type: .blob, hash: b1.sha256DigestValue!, name: filename1)])
        
        let content2 = Data(String(stringLiteral: "hi how are you?").utf8)
        let filename2 = "hello.txt"
        
        let f2 = AuditionFile(
            content: content2,
            name: filename2
        )
        
        try a1.add(f2)
        
        let commitMessage2 = "second commit"
        let commit2: String = try a1.commit(message: commitMessage2)
        
        let b2 = Blob(contents: content2)
        let t2 = Tree(entries: [TreeEntry(type: .blob, hash: b2.sha256DigestValue!, name: filename2), TreeEntry(type: .blob, hash: b1.sha256DigestValue!, name: filename1)])
        
        let commitObj1 = a1.objects[commit1] as! Commit
        let commitObj2 = a1.objects[commit2] as! Commit
        
        let logFromHEAD: [Commit] = try a1.log()
        let logFromBranch: [Commit] = try a1.log(branch: "main")
        let logFromCommit: [Commit] = try a1.log(commit: commitObj2.sha256DigestValue!)
        
        try a1.checkout(commit: commitObj2.sha256DigestValue!)
        let logFromCommit1: [Commit] = try a1.log()
        
        // test log() where HEAD is a branch
        try #require(logFromHEAD.count == 2)
        
        #expect(logFromHEAD[0].type == .commit)
        #expect(logFromHEAD[0].tree == t2.sha256DigestValue!)
        #expect(logFromHEAD[0].parents == [commit1])
        #expect(logFromHEAD[0].message == commitMessage2)
        #expect(logFromHEAD[0].timestamp.distance(to: .now) < TimeInterval(1))
        
        #expect(logFromHEAD[1].type == .commit)
        #expect(logFromHEAD[1].tree == t1.sha256DigestValue!)
        #expect(logFromHEAD[1].parents == [])
        #expect(logFromHEAD[1].message == commitMessage1)
        #expect(logFromHEAD[1].timestamp.distance(to: .now) < TimeInterval(1))
        
        
        // test log(branch:)
        try #require(logFromBranch.count == 2)
        
        #expect(logFromBranch[0].type == .commit)
        #expect(logFromBranch[0].tree == t2.sha256DigestValue!)
        #expect(logFromBranch[0].parents == [commit1])
        #expect(logFromBranch[0].message == commitMessage2)
        #expect(logFromBranch[0].timestamp.distance(to: .now) < TimeInterval(1))
        
        #expect(logFromBranch[1].type == .commit)
        #expect(logFromBranch[1].tree == t1.sha256DigestValue!)
        #expect(logFromBranch[1].parents == [])
        #expect(logFromBranch[1].message == commitMessage1)
        #expect(logFromBranch[1].timestamp.distance(to: .now) < TimeInterval(1))
        
        // test log(branch:) only works on branches
        #expect(throws: AuditionError.self) {
            try a1.log(branch: commitObj2.sha256DigestValue!)
        }
        
        // test log(commit:)
        try #require(logFromCommit.count == 2)
        
        #expect(logFromCommit[0].type == .commit)
        #expect(logFromCommit[0].tree == t2.sha256DigestValue!)
        #expect(logFromCommit[0].parents == [commit1])
        #expect(logFromCommit[0].message == commitMessage2)
        #expect(logFromCommit[0].timestamp.distance(to: .now) < TimeInterval(1))
        
        #expect(logFromCommit[1].type == .commit)
        #expect(logFromCommit[1].tree == t1.sha256DigestValue!)
        #expect(logFromCommit[1].parents == [])
        #expect(logFromCommit[1].message == commitMessage1)
        #expect(logFromCommit[1].timestamp.distance(to: .now) < TimeInterval(1))
        
        // test log(commit:) only works on commits
        #expect(throws: AuditionError.self) {
            try a1.log(commit: "main")
        }
        
        // test log() where HEAD is a commit
        try #require(logFromCommit1.count == 2)
        
        #expect(logFromCommit1[0].type == .commit)
        #expect(logFromCommit1[0].tree == t2.sha256DigestValue!)
        #expect(logFromCommit1[0].parents == [commit1])
        #expect(logFromCommit1[0].message == commitMessage2)
        #expect(logFromCommit1[0].timestamp.distance(to: .now) < TimeInterval(1))
        
        #expect(logFromCommit[1].type == .commit)
        #expect(logFromCommit1[1].tree == t1.sha256DigestValue!)
        #expect(logFromCommit1[1].parents == [])
        #expect(logFromCommit1[1].message == commitMessage1)
        #expect(logFromCommit1[1].timestamp.distance(to: .now) < TimeInterval(1))
    }
    
    @Test func testShowTree() async throws {
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
        
        let content2 = Data(String(stringLiteral: "hi how are you?").utf8)
        let filename2 = "hello.txt"
        
        let f2 = AuditionFile(
            content: content2,
            name: filename2
        )
        
        try a1.add(f2)
        
        let commitMessage2 = "second commit"
        let commit2: String = try a1.commit(message: commitMessage2)
        
        let b2 = Blob(contents: content2)
        let t2 = Tree(entries: [TreeEntry(type: .blob, hash: b2.sha256DigestValue!, name: filename2), TreeEntry(type: .blob, hash: b1.sha256DigestValue!, name: filename1)])
        
        let commitObj1 = a1.objects[commit1] as! Commit
        let commitObj2 = a1.objects[commit2] as! Commit
        
        #expect(try a1.showTree().sha256DigestValue == commitObj2.tree)
        #expect(try a1.showTree().sha256DigestValue == t2.sha256DigestValue)
        
        #expect((try a1.showTree(commit: commit1).sha256DigestValue) == commitObj1.tree)
        #expect((try a1.showTree(commit: commit1).sha256DigestValue) == t1.sha256DigestValue)
    }
    
    @Test func testShowBlobs() async throws {
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
        
        try #require(try a1.showBlobs().count == 1)
        #expect((try a1.showBlobs()[0].sha256DigestValue) == b1.sha256DigestValue)
        
        let content2 = Data(String(stringLiteral: "hi how are you?").utf8)
        let filename2 = "hello.txt"
        
        let f2 = AuditionFile(
            content: content2,
            name: filename2
        )
        
        try a1.add(f2)
        
        let commitMessage2 = "second commit"
        let commit2: String = try a1.commit(message: commitMessage2)
        
        let b2 = Blob(contents: content2)
        let t2 = Tree(entries: [TreeEntry(type: .blob, hash: b2.sha256DigestValue!, name: filename2), TreeEntry(type: .blob, hash: b1.sha256DigestValue!, name: filename1)])
        
        let commitObj1 = a1.objects[commit1] as! Commit
        let commitObj2 = a1.objects[commit2] as! Commit
        
        try #require(try a1.showBlobs().count == 2)
        #expect((try a1.showBlobs()[0].sha256DigestValue) == b2.sha256DigestValue)
        #expect((try a1.showBlobs()[1].sha256DigestValue) == b1.sha256DigestValue)
        
        try #require(try a1.showBlobs(commit: commit1).count == 1)
        #expect((try a1.showBlobs(commit: commit1)[0].sha256DigestValue) == b1.sha256DigestValue)
    }
    
    @Test func testCreateBranch() async throws {
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
        
        let content2 = Data(String(stringLiteral: "hi how are you?").utf8)
        let filename2 = "hello.txt"
        
        let f2 = AuditionFile(
            content: content2,
            name: filename2
        )
        
        try a1.add(f2)
        
        let commitMessage2 = "second commit"
        let commit2: String = try a1.commit(message: commitMessage2)
        
        let b2 = Blob(contents: content2)
        let t2 = Tree(entries: [TreeEntry(type: .blob, hash: b2.sha256DigestValue!, name: filename2), TreeEntry(type: .blob, hash: b1.sha256DigestValue!, name: filename1)])
        
        let newBranchName = "featureA"
        try a1.createBranch(branchName: newBranchName)
        try #require(a1.branches["main"] != nil)
        #expect(a1.branches["main"] == commit2)
        try #require(a1.branches[newBranchName] != nil)
        #expect(a1.branches[newBranchName] == commit2)
        #expect(a1.HEAD == "main")
    }
    
    @Test func testCheckoutBranch() async throws {
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
        
        let content2 = Data(String(stringLiteral: "hi how are you?").utf8)
        let filename2 = "hello.txt"
        
        let f2 = AuditionFile(
            content: content2,
            name: filename2
        )
        
        try a1.add(f2)
        
        let commitMessage2 = "second commit"
        let commit2: String = try a1.commit(message: commitMessage2)
        
        let b2 = Blob(contents: content2)
        let t2 = Tree(entries: [TreeEntry(type: .blob, hash: b2.sha256DigestValue!, name: filename2), TreeEntry(type: .blob, hash: b1.sha256DigestValue!, name: filename1)])
        
        let newBranchName = "featureA"
        
        // test checkout with non-existent branch
        try #require(throws: AuditionError.self) {
            try a1.checkout(branch: newBranchName)
        }
        
        try a1.createBranch(branchName: newBranchName)
        
        try a1.checkout(branch: newBranchName)
        #expect(a1.HEAD == newBranchName)
    }
    
    @Test func testCreateAndCheckoutBranch() async throws {
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
        
        let content2 = Data(String(stringLiteral: "hi how are you?").utf8)
        let filename2 = "hello.txt"
        
        let f2 = AuditionFile(
            content: content2,
            name: filename2
        )
        
        try a1.add(f2)
        
        let commitMessage2 = "second commit"
        let commit2: String = try a1.commit(message: commitMessage2)
        
        let b2 = Blob(contents: content2)
        let t2 = Tree(entries: [TreeEntry(type: .blob, hash: b2.sha256DigestValue!, name: filename2), TreeEntry(type: .blob, hash: b1.sha256DigestValue!, name: filename1)])
        
        let newBranchName = "featureA"
        
        // test checkout with non-existent branch
        try #require(throws: AuditionError.self) {
            try a1.checkout(branch: newBranchName, newBranch: false)
        }
        
        try a1.checkout(branch: newBranchName, newBranch: true)
        try #require(a1.branches["main"] != nil)
        #expect(a1.branches["main"] == commit2)
        try #require(a1.branches[newBranchName] != nil)
        #expect(a1.branches[newBranchName] == commit2)
        #expect(a1.HEAD == newBranchName)
    }
    
    @Test func testCommitBranch() async throws {
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
        
        let content2 = Data(String(stringLiteral: "hi how are you?").utf8)
        let filename2 = "hello.txt"
        
        let f2 = AuditionFile(
            content: content2,
            name: filename2
        )
        
        try a1.add(f2)
        
        let commitMessage2 = "second commit"
        let commit2: String = try a1.commit(message: commitMessage2)
        
        let b2 = Blob(contents: content2)
        let t2 = Tree(entries: [TreeEntry(type: .blob, hash: b2.sha256DigestValue!, name: filename2), TreeEntry(type: .blob, hash: b1.sha256DigestValue!, name: filename1)])
        
        let newBranchName = "featureA"
        try a1.checkout(branch: newBranchName, newBranch: true)
        
        let content3 = Data(String(stringLiteral: "see ya later!").utf8)
        let filename3 = "goodbye.txt"
        
        let f3 = AuditionFile(content: content3, name: filename3)
        
        try a1.add(f3)
        
        let commitMessage3 = "third commit"
        let commit3: String = try a1.commit(message: commitMessage3)
        
        let b3 = Blob(contents: content3)
        let t3 = Tree(entries: [TreeEntry(type: .blob, hash: b3.sha256DigestValue!, name: filename3), TreeEntry(type: .blob, hash: b2.sha256DigestValue!, name: filename2), TreeEntry(type: .blob, hash: b1.sha256DigestValue!, name: filename1)])
        
        #expect(a1.branches["main"] == commit2)
        #expect(a1.branches[newBranchName] == commit3)
        #expect(a1.HEAD == newBranchName)
    }
    
    @Test func testEmptyCommitNotAllowed() async throws {
        
    }
    
    @Test func testComputeInDegreeDict() async throws {
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
        
        let content2 = Data(String(stringLiteral: "test two").utf8)
        let filename2 = "test2.txt"
        
        let f2 = AuditionFile(
            content: content2,
            name: filename2
        )
        
        try a1.add(f2)
        
        let commitMessage2 = "second commit"
        var commit2: String = try a1.commit(message: commitMessage2)
        
        let expected1: [String : AuditionDataModel.CommitWalkInfo] = [
            commit1 : AuditionDataModel.CommitWalkInfo(visited: true, inDegree: 1),
            commit2 : AuditionDataModel.CommitWalkInfo(visited: true, inDegree: 0)
        ]
        
        let actual1 = try a1.computeInDegreeDict()
        
        #expect(actual1 == expected1)
        print("test with 2 nodes finished")
        
        let content3 = Data(String(stringLiteral: "test three").utf8)
        let filename3 = "test3.txt"
        
        let f3 = AuditionFile(
            content: content3,
            name: filename3
        )
        
        // CREATE A NEW MODEL
        let a2 = AuditionDataModel()
        try a2.add(f1)
        
        commit1 = try a2.commit(message: commitMessage1)
        
        // add a branch from the initial commit
        try a2.createBranch(branchName: "b1")
        try a2.createBranch(branchName: "b2")
        
        try a2.checkout(branch: "b1")
        try a2.add(f2)
        commit2 = try a2.commit(message: commitMessage2)
        
        try a2.checkout(branch: "b2")
        try a2.add(f3)
        let commitMessage3 = "third commit"
        var commit3: String = try a2.commit(message: commitMessage3)
        
        let expected2: [String : AuditionDataModel.CommitWalkInfo] = [
            commit1 : AuditionDataModel.CommitWalkInfo(visited: true, inDegree: 2),
            commit2 : AuditionDataModel.CommitWalkInfo(visited: true, inDegree: 0),
            commit3 : AuditionDataModel.CommitWalkInfo(visited: true, inDegree: 0),
        ]
        
        #expect(try a2.computeInDegreeDict() == expected2)
        print("test with 3 nodes finished")
        
        
        // test multiple branch points pointing to the same commits
        try a2.checkout(branch: "main")
        try a2.createBranch(branchName: "main2")
        try a2.checkout(branch: "b1")
        try a2.createBranch(branchName: "b1a")
        try a2.checkout(branch: "b2")
        try a2.createBranch(branchName: "b2a")
        
        #expect(try a2.computeInDegreeDict() == expected2)
        print("test with 3 nodes testing multiple branches pointed to the same commits finished")
        
        a2.unsafeDeleteBranch(branchName: "main2")
        a2.unsafeDeleteBranch(branchName: "b1a")
        a2.unsafeDeleteBranch(branchName: "b2a")
        
        // add a commit to the b1 branch
        try a2.checkout(branch: "b1")
        try a2.add(AuditionFile(
                content: Data(String(stringLiteral: "test four").utf8),
                name: "test4.txt"
            )
        )
        
        let commit4 = try a2.commit(message: "fourth commit")
        
        // manually modify the commit to make it have two parents
        let commitObj4 = a2.objects[commit4] as! Commit
        var newParents: [String] = Array(commitObj4.parents)
        newParents.append(a2.branches["b2"]!)
//        a2.objects[commit4] = Commit(tree: commitObj4.tree, parents: newParents, message: commitObj4.message, timestamp: commitObj4.timestamp)
        a2.unsafeSetObject(key: commit4, value: Commit(tree: commitObj4.tree, parents: newParents, message: commitObj4.message, timestamp: commitObj4.timestamp))
        
        let expected3: [String : AuditionDataModel.CommitWalkInfo] = [
            commit1 : AuditionDataModel.CommitWalkInfo(visited: true, inDegree: 2), // main
            commit2 : AuditionDataModel.CommitWalkInfo(visited: true, inDegree: 1), //
            commit3 : AuditionDataModel.CommitWalkInfo(visited: true, inDegree: 1), // b2
            commit4 : AuditionDataModel.CommitWalkInfo(visited: true, inDegree: 0), // b2
        ]
        
        #expect(try a2.computeInDegreeDict() == expected3)
        print("test with 4 nodes finished")
    }
    
    @Test func testDetachedHEAD() async throws {
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
        
        let content2 = Data(String(stringLiteral: "hi how are you?").utf8)
        let filename2 = "hello.txt"
        
        let f2 = AuditionFile(
            content: content2,
            name: filename2
        )
        
        try a1.add(f2)
        
        let commitMessage2 = "second commit"
        let commit2: String = try a1.commit(message: commitMessage2)
        
        let content3 = Data(String(stringLiteral: "see ya later!").utf8)
        let filename3 = "goodbye.txt"
        let f3 = AuditionFile(
            content: content3,
            name: filename3
        )
        let commitMessage3 = "third commit"
        
        try a1.checkout(commit: commit1)
        #expect(throws: AuditionError.self) {
            try a1.add(f3)
            _ = try a1.commit(message: commitMessage3)
        }
        
        try a1.checkout(commit: commit2)
        #expect(throws: AuditionError.self) {
            try a1.add(f3)
            _ = try a1.commit(message: commitMessage3)
        }
        
        try a1.checkout(branch: "main")
    }
    
    // since there is some functionality in AuditionDataModel that
    // relies on checking branches[HEAD] exists to see if HEAD is a branch,
    // then checking objects[HEAD] is Commit to see if HEAD is a commit,
    // having a branch with a name that is the same as an existing commit's hash may cause unintended behavior
    @Test func testDisallowCreateBranchNamedAfterExistingObjectHash() async throws {
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
        
        let content2 = Data(String(stringLiteral: "hi how are you?").utf8)
        let filename2 = "hello.txt"
        
        let f2 = AuditionFile(
            content: content2,
            name: filename2
        )
        
        try a1.add(f2)
        
        let commitMessage2 = "second commit"
        let commit2: String = try a1.commit(message: commitMessage2)
        
        #expect(throws: AuditionError.self) {
            try a1.createBranch(branchName: commit2)
        }
    }
    
    @Test func testAuditionFileInit() async throws {
        let content1 = Data(String(stringLiteral: "you're reading me!").utf8)
        let filename1 = "README.md"
        
        let f1 = AuditionFile(
            content: content1,
            name: filename1
        )
        
        let content2 = PKDrawing().dataRepresentation()
        let filename2 = "testDrawingA"
        
        let f2 = AuditionFile(
            content: content2,
            name: filename2
        )
        
        let content3 = PKDrawing().dataRepresentation()
        let filename3 = "testDrawingB"
        
        let f3 = AuditionFile(
            content: content3,
            contentTypeIdentifier: PKAppleDrawingTypeIdentifier,
            name: filename3
        )
        
        let drawing4 = PKDrawing()
        let filename4 = "testDrawingC"
        
        let f4 = AuditionFile(
            from: drawing4,
            name: filename4
        )
        
        #expect(f1.contentTypeIdentifier == nil)
        #expect(f2.contentTypeIdentifier == nil)
        #expect(f3.contentTypeIdentifier == PKAppleDrawingTypeIdentifier as String)
        #expect(f4.contentTypeIdentifier == PKAppleDrawingTypeIdentifier as String)
    }
    
    @Test func testBlobInit() async throws {
        let content1 = Data(String(stringLiteral: "you're reading me!").utf8)
        let filename1 = "README.md"
        
        let f1 = AuditionFile(
            content: content1,
            name: filename1
        )
        
        let content2 = PKDrawing().dataRepresentation()
        let filename2 = "testDrawingA"
        
        let f2 = AuditionFile(
            content: content2,
            contentTypeIdentifier: PKAppleDrawingTypeIdentifier,
            name: filename2
        )
        
        let b1 = Blob(contents: f1.content, contentTypeIdentifier: f1.contentTypeIdentifier)
        let b1a = Blob(from: f1)
        
        #expect(b1.contentTypeIdentifier == nil)
        #expect(b1.contents == b1a.contents)
        #expect(b1.contentTypeIdentifier == b1a.contentTypeIdentifier)
        
        let b2 = Blob(contents: f2.content, contentTypeIdentifier: f2.contentTypeIdentifier)
        let b2a = Blob(from: f2)
        
        #expect(b2.contentTypeIdentifier == PKAppleDrawingTypeIdentifier as String)
        #expect(b2.contents == b2a.contents)
        #expect(b2.contentTypeIdentifier == b2a.contentTypeIdentifier)
    }
    
    // ensure that Blob.createDrawing() will throw an error when there isn't content in the Blob
    // that is marked as a PKDrawing with the PKAppleDrawingTypeIdentifier.
    @Test func testBlobCreateDrawingChecksContentTypeIdentifier() async throws {
        let content1 = Data(String(stringLiteral: "you're reading me!").utf8)
        let filename1 = "README.md"
        
        let f1 = AuditionFile(
            content: content1,
            name: filename1
        )
        
        let content2 = PKDrawing().dataRepresentation()
        let filename2 = "testDrawingA"
        
        let f2 = AuditionFile(
            content: content2,
            name: filename2
        )
        
        let content3 = PKDrawing().dataRepresentation()
        let filename3 = "testDrawingB"
        
        let f3 = AuditionFile(
            content: content3,
            contentTypeIdentifier: PKAppleDrawingTypeIdentifier,
            name: filename3
        )
        
        let b1 = Blob(contents: f1.content, contentTypeIdentifier: f1.contentTypeIdentifier)
        let b2 = Blob(contents: f2.content, contentTypeIdentifier: f2.contentTypeIdentifier)
        let b3 = Blob(contents: f3.content, contentTypeIdentifier: f3.contentTypeIdentifier)
        
        let b4 = Blob(from: f1)
        let b5 = Blob(from: f2)
        let b6 = Blob(from: f3)
        
        #expect(throws: AuditionError.self) {
            try b1.createDrawing()
        }
        
        #expect(throws: AuditionError.self) {
            try b2.createDrawing()
        }
        
        _ = try b3.createDrawing()
        
        #expect(throws: AuditionError.self) {
            try b4.createDrawing()
        }
        
        #expect(throws: AuditionError.self) {
            try b5.createDrawing()
        }
        
        _ = try b6.createDrawing()
    }
    
    @Test func testAuditionFileInitFromPKStroke() async throws {
        let f1 = AuditionFile(
            content: Data(String(stringLiteral: "you're reading me!").utf8),
            name: "README.md"
        )
        
        let point1 = PKStrokePoint(location: CGPoint(x: 0, y: 0), timeOffset: 0, size: CGSize(width: 10, height: 10), opacity: 1, force: 1, azimuth: 0, altitude: 3.14/2)
        let point2 = PKStrokePoint(location: CGPoint(x: 1, y: 1), timeOffset: 1, size: CGSize(width: 10, height: 10), opacity: 1, force: 1, azimuth: 0, altitude: 3.14/2)
        let path1 = PKStrokePath(controlPoints: [point1, point2], creationDate: Date(timeIntervalSince1970: 0))
        
        let stroke1 = PKStroke(ink: PKInk(.pen), path: path1)
        
        let f2 = AuditionFile(
            content: try stroke1.dataRepresentation(),
            name: "strokeA"
        )
        
        let f3 = AuditionFile(
            content: try stroke1.dataRepresentation(),
            contentTypeIdentifier: PKAppleStrokeTypeIdentifier,
            name: "strokeB"
        )
        
        let f4 = try AuditionFile(
            from: stroke1,
            name: "strokeC"
        )
        
        #expect(f1.contentTypeIdentifier == nil)
        #expect(f2.contentTypeIdentifier == nil)
        #expect(f3.contentTypeIdentifier == PKAppleStrokeTypeIdentifier)
        #expect(f4.contentTypeIdentifier == PKAppleStrokeTypeIdentifier)
    }
    
    @Test func testBlobInitFromPKStroke() async throws {
        let f1 = AuditionFile(
            content: Data(String(stringLiteral: "you're reading me!").utf8),
            name: "README.md"
        )
        
        let point1 = PKStrokePoint(location: CGPoint(x: 0, y: 0), timeOffset: 0, size: CGSize(width: 10, height: 10), opacity: 1, force: 1, azimuth: 0, altitude: 3.14/2)
        let point2 = PKStrokePoint(location: CGPoint(x: 1, y: 1), timeOffset: 1, size: CGSize(width: 10, height: 10), opacity: 1, force: 1, azimuth: 0, altitude: 3.14/2)
        let path1 = PKStrokePath(controlPoints: [point1, point2], creationDate: Date(timeIntervalSince1970: 0))
        
        let stroke1 = PKStroke(ink: PKInk(.pen), path: path1)
        
        let f2 = AuditionFile(
            content: try stroke1.dataRepresentation(),
            contentTypeIdentifier: PKAppleStrokeTypeIdentifier,
            name: "strokeA"
        )
        
        let b2 = Blob(contents: f2.content, contentTypeIdentifier: f2.contentTypeIdentifier)
        let b2a = Blob(from: f2)
        
        #expect(b2.contentTypeIdentifier == PKAppleStrokeTypeIdentifier)
        #expect(b2.contents == b2a.contents)
        #expect(b2.contentTypeIdentifier == b2a.contentTypeIdentifier)
    }
    
    @Test func testCreateDrawingFromBlobsChecksContentTypeIdentifier() async throws {
        let f1 = AuditionFile(
            content: Data(String(stringLiteral: "you're reading me!").utf8),
            name: "README.md"
        )
        
        let point1 = PKStrokePoint(location: CGPoint(x: 0, y: 0), timeOffset: 0, size: CGSize(width: 10, height: 10), opacity: 1, force: 1, azimuth: 0, altitude: 3.14/2)
        let point2 = PKStrokePoint(location: CGPoint(x: 1, y: 1), timeOffset: 1, size: CGSize(width: 10, height: 10), opacity: 1, force: 1, azimuth: 0, altitude: 3.14/2)
        let path1 = PKStrokePath(controlPoints: [point1, point2], creationDate: Date(timeIntervalSince1970: 0))
        
        let stroke1 = PKStroke(ink: PKInk(.pen), path: path1)
        
        let f2 = AuditionFile(
            content: try stroke1.dataRepresentation(),
            contentTypeIdentifier: PKAppleStrokeTypeIdentifier,
            name: "strokeA"
        )
        
        let b1 = Blob(from: f1)
        let b2 = Blob(from: f2)
        
        #expect(throws: AuditionError.self) {
            try createDrawing(strokes: [b1, b2])
        }
        
        _ = try createDrawing(strokes: [b2])
    }
    
    @Test func testEncodeAndDecodePKInk() async throws {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        
        let encoded: Data = try encoder.encode(PKInk(.crayon, color: .purple))
        let decoded: PKInk = try PropertyListDecoder().decode(PKInk.self, from: encoded)
        
        #expect(decoded.color == UIColor.purple)
        #expect(decoded.inkType == .crayon)
    }
    
    
    @Test func testEncodeAndDecodePKStrokePoint() async throws {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        
        let location = CGPoint(x: 0, y: 0)
        let timeOffset: TimeInterval = 0
        let size = CGSize(width: 10, height: 10)
        let opacity: CGFloat = 1
        let force: CGFloat = 1
        let azimuth: CGFloat = 0
        let altitude: CGFloat = 3.14/2
        
        
        let point1 = PKStrokePoint(location: location, timeOffset: timeOffset, size: size, opacity: opacity, force: force, azimuth: azimuth, altitude: altitude)
        
        let encoded: Data = try encoder.encode(point1)
        let decoded: PKStrokePoint = try PropertyListDecoder().decode(PKStrokePoint.self, from: encoded)
        
        // some floating point result need to be rounded due to floating point inaccuracy
        #expect(decoded.location == location)
        #expect(decoded.timeOffset == timeOffset)
        #expect(decoded.size == size)
        #expect(decoded.opacity.rounded() == opacity)
        #expect(decoded.force == force)
        #expect(decoded.azimuth.rounded() == azimuth)
        #expect(decoded.altitude.rounded() == 2.0)
    }
    
    @Test func testEncodeAndDecodePKStrokePath() async throws {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        
        let location1 = CGPoint(x: 0, y: 0)
        let timeOffset1: TimeInterval = 0
        let size1 = CGSize(width: 10, height: 10)
        let opacity1: CGFloat = 1
        let force1: CGFloat = 1
        let azimuth1: CGFloat = 0
        let altitude1: CGFloat = 3.14/2
        
        let location2 = CGPoint(x: 1, y: 1)
        let timeOffset2: TimeInterval = 1
        let size2 = CGSize(width: 10, height: 10)
        let opacity2: CGFloat = 1
        let force2: CGFloat = 1
        let azimuth2: CGFloat = 0
        let altitude2: CGFloat = 3.14/2
        
        let point1 = PKStrokePoint(location: location1, timeOffset: timeOffset1, size: size1, opacity: opacity1, force: force1, azimuth: azimuth1, altitude: altitude1)
        let point2 = PKStrokePoint(location: location2, timeOffset: timeOffset2, size: size2, opacity: opacity2, force: force2, azimuth: azimuth2, altitude: altitude2)
        
        let creationDate = Date(timeIntervalSince1970: 0)
        
        let path1 = PKStrokePath(controlPoints: [point1, point2], creationDate: creationDate)
        
        let encoded: Data = try encoder.encode(path1)
        let decoded: PKStrokePath = try PropertyListDecoder().decode(PKStrokePath.self, from: encoded)
        
        #expect(decoded[0].location == location1)
        #expect(decoded[0].timeOffset == timeOffset1)
        #expect(decoded[0].size == size1)
        #expect(decoded[0].opacity.rounded() == opacity1)
        #expect(decoded[0].force == force1)
        #expect(decoded[0].azimuth.rounded() == azimuth1)
        #expect(decoded[0].altitude.rounded() == 2.0)
        
        #expect(decoded[1].location == location2)
        #expect(decoded[1].timeOffset == timeOffset2)
        #expect(decoded[1].size == size2)
        #expect(decoded[1].opacity.rounded() == opacity2)
        #expect(decoded[1].force == force2)
        #expect(decoded[1].azimuth.rounded() == azimuth2)
        #expect(decoded[1].altitude.rounded() == 2.0)
        
        #expect(decoded.creationDate == creationDate)
    }
    
    @Test func testEncodeAndDecodePKStroke() async throws {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        
        let ink = PKInk(.crayon, color: .purple)
        
        let location1 = CGPoint(x: 0, y: 0)
        let timeOffset1: TimeInterval = 0
        let size1 = CGSize(width: 10, height: 10)
        let opacity1: CGFloat = 1
        let force1: CGFloat = 1
        let azimuth1: CGFloat = 0
        let altitude1: CGFloat = 3.14/2
        let location2 = CGPoint(x: 1, y: 1)
        let timeOffset2: TimeInterval = 1
        let size2 = CGSize(width: 10, height: 10)
        let opacity2: CGFloat = 1
        let force2: CGFloat = 1
        let azimuth2: CGFloat = 0
        let altitude2: CGFloat = 3.14/2
        let point1 = PKStrokePoint(location: location1, timeOffset: timeOffset1, size: size1, opacity: opacity1, force: force1, azimuth: azimuth1, altitude: altitude1)
        let point2 = PKStrokePoint(location: location2, timeOffset: timeOffset2, size: size2, opacity: opacity2, force: force2, azimuth: azimuth2, altitude: altitude2)
        let creationDate = Date(timeIntervalSince1970: 0)
        let path = PKStrokePath(controlPoints: [point1, point2], creationDate: creationDate)
        
        let transform: CGAffineTransform = .identity
        
        // doesn't really matter what the mask is, just want to make sure it's encoded/decoded properly
        let maskPath = CGPath(rect: CGRect(x: 0, y: 0, width: 2, height: 2), transform: nil)
        let mask = UIBezierPath(cgPath: maskPath)
        
        let stroke1 = PKStroke(ink: ink, path: path, transform: transform, mask: mask)
        
        let encoded1: Data = try encoder.encode(stroke1)
        let decoded1: PKStroke = try PropertyListDecoder().decode(PKStroke.self, from: encoded1)
        
        #expect(decoded1.ink.color == UIColor.purple)
        #expect(decoded1.ink.inkType == .crayon)
        
        #expect(decoded1.path[0].location == location1)
        #expect(decoded1.path[0].timeOffset == timeOffset1)
        #expect(decoded1.path[0].size == size1)
        #expect(decoded1.path[0].opacity.rounded() == opacity1)
        #expect(decoded1.path[0].force == force1)
        #expect(decoded1.path[0].azimuth.rounded() == azimuth1)
        #expect(decoded1.path[0].altitude.rounded() == 2.0)
        
        #expect(decoded1.path[1].location == location2)
        #expect(decoded1.path[1].timeOffset == timeOffset2)
        #expect(decoded1.path[1].size == size2)
        #expect(decoded1.path[1].opacity.rounded() == opacity2)
        #expect(decoded1.path[1].force == force2)
        #expect(decoded1.path[1].azimuth.rounded() == azimuth2)
        #expect(decoded1.path[1].altitude.rounded() == 2.0)
        
        #expect(decoded1.path.creationDate == creationDate)
        
        #expect(decoded1.transform.isIdentity)
        
        #expect(decoded1.mask?.bounds == mask.bounds)
        
        let stroke2 = PKStroke(ink: ink, path: path, transform: transform, mask: nil)
        
        let encoded2: Data = try encoder.encode(stroke2)
        // test mask only decoded if present
        let decoded2: PKStroke = try PropertyListDecoder().decode(PKStroke.self, from: encoded2)

        #expect(decoded2.mask == nil)
    }
}
