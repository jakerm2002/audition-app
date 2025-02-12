//
//  SwiftUITreeView.swift
//  audition
//
//  Created by Jake Medina on 2/7/25.
//

import SwiftUI

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


struct Node<A: CustomStringConvertible>: View {
    @ObservedObject var x: DisplayTree<A>
    
    var body: some View {
        return ZStack {
            Image("moon")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipShape(Circle())
                .overlay {
                    Circle()
                        .stroke(Color.primary, lineWidth: 2)
                }
        }.onAppear{
            // if I am the root node
            if self.x.parent == nil {
                print("laying out initial tree...")
                self.x.relayout()
            }
        }
    }
}


struct Point: Hashable {
    var x: Int
    var y: Int
    
    static let zero = Point(x: 0, y: 0)
}


final class DisplayTree<A>: ObservableObject, Identifiable, CustomStringConvertible {
    init(commit: Commit, value: A, point: Point = .zero, children: [DisplayTree<A>]? = nil) {
        self.commit = commit
        self.value = value
        self.point = point
        self.children = children
        children?.forEach {
            $0.parent = self
        }
    }
    
    @Published var commit: Commit
    @Published var value: A
    @Published var point: Point = .zero
    @Published private(set) var children: [DisplayTree<A>]?
    
    weak var parent: DisplayTree<A>? = nil
    
    var id: ObjectIdentifier {
        ObjectIdentifier(self)
    }
    
    var description: String {
        "DisplayTree(\(value) \(point) with *\(children?.description ?? "no children")*"
    }
    
    func addChild(_ child: DisplayTree<A>) {
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


extension DisplayTree {
    func modifyAll(_ transform: (DisplayTree<A>) -> ()) {
        transform(self)
        if let children {
            for child in children {
                child.modifyAll(transform)
            }
        }
    }
    
    var allSubtrees: [DisplayTree<A>] {
        var childrenSubtrees: [DisplayTree<A>] = []
        if let children {
            for child in children {
                childrenSubtrees.append(contentsOf: child.allSubtrees)
            }
        }
        return [self] + childrenSubtrees
    }
    
    var allEdges: [(from: DisplayTree<A>, to: DisplayTree<A>)] {
        var result: [(from: DisplayTree<A>, to: DisplayTree<A>)] = []
        if let children {
            for child in children {
                result.append((from: self, to: child))
                result.append(contentsOf: child.allEdges)
            }
        }
        return result
    }
}


extension DisplayTree {
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


struct DrawTree<A, Node>: View where Node: View {
    @ObservedObject var tree: DisplayTree<A>
    var horizontalSpacing: CGFloat = 40
    var verticalSpacing: CGFloat = 40
    let node: (DisplayTree<A>) -> Node
    let nodeSize = CGSize(width: 100, height: 100)
    
    init(tree: DisplayTree<A>, node: @escaping (DisplayTree<A>) -> Node) {
        self.tree = tree
        self.node = node
    }
    
    func cgPoint(for point: Point) -> CGPoint {
        CGPoint(x: CGFloat(point.x) * (nodeSize.width + horizontalSpacing), y: CGFloat(point.y) * (nodeSize.height + verticalSpacing))
    }
    
    var body: some View {
        return ZStack(alignment: .topLeading) {
            ForEach(tree.allSubtrees) { (tree: DisplayTree<A>) in
                self.node(tree)
                    .frame(width: self.nodeSize.width, height: self.nodeSize.height)
                    .alignmentGuide(.leading, computeValue: { _ in
                        -self.cgPoint(for: tree.point).x
                    })
                    .alignmentGuide(.top, computeValue: { _ in
                        -self.cgPoint(for: tree.point).y
                    })
            }
        }
        .background(
            ZStack {
                ForEach(tree.allEdges, id: \.to.id) { edge in
                    Line(from: self.cgPoint(for: edge.from.point), to: self.cgPoint(for: edge.to.point))
                        .stroke(Color(uiColor: .systemGray3), lineWidth: 2)
                }
            }
            .offset(CGSize(width: nodeSize.width/2, height: nodeSize.height/2))
        )
    }
}


func sampleTree() -> DisplayTree<String> {
    let root = DisplayTree(commit: Commit(tree: "", parents: [], message: "", timestamp: .now), value: "Loading")
    return root
}

struct SwiftUITreeView: View {
    var edgeFade = Gradient(stops:
                            [Gradient.Stop(color: Color.clear, location: 0.0),
                             Gradient.Stop(color: Color.black, location: 0.05),
                             Gradient.Stop(color: Color.black, location: 0.95),
                             Gradient.Stop(color: Color.clear, location: 1.0)])
    
    @EnvironmentObject var model: AuditionDataModel
    @State var tree = sampleTree()
    @Binding var updatesCounter: Int
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            HStack {
                DrawTree(tree: tree, node: { Node(x: $0) })
                    .animation(.default)
                    .onAppear{
                        tree = model.getRootsAsTrees().first ?? tree
                    }
            }
        }
        // TODO: there may be a more graphics-efficient way to do this
        // fades away content when it reaches the edges of the screen
        .mask(LinearGradient(gradient: edgeFade, startPoint: .top, endPoint: .bottom))
        .mask(LinearGradient(gradient: edgeFade, startPoint: .leading, endPoint: .trailing))
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    updatesCounter += 1
                    dismiss()
                } label: {
                    Image(systemName: "chevron.backward")
                }
            }
        }
    }
}

