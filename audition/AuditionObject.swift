//
//  AuditionObject.swift
//  audition
//
//  Created by Jake Medina on 1/15/25.
//

import Foundation
import CryptoKit

protocol SHA256Hashable {
    var sha256DigestObject: SHA256Digest? { get }
    var sha256DigestValue: String? { get }
}

protocol AuditionObjectProtocol: SHA256Hashable {
    var type: AuditionObjectType { get }
}

enum AuditionObjectType: String {
    case blob = "blob"
    case tree = "tree"
    case commit = "commit"
}

class Blob: AuditionObjectProtocol, CustomStringConvertible {
    let type: AuditionObjectType
    let contents: Data
    
    init(contents: Data) {
        type = AuditionObjectType.blob
        self.contents = contents
    }
    
    // create a hash using the contents of a blob
    var sha256DigestObject: SHA256Digest? {
        return SHA256.hash(data: contents)
    }
    
    // create a hash using the contents of a blob
    var sha256DigestValue: String? {
        return sha256DigestObject?.hexString
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

class Tree: AuditionObjectProtocol, CustomStringConvertible {
    let type: AuditionObjectType
    let entries: [TreeEntry]
    
    init(entries: [TreeEntry]) {
        type = AuditionObjectType.tree
        self.entries = entries
    }
    
    var plist: [Any] {
        var plist: [Any] = []
        for item in entries {
            plist.append([item.type.rawValue, item.hash, item.name])
        }
        return plist
    }
    
    // create a hash using all of the entries of a tree
    var sha256DigestObject: SHA256Digest? {
        do {
            let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .binary, options: .zero)
            return SHA256.hash(data: data)
        } catch {
            print("Unable to serialize Tree to plist:\n\(self.description)")
            return nil
        }
    }
    
    var sha256DigestValue: String? {
        sha256DigestObject?.hexString
    }
    
    public var description: String {
        var entriesStr: [String] = []
        for item in entries {
            entriesStr.append(item.description)
        }
        return entriesStr.joined(separator: "\n")
    }
}

class Commit: AuditionObjectProtocol, CustomStringConvertible, Hashable {
    let type: AuditionObjectType
    let tree: String
    let parents: [String]
    let message: String
    let timestamp: Date
    
    init(tree: String, parents: [String], message: String, timestamp: Date) {
        self.type = AuditionObjectType.commit
        self.tree = tree
        self.parents = parents
        self.message = message
        self.timestamp = timestamp
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
    
    var plist: [Any] {
        return [type.rawValue, tree, parents, message, timestamp]
    }
    
    // create a hash using all of the contents of a commit: type, tree, parents, message, and timestamp
    var sha256DigestObject: SHA256Digest? {
        do {
            let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .binary, options: .zero)
            return SHA256.hash(data: data)
        } catch {
            print("Unable to serialize Commit to plist:\n\(self.description)")
            return nil
        }
    }
    
    var sha256DigestValue: String? {
        return sha256DigestObject?.hexString
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

extension SHA256Digest{
    public var hexString: String {
        let input = Data(self) as NSData
        var bytes = [UInt8](repeating: 0, count: input.length)
        input.getBytes(&bytes, length: input.length)
        
        var hexString = ""
        for byte in bytes {
            hexString += String(format:"%02x", UInt8(byte))
        }
        return hexString
    }
}
