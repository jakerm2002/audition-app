//
//  AuditionDataModel.swift
//  audition
//
//  Created by Jake Medina on 1/15/25.
//

import Foundation

class AuditionDataModel: CustomStringConvertible {
    private var objects: [String : AuditionObjectProtocol]
    
    init() {
        self.objects = [:]
    }
    
    init(objects: [String : AuditionObjectProtocol]) {
        self.objects = objects
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
    func add() {
        
    }
    
    // creates a tree object from the state of the index
    // should mimic git write-tree
    func writeTree() {
        // add the tree object to the `objects` array
    }
    
    // takes the SHA-1 hash of a tree
    func commitTree(tree: String, parents: [String], message: String) {
        // generate the SHA-1 hash of a commit
        // add the commit object to the `objects` array
    }
    
    public var description: String {
        return "\(objects as AnyObject)"
    }
}
