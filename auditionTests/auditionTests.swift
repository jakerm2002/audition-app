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
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
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
        try a1.add(sha256DigestValue: b1.sha256DigestValue!, name: "test.txt")
        
        #expect(a1.index == [TreeEntry(type: .blob, hash: b1.sha256DigestValue!, name: "test.txt")])
        
        let b2 = Blob(contents: Data(String(stringLiteral: "version 2").utf8))
        _ = a1.hash(obj: b2, write: true)
        try a1.add(sha256DigestValue: b2.sha256DigestValue!, name: "test.txt")
        
        #expect(a1.index == [TreeEntry(type: .blob, hash: b2.sha256DigestValue!, name: "test.txt")])
        
        let b3 = Blob(contents: Data(String(stringLiteral: "new file").utf8))
        _ = a1.hash(obj: b3, write: true)
        try a1.add(sha256DigestValue: b3.sha256DigestValue!, name: "new.txt")
        
        #expect(a1.index == [TreeEntry(type: .blob, hash: b2.sha256DigestValue!, name: "test.txt"), TreeEntry(type: .blob, hash: b3.sha256DigestValue!, name: "new.txt")])
    }
    
    @Test func writeTree() async throws {
        let b1 = Blob(contents: Data(String(stringLiteral: "version 1").utf8))
        let a1 = AuditionDataModel()
        _ = a1.hash(obj: b1, write: true)
        try a1.add(sha256DigestValue: b1.sha256DigestValue!, name: "test.txt")
        let b2 = Blob(contents: Data(String(stringLiteral: "version 2").utf8))
        _ = a1.hash(obj: b2, write: true)
        try a1.add(sha256DigestValue: b2.sha256DigestValue!, name: "test.txt")
        let b3 = Blob(contents: Data(String(stringLiteral: "new file").utf8))
        _ = a1.hash(obj: b3, write: true)
        try a1.add(sha256DigestValue: b3.sha256DigestValue!, name: "new.txt")
        
        let t1Hash = a1.writeTree()
        let t1 = a1.objects[t1Hash] as! Tree
        
        #expect(t1.entries.contains(TreeEntry(type: .blob, hash: b3.sha256DigestValue!, name: "new.txt")))
        #expect(t1.entries.contains(TreeEntry(type: .blob, hash: b2.sha256DigestValue!, name: "test.txt")))
    }
    
    @Test func treeSortedAlphabetically() async throws {
        let b1 = Blob(contents: Data(String(stringLiteral: "version 1").utf8))
        let a1 = AuditionDataModel()
        _ = a1.hash(obj: b1, write: true)
        try a1.add(sha256DigestValue: b1.sha256DigestValue!, name: "test.txt")
        let b2 = Blob(contents: Data(String(stringLiteral: "version 2").utf8))
        _ = a1.hash(obj: b2, write: true)
        try a1.add(sha256DigestValue: b2.sha256DigestValue!, name: "test.txt")
        let b3 = Blob(contents: Data(String(stringLiteral: "new file").utf8))
        _ = a1.hash(obj: b3, write: true)
        try a1.add(sha256DigestValue: b3.sha256DigestValue!, name: "new.txt")
        
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
        try a1.add(sha256DigestValue: b1.sha256DigestValue!, name: "test.txt")
        let b2 = Blob(contents: Data(String(stringLiteral: "version 2").utf8))
        _ = a1.hash(obj: b2, write: true)
        try a1.add(sha256DigestValue: b2.sha256DigestValue!, name: "test.txt")
        let b3 = Blob(contents: Data(String(stringLiteral: "new file").utf8))
        _ = a1.hash(obj: b3, write: true)
        try a1.add(sha256DigestValue: b3.sha256DigestValue!, name: "new.txt")
        
        let t1Hash = a1.writeTree()

        let c1Hash = try a1.commitTree(tree: t1Hash, message: "commit number one")
        let currentTime: Date = .now
        let c1 = a1.objects[c1Hash] as! Commit
        
        #expect(c1.type == .commit)
        #expect(c1.tree == t1Hash)
        #expect(c1.parents == [])
        #expect(c1.message == "commit number one")
        #expect(c1.timestamp.distance(to: currentTime) < TimeInterval(1))
    }
}