func generateSampleData() -> AuditionDataModel{
    do {
        let content1 = Data(String(stringLiteral: "test one").utf8)
        let filename1 = "test1.txt"
        
        let f1 = AuditionFile(
            content: content1,
            name: filename1
        )
        
        let a1 = AuditionDataModel()
        try a1.add(f1)
        
        let commitMessage1 = "initial commit"
        var commit1: String = try a1.commit(message: commitMessage1)
        print("commit1 \(commit1)")
        
        let content2 = Data(String(stringLiteral: "test two").utf8)
        let filename2 = "test2.txt"
        
        let f2 = AuditionFile(
            content: content2,
            name: filename2
        )
        
        try a1.add(f2)
        
        let commitMessage2 = "second commit"
        var commit2: String = try a1.commit(message: commitMessage2)
        print("commit2 \(commit2)")
        
        return a1
    } catch {
        print("error: prevew of SwiftUITreeView failed, returning an empty model")
        return AuditionDataModel()
    }
}

func generateSampleDataThreeCommits() -> AuditionDataModel {
    do {
        let content1 = Data(String(stringLiteral: "test one").utf8)
        let filename1 = "test1.txt"
        let f1 = AuditionFile(
            content: content1,
            name: filename1
        )
        
        let content2 = Data(String(stringLiteral: "test two").utf8)
        let filename2 = "test2.txt"
        
        let f2 = AuditionFile(
            content: content2,
            name: filename2
        )
        
        let content3 = Data(String(stringLiteral: "test three").utf8)
        let filename3 = "test3.txt"
        
        let f3 = AuditionFile(
            content: content3,
            name: filename3
        )
        
        let commitMessage1 = "initial commit"
        let commitMessage2 = "second commit"
        let commitMessage3 = "third commit"
        
        // CREATE A NEW MODEL
        let a2 = AuditionDataModel()
        try a2.add(f1)
        
        let commit1 = try a2.commit(message: commitMessage1)
        print("commit1 \(commit1)")
        
        // add a branch from the initial commit
        try a2.createBranch(branchName: "b1")
        try a2.createBranch(branchName: "b2")
        
        try a2.checkout(branch: "b1")
        try a2.add(f2)
        let commit2 = try a2.commit(message: commitMessage2)
        print("commit2 \(commit2)")
        
        try a2.checkout(branch: "b2")
        try a2.add(f3)
        var commit3: String = try a2.commit(message: commitMessage3)
        print("commit3 \(commit3)")
        
        return a2
    } catch {
        print("error: prevew of SwiftUITreeView failed, returning an empty model")
        return AuditionDataModel()
    }
}

#Preview {
//    SwiftUITreeView(model: generateSampleData())
    var model: AuditionDataModel = generateSampleDataThreeCommits()
    SwiftUITreeView(updatesCounter: Binding.constant(0)).environmentObject(model)
}
