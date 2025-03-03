//
//  AuditionDataModel.swift
//  audition
//
//  Created by Jake Medina on 1/15/25.
//

import Foundation
import PencilKit

enum AuditionError: Error {
    case runtimeError(String)
}

protocol AuditionDataModelDelegate: AnyObject {
    func headDidChange(_ newValue: String)
}

extension AuditionDataModelDelegate {
    func headDidChange(_ newValue: String) { }
}

struct AuditionFile {
    let content: Data
    let contentTypeIdentifier: String?
    let name: String
    
    init(content: Data, name: String) {
        self.content = content
        self.contentTypeIdentifier = nil
        self.name = name
    }
    
    init(content: Data, contentTypeIdentifier: CFString, name: String) {
        self.content = content
        self.contentTypeIdentifier = contentTypeIdentifier as String
        self.name = name
    }
    
    init(content: Data, contentTypeIdentifier: String, name: String) {
        self.content = content
        self.contentTypeIdentifier = contentTypeIdentifier
        self.name = name
    }
    
    init(from drawing: PKDrawing, name: String) {
        self.content = drawing.dataRepresentation()
        self.contentTypeIdentifier = PKAppleDrawingTypeIdentifier as String
        self.name = name
    }
    
    init(from stroke: PKStroke, name: String) throws {
        self.content = try stroke.dataRepresentation()
        self.contentTypeIdentifier = "PKAppleStrokeTypeIdentifier"
        self.name = name
    }
}

class AuditionDataModel: CustomStringConvertible, Codable, ObservableObject, Identifiable {
    @Published private(set) var objects: [String : AuditionObjectProtocol]
    @Published private(set) var index: [TreeEntry]
    
    @Published private(set) var HEAD: String {
        didSet {
            delegate?.headDidChange(HEAD)
        }
    }
    @Published private(set) var branches: [String : String]
    
    weak var delegate: AuditionDataModelDelegate?
    
    init() {
        self.objects = [:]
        self.index = []
        self.HEAD = "main"
        self.branches = [:]
    }
    
    init(objects: [String : AuditionObjectProtocol], index: [TreeEntry], HEAD: String, branches: [String : String]) {
        self.objects = objects
        self.index = index
        self.HEAD = HEAD
        self.branches = branches
    }
    
    var currentBranch: String? {
        return branches[HEAD] != nil ? HEAD : nil
    }
    
    // returns the full branch name if HEAD points to a branch.
    // otherwise, return the first 7 characters of the commit hash.
    var shortHEAD: String {
        return headIsDetached ? String(HEAD.prefix(7)) : HEAD
    }
    
