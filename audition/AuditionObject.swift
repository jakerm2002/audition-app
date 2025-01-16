//
//  AuditionObject.swift
//  audition
//
//  Created by Jake Medina on 1/15/25.
//

import Foundation

enum AuditionObjectType {
    case blob
    case tree
    case commit
}

class AuditionObject {
    let type: AuditionObjectType
    
    init(type: AuditionObjectType) {
        self.type = type
    }
}

class Blob: AuditionObject {
    let contents: Data
    
    init(contents: Data) {
        self.contents = contents
        super.init(type: AuditionObjectType.blob)
    }
}

struct TreeEntry {
    let type: AuditionObjectType
    let hash: String
    let name: String
}

class Tree: AuditionObject {
    let entries: [TreeEntry]
    
    init(entries: [TreeEntry]) {
        self.entries = entries
        super.init(type: AuditionObjectType.tree)
    }
}

class Commit: AuditionObject, CustomStringConvertible {
    let tree: String
    let parents: [String]
    let message: String
    let timestamp: Date
    
    init(tree: String, parents: [String], message: String, timestamp: Date) {
        self.tree = tree
        self.parents = parents
        self.message = message
        self.timestamp = timestamp
        super.init(type: AuditionObjectType.commit)
    }
    
    public var description: String {
        var treeDescription: String = "tree \(tree)"
        
        var parentsDescription: String = {
            var parentsAppend = parents
            for (idx, item) in parentsAppend.enumerated() {
                parentsAppend[idx] = "parent \(item)"
            }
            return parentsAppend.joined(separator: "\n")
        }()
        
        return "\(treeDescription)\n\(parentsDescription)\n\(timestamp)\n\n\(message)"
    }
}
