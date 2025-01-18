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

class AuditionDataModel: CustomStringConvertible {
    private(set) var objects: [String : AuditionObjectProtocol]
    private(set) var index: [TreeEntry]
    
    init() {
        self.objects = [:]
        self.index = []
    }
    
    init(objects: [String : AuditionObjectProtocol], index: [TreeEntry]) {
        self.objects = objects
        self.index = index
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
    func add(sha256DigestValue: String, name: String) throws {
        guard objects[sha256DigestValue] != nil else {
            throw AuditionError.runtimeError("Hash \(sha256DigestValue) does not exist in AuditionDataModel.objects")
        }
        
        let obj: AuditionObjectProtocol = objects[sha256DigestValue]!
        index.append(TreeEntry(type: obj.type, hash: obj.sha256DigestValue!, name: name))
    }
    
    // creates a tree object from the state of the index
    // should mimic git write-tree
    func writeTree() {
        let tree = Tree(entries: index)
        objects[tree.sha256DigestValue!] = tree
    }
    
    // takes the SHA-1 hash of a tree
    func commitTree(tree: String, parents: [String] = [], message: String) throws {
        guard objects[tree] != nil else {
            throw AuditionError.runtimeError("Tree cannot be committed because the hash \(tree) does not exist in AuditionDataModel.objects")
        }
        
        guard objects[tree]?.type == .tree else {
            throw AuditionError.runtimeError("Tree cannot be committed because the hash \(tree) does not refer to a tree")
        }
        
        let commit = Commit(tree: tree, parents: parents, message: message, timestamp: .now)
        objects[commit.sha256DigestValue!] = commit
    }
    
    public var description: String {
        return "\(objects as AnyObject)"
    }
}
