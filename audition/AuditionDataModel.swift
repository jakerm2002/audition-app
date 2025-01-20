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

class AuditionDataModel: CustomStringConvertible, Codable {
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
    
    enum CodingKeys: String, CodingKey {
        case objects
        case index
        case HEAD
        case branches
    }
    
    enum ObjectKeys: String, CodingKey {
        case hash
        case object
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
//        var objectsContainer = container.nestedContainer(keyedBy: ObjectKeys.self, forKey: .objects)
        
        
          // only encodes one object, keeps replacing the key with a new value
//        for object in objects {
//            try objectsContainer.encode(object.key, forKey: .hash)
//            try objectsContainer.encode(AuditionObjectWrapper(object: object.value), forKey: .object)
//        }
        
          // encodes ONLY the values of `objects` inside of objects[object]
//        for (key, value) in objects {
//            let wrapper = AuditionObjectWrapper(object: value)
//            try objectsContainer.encode(wrapper, forKey: .object)
//        }
        
          // encodes ONLY the values of `objects` inside of objects
//        var objectsWithWrappers = [AuditionObjectWrapper]()
//        for (key, value) in objects {
//            objectsWithWrappers.append(AuditionObjectWrapper(object: value))
//        }
//        try container.encode(objectsWithWrappers, forKey: .objects)
        
        var objectsContainer = container.nestedUnkeyedContainer(forKey: .objects)
        for (key, value) in objects {
            let wrapper = AuditionObjectWrapper(object: value).object
            var objectContainer = objectsContainer.nestedContainer(keyedBy: ObjectKeys.self)
            try objectContainer.encode(key, forKey: .hash)
            try objectContainer.encode(value, forKey: .object)
        }
        
        try container.encode(index, forKey: .index)
        try container.encode(HEAD, forKey: .HEAD)
        try container.encode(branches, forKey: .branches)
    }
    
    required init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        // decode ObjectKeys
        let objectsContainer = try values.nestedContainer(keyedBy: ObjectKeys.self, forKey: .objects)
        var objects = [String : AuditionObjectProtocol]()
        for key in objectsContainer.allKeys {
            let wrapper = try objectsContainer.decode(AuditionObjectWrapper.self, forKey: .object)
            objects[key.rawValue] = wrapper.object
        }
        
        self.objects = objects
        self.index = try values.decode([TreeEntry].self, forKey: .index)
        self.HEAD = try values.decode(String.self, forKey: .HEAD)
        self.branches = try values.decode([String : String].self, forKey: .branches)
    }
    
    public var description: String {
        return "\(objects as AnyObject)"
    }
}

struct AuditionObjectWrapper: Codable {
    let object: AuditionObjectProtocol
    
    enum CodingKeys: String, CodingKey {
        case type
        case data
    }
    
    init(object: AuditionObjectProtocol) {
        self.object = object
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
//        potentially more efficient to check the AuditionObjectType
//        instead of trying to do let obj as Blob/Tree/Commit?
        
//        example:
//        switch object.type {
//        case .blob:
//            let blob = object as! Blob
//            try container.encode(AuditionObjectType.blob, forKey: .type)
//            try container.encode(object as! Blob, forKey: .data)
//        }
        
        switch object {
        case let blob as Blob:
            try container.encode(AuditionObjectType.blob, forKey: .type)
            try container.encode(blob, forKey: .data)
        case let tree as Tree:
            try container.encode(AuditionObjectType.tree, forKey: .type)
            try container.encode(tree, forKey: .data)
        case let commit as Commit:
            try container.encode(AuditionObjectType.commit, forKey: .type)
            try container.encode(commit, forKey: .data)
        default:
            throw EncodingError.invalidValue(object, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Cannot encode AuditionObject of unknown type"))
        }
    }
    
    init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        let type = try values.decode(AuditionObjectType.self, forKey: .type)
        
        switch type {
        case .blob:
            self.object = try values.decode(Blob.self, forKey: .data)
        case .tree:
            self.object = try values.decode(Tree.self, forKey: .data)
        case .commit:
            self.object = try values.decode(Commit.self, forKey: .data)
        }
    }
}