    var headIsDetached: Bool {
        if branches[HEAD] != nil {
            return false
        } else if objects[HEAD] is Commit {
            return true
        } else {
            // assuming HEAD points to default branch
            // but no commits have been made yet.
            // we will not consider this as 'detached HEAD' state
            return false
        }
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
            let b = Blob(from: file)
            
            // update index
            let h = hash(obj: b, write: true)
            try updateIndex(sha256DigestValue: h, name: file.name)
        }
    }
    
    // returns: the hash of the created commit
    func commit(message: String) throws -> String {
        // TODO: decide if empty commmits should be allowed
        
        let commit: String
        
        if let parent = branches[HEAD] {
            // write the tree from the index
            let h = writeTree()
            // write the commit from the tree
            commit = try commitTree(tree: h, parents: [parent], message: message)
        } else if let parent = objects[HEAD] as? Commit {
            throw AuditionError.runtimeError("Error: Commit not successful. Commits cannot be made in 'detached HEAD' mode.")
        } else {
            let h = writeTree()
            commit = try commitTree(tree: h, message: message)
        }
        
        // move the branch ref to point to the new commit
        // if head points to non-existent branch, this will 'create' a branch pointing to the commit
        branches[HEAD] = commit
        return commit
    }
    
    // creates a branch from the current HEAD
    func createBranch(branchName: String) throws {
        guard branches[branchName] == nil else {
            throw AuditionError.runtimeError("A branch named '\(branchName)' already exists")
        }
        
        guard objects[branchName] == nil else {
            throw AuditionError.runtimeError("A branch cannot be named after an existing object ref")
        }
        
        if let HEADcommit = branches[HEAD] {
            branches[branchName] = HEADcommit
        } else if let HEADcommit = objects[HEAD] as? Commit {
            branches[branchName] = HEADcommit.sha256DigestValue!
        } else {
            throw AuditionError.runtimeError("Cannot create new branch: HEAD does not point to an existing branch or commit")
        }
    }
    
    func checkout(branch: String, newBranch: Bool = false) throws {
        // ensure that there will be a new branch created, or that a branch already exists
        guard newBranch || branches[branch] != nil else {
            throw AuditionError.runtimeError("A branch named '\(branch)' does not exist")
        }
        if newBranch {
            try createBranch(branchName: branch)
        }
        
        HEAD = branch
    }
    
    func checkout(commit: String) throws {
        // ensure that there will be a new branch created, or that a branch already exists
        guard objects[commit] != nil else {
            throw AuditionError.runtimeError("Commit '\(commit)' does not exist")
        }
        
        guard objects[commit] is Commit else {
            throw AuditionError.runtimeError("Ref '\(commit)' does not refer to a commit")
        }
        HEAD = commit
    }
    
    // check out the HEAD
    func showTree() throws -> Tree {
        guard let HEADcommit = branches[HEAD] else {
            throw AuditionError.runtimeError("HEAD does not point to an existing branch")
        }
        do {
            return try showTree(commit: HEADcommit)
        } catch let error {
            throw AuditionError.runtimeError("Unable to read branch pointed to by HEAD: \(error)")
        }
    }
    
    func showTree(commit: String) throws -> Tree {
        guard let commit = objects[commit] as? Commit else {
            throw AuditionError.runtimeError("Unable to read commit \(commit)")
        }
        
        guard let tree = objects[commit.tree] as? Tree else {
            throw AuditionError.runtimeError("Unable to read tree \(commit.tree) from commit \(commit)")
        }
        
        return tree
    }
    
    // NOTE: HEAD must point to a branch
    // TODO: This method assumes that HEAD points to a branch and should probably be redone to support 'detached HEAD' state.
    func showBlobs() throws -> [Blob] {
        guard let HEADcommit = branches[HEAD] else {
            throw AuditionError.runtimeError("HEAD does not point to an existing branch")
        }
        return try showBlobs(commit: HEADcommit)
    }
    
    func showBlobs(commit: String) throws -> [Blob] {
        let t = try showTree(commit: commit)
        
        var blobs = [Blob]()
        for entry in t.entries {
            if entry.type == .blob, let blob = objects[entry.hash] as? Blob {
                blobs.append(blob)
            }
        }
        
        return blobs
    }
    
    // returns: the current log of past commits, starting at HEAD
    func log() throws -> [Commit] {
        do {
            return try log(branch: HEAD)
        } catch {
            do {
                return try log(commit: HEAD)
            } catch {
                throw AuditionError.runtimeError("Unable to read ref pointed to by HEAD. Perhaps there is nothing committed yet?")
            }
        }
    }
    
    // returns: the current log of past commits, starting at the most recent commit in `branch`
    func log(branch: String) throws -> [Commit] {
        guard let commit = branches[branch] else {
            throw AuditionError.runtimeError("Unable to read branch \(branch)")
        }
        return try log(commit: commit)
    }
    
    // returns: the current log of past commits, starting at commit `commit`
    func log(commit: String) throws -> [Commit] {
        guard let c = objects[commit] as? Commit else {
            throw AuditionError.runtimeError("Unable to read commit \(commit)")
        }
        
        // assemble commit history
        var commits = [Commit]()
        
        var current: Commit? = c
        while let commit = current {
            // TODO: handle case where commit has multiple parents (in the case of a merge)
            commits.append(commit)
            if let newCurrentHash = commit.parents.first {
                current = objects[newCurrentHash] as? Commit
            } else {
                current = nil
            }
        }
        return commits
    }
    
    // TODO: Make the AuditionDataModel maintain a thumbnail of itself instead of having other objects potentially call thumbnail redundantly
    // TODO: The thumbnail will evaluate to nil if in 'detached HEAD' state. Figure out which thumbnail to return if in 'detached HEAD' state.
    var thumbnail: UIImage? {
        print("thumbnail being generated")
        #warning("The thumbnail will evaluate to nil if in 'detached HEAD' state. Figure out which thumbnail to return if in 'detached HEAD' state.")
        return getThumbnail()
    }
    
    // if no commit passed, get thumbnail from HEAD
    // NOTE: if not passing a commit, HEAD must point to a branch
    // TODO: This method, given no arguments, assumes that HEAD points to a branch and should probably be redone to support 'detached HEAD' state.
    func getThumbnail(commit: Commit? = nil) -> UIImage? {
        let d: PKDrawing
        
        do {
            let blobs: [Blob]
            if let commit {
                blobs = try showBlobs(commit: commit.sha256DigestValue!)
            } else {
                blobs = try showBlobs()
            }
            d = try blobs[0].createDrawing()
            return d.image(from: d.bounds, scale: 3.0)
        } catch let error {
            print("error: failed to create thumbnail from AuditionDataModel: \(error)")
            return nil
        }
    }
    
    // returns a Dictionary where:
    // key: a String, representing the commit hash of a commit in the data model.
    // value: an Array of strings, representing a list of branches that point to the keyed commit
    func getBranchesForCommits() -> [String : [String]] {
        var branchesForCommit: [String : [String]] = [:]
        for (branch, hash) in branches {
            branchesForCommit[hash, default: []].append(branch)
        }
        return branchesForCommit
    }
    
    func getRootsAsTrees() -> [TreeNodeData<String>] {
        var branchesForCommits = getBranchesForCommits()
        print("************* STARTING ALGORITHM ***************")
        var wrappers: [String : TreeNodeData<String>] = [:]
        var rootNodes: [TreeNodeData<String>] = []
        
        func alg(_ cur: TreeNodeData<String>) {
            // mark cur as visited
            wrappers[cur.commit.sha256DigestValue!] = cur
            
            // if cur has parents
            if !cur.commit.parents.isEmpty {
                for pCommit in cur.commit.parents {
                    // parent visited?
                    if let p = wrappers[pCommit] {
                        p.addChild(cur)
                    } else {
                        let pCommitObj = objects[pCommit] as! Commit
                        let isHEAD = headIsDetached ? pCommit == HEAD : pCommit == branches[HEAD]
                        let p = TreeNodeData(commit: pCommitObj, value: String(pCommit.prefix(7)), children: [cur], branches: branchesForCommits[pCommit], isHEAD: isHEAD)
                        alg(p)
                    }
                }
            } else {
                // at this point, if the node has no parents,
                // it can be considered a root node.
                //
                // we don't have to check if a root node is already in the array
                // because a node will never be accessed more than once.
                // this is because we don't look at already visited nodes
                rootNodes.append(cur)
            }
        }
        
        // TODO: change sortedBranches to be an array of branches with in-degree of zero
        do {
            let reachableCommitsWithInDegreeZero: [String] = try getReachableCommitsWithInDegreeZero()
            var timeSortedCommits: [String] {
                var arr = [Commit]()
                for commit in reachableCommitsWithInDegreeZero {
                    arr.append(objects[commit] as! Commit)
                }
                arr.sort(by: >)
                var res = [String]()
                for c in arr {
                    res.append(c.sha256DigestValue!)
                }
                return res
            }
            
            for commit in timeSortedCommits {
                let isHEAD = headIsDetached ? commit == HEAD : commit == branches[HEAD]
                let w = TreeNodeData(commit: objects[commit] as! Commit, value: String(commit.prefix(7)), children: [], branches: branchesForCommits[commit], isHEAD: isHEAD)
                alg(w)
            }
        } catch let error {
            print("ERROR: AuditionDataModel.getRootsAsTrees failed: \(error)")
        }
        print("************* END OF ALGORITHM ***************")
        return rootNodes
    }
    
    // FIXME: This might be better off as a struct, is there a need to hold references to these?
    class CommitWalkInfo: Equatable {
        static func == (lhs: AuditionDataModel.CommitWalkInfo, rhs: AuditionDataModel.CommitWalkInfo) -> Bool {
            return lhs.visited == rhs.visited && lhs.inDegree == rhs.inDegree
        }
        
        var visited: Bool = false
        var inDegree: Int = 0
        
        init(){
            self.visited = false
            self.inDegree = 0
        }
        
        init(visited: Bool, inDegree: Int) {
            self.visited = visited
            self.inDegree = inDegree
        }
        
        public var description: String {
            return ("CommitWalkInfo(visited: \(visited), inDegree: \(inDegree)")
        }
    }

    // returns a dictionary of commits that can be reached from one or more branches
    // the resulting dicionary contains
    func computeInDegreeDict() throws -> [String : CommitWalkInfo] {
        var commits: [String : CommitWalkInfo] = [:]
        
        for (branchName, branchRef) in branches {
            try countInDegreesFromCommit(id: branchRef, commits: &commits)
        }
        
        return commits
    }
    
    // NOT SAFE: ONLY USE FOR TESTING
    // manually set an object in the object store
    func unsafeSetObject(key: String, value: AuditionObjectProtocol) {
        objects[key] = value
    }
    
    // NOT SAFE: ONLY USE FOR TESTING
    func unsafeSetBranch(branchName: String, commitHash: String) {
        branches[branchName] = commitHash
    }
    
    // NOT SAFE: LEAVES COMMITS DANGLING, ONLY USE FOR TESTING
    func unsafeDeleteBranch(branchName: String) {
        branches.removeValue(forKey: branchName)
    }

    // call this function on all branch refs
    func countInDegreesFromCommit(id: String, commits: inout [String : CommitWalkInfo]) throws {
        guard let commitObj: Commit = objects[id] as? Commit else {
            throw AuditionError.runtimeError("error: countInDegreesFromCommit looking at a branchRef that does not point to a valid commit.")
        }
        
        if commits[id] == nil {
            commits[id] = CommitWalkInfo()
        }
        
        if commits[id]!.visited == false {
            commits[id]!.visited = true
            let parents: [String] = commitObj.parents
            for p in parents {
                if commits[p] != nil {
                    commits[p]!.inDegree += 1
                } else {
                    commits[p] = CommitWalkInfo(visited: false, inDegree: 1)
                }
                try countInDegreesFromCommit(id: p, commits: &commits)
            }
        }
    }
    
    func getReachableCommitsWithInDegreeZero() throws -> [String] {
        let commitInfo = try computeInDegreeDict()
        var result: [String] = []
        for (commit, info) in commitInfo {
            if info.inDegree == 0 {
                result.append(commit)
            }
        }
        return result
    }
    
    enum CodingKeys: String, CodingKey {
        case objects
        case index
        case HEAD
        case branches
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        var objectsContainer = container.nestedUnkeyedContainer(forKey: .objects)
        for (key, value) in objects {
            let wrapper = AuditionObjectWrapper(hash: key, object: value)
            try objectsContainer.encode(wrapper)
        }
        
        try container.encode(index, forKey: .index)
        try container.encode(HEAD, forKey: .HEAD)
        try container.encode(branches, forKey: .branches)
    }
    
    required init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        var objectsContainer = try values.nestedUnkeyedContainer(forKey: .objects)
        var objects = [String : AuditionObjectProtocol]()
        while !objectsContainer.isAtEnd {
            let wrapper = try objectsContainer.decode(AuditionObjectWrapper.self)
            objects[wrapper.hash] = wrapper.object
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
    let hash: String
    let object: AuditionObjectProtocol
    
    enum CodingKeys: String, CodingKey {
        case type
        case data
        case hash
    }
    
    init(hash: String, object: AuditionObjectProtocol) {
        self.hash = hash
        self.object = object
    }
    
    init(object: AuditionObjectProtocol) {
        self.hash = object.sha256DigestValue!
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
        
        try container.encode(hash, forKey: .hash)
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
        
        self.hash = try values.decode(String.self, forKey: .hash)
    }
}
