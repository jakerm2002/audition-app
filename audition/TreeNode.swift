//
//  TreeTreeNode.swift
//  audition
//
//  Created by Jake Medina on 1/14/25.
//

import Foundation

final class TreeNode<Value> {
    var value: Value
    private(set) var children: [TreeNode]

    var count: Int {
        1 + children.reduce(0) { $0 + $1.count }
    }

    init(_ value: Value) {
        self.value = value
        children = []
    }

    init(_ value: Value, children: [TreeNode]) {
        self.value = value
        self.children = children
    }

    init(_ value: Value, @TreeNodeBuilder builder: () -> [TreeNode]) {
        self.value = value
        self.children = builder()
    }

    func add(child: TreeNode) {
        children.append(child)
    }
}

extension TreeNode: Equatable where Value: Equatable {
    static func ==(lhs: TreeNode, rhs: TreeNode) -> Bool {
        lhs.value == rhs.value && lhs.children == rhs.children
    }
}

extension TreeNode: Hashable where Value: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(value)
        hasher.combine(children)
    }
}

extension TreeNode: Codable where Value: Codable { }

extension TreeNode where Value: Equatable {
    func find(_ value: Value) -> TreeNode? {
        if self.value == value {
            return self
        }

        for child in children {
            if let match = child.find(value) {
                return match
            }
        }

        return nil
    }
}

@resultBuilder
struct TreeNodeBuilder {
    static func buildBlock<Value>(_ children: TreeNode<Value>...) -> [TreeNode<Value>] {
        children
    }
}
