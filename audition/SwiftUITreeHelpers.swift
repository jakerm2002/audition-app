//
//  SwiftUITreeHelpers.swift
//  audition
//
//  Created by Jake Medina on 2/17/25.
//

import SwiftUI

final class TreeNodeData<A>: ObservableObject, Identifiable, CustomStringConvertible {
    init(commit: Commit, value: A, point: Point = .zero, children: [TreeNodeData<A>]? = nil, branches: [String]?, isHEAD: Bool) {
        self.commit = commit
        self.value = value
        self.point = point
        self.children = children
        self.branches = branches ?? []
        self.isHEAD = isHEAD
        children?.forEach {
            $0.parent = self
        }
    }
    
    // TODO: why are these published? They shouldn't ever change
    @Published var commit: Commit
    @Published var value: A
    @Published var point: Point = .zero
    @Published private(set) var children: [TreeNodeData<A>]?
    let branches: [String]
    @Published var isHEAD: Bool
    
    weak var parent: TreeNodeData<A>? = nil
    
    // TODO: change this to a stronger identifier, perhaps self.commit.sha256DigestValue?
    // NOTE: DON'T change it to self.commit.sha256DigestValue, as it is a computed property??
    // That might only be a problem if the computed property changes every time, our hash isn't supposed to change.
    // Reading: https://developer.apple.com/documentation/swift/identifiable,
    // ObjectIdentifier "is only guaranteed to remain unique for the lifetime of an object.
    // If an object has a stronger notion of identity, it may be appropriate to provide a custom implementation."
    var id: ObjectIdentifier {
        ObjectIdentifier(self)
    }
    
    var description: String {
        "TreeNodeData(\(value) \(point) with *\(children?.description ?? "no children")*"
    }
    
    func addChild(_ child: TreeNodeData<A>) {
        if children != nil {
            children!.append(child)
        } else {
            children = [child]
        }
        child.parent = self
        print("setting the parent of node \(child.value) to \(value)")
    }
    
    func relayout() {
        var root = self
        while let p = root.parent {
            root = p
        }
        root.layout()
    }
}


extension TreeNodeData {
    func modifyAll(_ transform: (TreeNodeData<A>) -> ()) {
        transform(self)
        if let children {
            for child in children {
                child.modifyAll(transform)
            }
        }
    }
    
    var allSubtrees: [TreeNodeData<A>] {
        var childrenSubtrees: [TreeNodeData<A>] = []
        if let children {
            for child in children {
                childrenSubtrees.append(contentsOf: child.allSubtrees)
            }
        }
        return [self] + childrenSubtrees
    }
    
    var allEdges: [(from: TreeNodeData<A>, to: TreeNodeData<A>)] {
        var result: [(from: TreeNodeData<A>, to: TreeNodeData<A>)] = []
        if let children {
            for child in children {
                result.append((from: self, to: child))
                result.append(contentsOf: child.allEdges)
            }
        }
        return result
    }
}


extension TreeNodeData {
    func layout() {
        var x: [Int:Int] = [:]
        alt(depth: 0, x: &x)
    }
    
    func alt(depth: Int, x: inout [Int:Int]) {
        print("looking at a node at depth \(depth): \(x.sorted(by: <))")
        var prev: Int
        if x[depth + 1, default: 0] > x[depth, default: 0] {
            prev = x[depth + 1]!
        } else {
            prev = x[depth, default: 0]
        }
        point.x = x[depth, default: 0]
        point.y = depth
        if x[depth] != nil {
            x[depth]! += 1
        } else {
            x[depth] = 1
        }
        x[depth + 1] = prev
        if let children {
            for child in children {
                child.alt(depth: depth+1, x: &x)
            }
        }
    }
    
    func moveRight(_ amount: Int) {
        modifyAll { $0.point.x += amount }
    }
}


struct Line: Shape {
    var from: CGPoint
    var to: CGPoint
    
    var animatableData: AnimatablePair<CGPoint.AnimatableData, CGPoint.AnimatableData> {
        get { return AnimatablePair(from.animatableData, to.animatableData) }
        set {
            from.animatableData = newValue.first
            to.animatableData = newValue.second
        }
    }
    
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: from)
            p.addLine(to: to)
        }
    }
}


struct CircleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Font.body)
            .foregroundStyle(.white)
            .frame(width: 32, height: 32)
            .background(
                Circle()
                    .fill(Color(uiColor: UIColor.systemBlue))
                    .overlay(Circle().fill(configuration.isPressed ? Color.white.opacity(0.5) : Color.clear))
            )
        
    }
}


struct Point: Hashable {
    var x: Int
    var y: Int
    
    static let zero = Point(x: 0, y: 0)
}
