//
//  AuditionObject.swift
//  audition
//
//  Created by Jake Medina on 1/15/25.
//

import Foundation
import CryptoKit

enum AuditionObjectType: String {
    case blob = "blob"
    case tree = "tree"
    case commit = "commit"
}

class AuditionObject {
    let type: AuditionObjectType
    
    init(type: AuditionObjectType) {
        self.type = type
    }
}

class Blob: AuditionObject, CustomStringConvertible {
    let contents: Data
    
    init(contents: Data) {
        self.contents = contents
        super.init(type: AuditionObjectType.blob)
    }
    
    // create a hash using the contents of a blob
    var sha256HashValue: SHA256Digest? {
        return SHA256.hash(data: contents)
    }
    
    public var description: String {
        return contents.description
    }
}

struct TreeEntry: CustomStringConvertible {
    let type: AuditionObjectType
    let hash: String
    let name: String
    
    public var description: String {
        return "\(type) \(hash)      \(name)"
    }
}

class Tree: AuditionObject, CustomStringConvertible {
    let entries: [TreeEntry]
    
    init(entries: [TreeEntry]) {
        self.entries = entries
        super.init(type: AuditionObjectType.tree)
    }
    
    // create a hash using all of the entries of a tree
    var sha256HashValue: SHA256Digest? {
        do {
            var plist: [Any] = []
            for item in entries {
                plist.append([item.type.rawValue, item.hash, item.name])
            }
            print(plist)
            let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .binary, options: .zero)
            return SHA256.hash(data: data)
        } catch {
            print("Unable to serialize Tree to plist:\n\(self.description)")
            return nil
        }
    }
    
    public var description: String {
        var entriesStr: [String] = []
        for item in entries {
            entriesStr.append(item.description)
        }
        return entriesStr.joined(separator: "\n")
    }
}

class Commit: AuditionObject, CustomStringConvertible, Hashable {
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
    
    static func == (lhs: Commit, rhs: Commit) -> Bool {
        return lhs.type == rhs.type && lhs.tree == rhs.tree && lhs.parents == rhs.parents && lhs.message == rhs.message && lhs.timestamp == rhs.timestamp
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(type)
        hasher.combine(tree)
        hasher.combine(parents)
        hasher.combine(message)
        hasher.combine(timestamp)
    }
    
    // create a hash using all of the contents of a commit: type, tree, parents, message, and timestamp
    var sha256HashValue: SHA256Digest? {
        let plist: [Any] = [type.rawValue, tree, parents, message, timestamp]
        
        do {
            let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .binary, options: .zero)
            return SHA256.hash(data: data)
        } catch {
            print("Unable to serialize Commit to plist:\n\(self.description)")
            return nil
        }
    }
    
    public var description: String {
        let treeDescription: String = "tree \(tree)"
        
        let parentsDescription: String = {
            var parentsAppend = parents
            for (idx, item) in parentsAppend.enumerated() {
                parentsAppend[idx] = "parent \(item)"
            }
            return parentsAppend.joined(separator: "\n")
        }()
        
        return "\(treeDescription)\n\(parentsDescription)\n\(timestamp)\n\n\(message)"
    }
}
