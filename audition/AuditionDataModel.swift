//
//  AuditionDataModel.swift
//  audition
//
//  Created by Jake Medina on 1/15/25.
//

import Foundation

enum AuditionError: Error {
    case runtimeError(String)
}

struct AuditionFile {
    let content: Data
    let name: String
}

class AuditionDataModel: CustomStringConvertible {
    private(set) var objects: [String : AuditionObjectProtocol]
    private(set) var index: [TreeEntry]
    
    private(set) var HEAD: String
    private(set) var branches: [String : String]
    
    init() {
        self.objects = [:]
        self.index = []
        self.HEAD = "main"
        self.branches = [:]
    }
    
    init(objects: [String : AuditionObjectProtocol], index: [TreeEntry]) {
        self.objects = objects
        self.index = index
        self.HEAD = "main"
        self.branches = [:]
    }
    
    // params:
    //      write (bool): if true, takes the data and writes it to a blob
    // returns: the SHA-1 hash of the data
    // should mimic `git hash-object [file]`
    func hash(obj: AuditionObjectProtocol, write: Bool) -> String {
        if write {
            objects[obj.sha256DigestValue!] = obj
        }
        
        return obj.sha256DigestValue!
    }
    
    // add a new file to the staging area (aka the 'index')
    // should mimic `git update-index --add --cacheinfo [hash] [filename]`
    // the hash of the file should already exist in `objects`
    func updateIndex(sha256DigestValue: String, name: String) throws {
        guard objects[sha256DigestValue] != nil else {
            throw AuditionError.runtimeError("Hash \(sha256DigestValue) does not exist in AuditionDataModel.objects")
        }
        let obj: AuditionObjectProtocol = objects[sha256DigestValue]!
        
        // check if the index already contains an entry for this filename
        for (idx, item) in index.enumerated() {
            if item.name == name {
                index[idx].hash = obj.sha256DigestValue!
                return
            }
        }
        
        index.append(TreeEntry(type: obj.type, hash: obj.sha256DigestValue!, name: name))
    }
    
    // creates a tree object from the state of the index
    // should mimic git write-tree
    // returns: the SHA-256 hash of the tree
    func writeTree() -> String {
        let tree = Tree(entries: index)
        objects[tree.sha256DigestValue!] = tree
        return tree.sha256DigestValue!
    }
    
    // params:
    //      tree: the SHA-256 hash of a tree
    //      parents: the SHA-256 hashes of any parent commits
    //      message: the commit message
    func commitTree(tree: String, parents: [String] = [], message: String) throws -> String {
        guard objects[tree] != nil else {
            throw AuditionError.runtimeError("Tree cannot be committed because the hash \(tree) does not exist in AuditionDataModel.objects")
        }
        
        guard objects[tree]?.type == .tree else {
            throw AuditionError.runtimeError("Tree cannot be committed because the hash \(tree) does not refer to a tree")
        }
        
        let commit = Commit(tree: tree, parents: parents, message: message, timestamp: .now)
        objects[commit.sha256DigestValue!] = commit
        
        return commit.sha256DigestValue!
    }
    
    // params:
    //      file: file to add content from
    func add(_ file: AuditionFile) throws {
        try add(files: [file])
    }
    
    // params:
    //      files: files to add content from
    func add(files: [AuditionFile]) throws {
        for file in files {
            // create blob
            let b = Blob(contents: file.content)
            
            // update index
            let h = hash(obj: b, write: true)
            try updateIndex(sha256DigestValue: h, name: file.name)
        }
    }
    
    // returns: the hash of the created commit
    func commit(message: String) throws -> String {
        // write the tree from the index
        let h = writeTree()
        
        let commit: String
        // write the commit from the tree
        if let parent = branches[HEAD] {
            commit = try commitTree(tree: h, parents: [parent], message: message)
        } else {
            commit = try commitTree(tree: h, message: message)
        }
        
        // move the branch ref to point to the new commit
        // if head points to non-existent branch, this will 'create' a branch pointing to the commit
        branches[HEAD] = commit
        return commit
    }
    
    public var description: String {
        return "\(objects as AnyObject)"
    }
}
