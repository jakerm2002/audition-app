//
//  SwiftUITreeView.swift
//  audition
//
//  Created by Jake Medina on 2/7/25.
//

import SwiftUI
import PencilKit

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

struct BranchMarker: View {
    var value: String
    
    var body: some View {
        Text(value)
            .lineLimit(1)
            .truncationMode(.middle)
            .padding(.horizontal, 4.0)
            .background {
                Capsule()
                    .fill(.blue)
                    .stroke(.blue, lineWidth: 2)
                    .opacity(0.15)
            }
            .foregroundStyle(.blue)
            .background{
                Capsule()
                    .fill(.ultraThinMaterial)
            }
            .frame(maxWidth: .infinity)
    }
}

struct BranchMarkers: View {
    static let MAX_MARKERS_DISPLAYED = 3
    
    var branchNames: [String]
    
    @State var firstNames: [String]
    @State var lastNames: [String]
    
    @State var expanded: Bool = false
    
    // could be shortened to `branchNames.count - BranchMarkers.MAX_MARKERS_DISPLAYED`
    // to avoid having to count two arrays
    var expandable: Bool { branchNames.count - namesToDisplay.count > 0 }
    
    init(branchNames: [String]) {
        self.branchNames = branchNames
        
        firstNames = Array(branchNames.prefix(BranchMarkers.MAX_MARKERS_DISPLAYED))
        lastNames = Array(branchNames.dropFirst(BranchMarkers.MAX_MARKERS_DISPLAYED))
    }
    
    var namesToDisplay: [String] {
        return expanded ? branchNames : Array(branchNames.prefix(BranchMarkers.MAX_MARKERS_DISPLAYED))
    }

    // TODO: add a mask on the top side that looks aesthetically pleasing
    // this may require shifting the ScrollView up manually using a GeometryReader
    // the scrollview may need to overlap with the node,
    // and then there will need to be top padding added to the VStack
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 3.0) {
                ForEach(namesToDisplay, id: \.self) { value in
                    BranchMarker(value: value)
                }
                if !expanded && expandable {
                    // could be shortened to `max(0, branchNames.count - BranchMarkers.MAX_MARKERS_DISPLAYED)`
                    // to avoid having to count two arrays
                    BranchMarker(value: "+\(branchNames.count - namesToDisplay.count)")
                }
            }
            .padding(.bottom, expanded ? nil : 0)
            .onTapGesture {
                expanded = expandable && !expanded
                print("branch markers tapped!!!!")
            }
        }
        .mask(LinearGradient(gradient: Gradient(stops: [
            .init(color: .black, location: 0),
            .init(color: .black, location: 0.8),
            .init(color: expanded ? .clear : .black, location: 1)
        ]), startPoint: .top, endPoint: .bottom))
        .frame(height: 100)
    }
}

struct Node<A: CustomStringConvertible>: View {
    @EnvironmentObject var dataModel: AuditionDataModel
    @ObservedObject var x: DisplayTree<A>
    
    @State var img: UIImage = UIImage(ciImage: .empty())
    
    var body: some View {
        return ZStack {
            // NOTE: Using conditionals here to display a different
            // View if the image was nil causes the view to break for some reason.
            // Symptoms can be seen when tapping the node very fast when the TreeView
            // is first displayed. DrawTree has an onTapGesture that captures which Node
            // was pressed. If conditionals are used, DrawTree will sometimes behave
            // like a DIFFERENT Node was pressed. As of right now, I've only observed
            // this behavior on the root node of the tree structure.
            // It could be because of SwiftUI Identity, Lifetime, or Dependencies.
            // I tried watching "Demystify SwiftUI" from 2021 which covers some things,
            // but I wasn't able to determine the cause of the issue.
            // The current fix is to always make an image available so that we don't
            // need to use a separate view to render something other than an Image.
            Image(uiImage: img)
                    .resizable()
                    .antialiased(true)
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipShape(Circle())
                    .background(in: Circle())
                    .overlay {
                        Circle()
                            .stroke(x.isHEAD ? Color.orange : Color.primary, lineWidth: 2)
                    }
            Text(x.commit.sha256DigestValue!.prefix(7))
        }.onAppear{
            // if I am the root node
            if self.x.parent == nil {
                print("laying out initial tree...")
                self.x.relayout()
            }
            img = dataModel.getThumbnail(commit: x.commit) ?? img
        }
    }
}


struct Point: Hashable {
    var x: Int
    var y: Int
    
    static let zero = Point(x: 0, y: 0)
}


final class DisplayTree<A>: ObservableObject, Identifiable, CustomStringConvertible {
    init(commit: Commit, value: A, point: Point = .zero, children: [DisplayTree<A>]? = nil, branches: [String]?, isHEAD: Bool) {
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
    @Published private(set) var children: [DisplayTree<A>]?
    let branches: [String]
    @Published var isHEAD: Bool
    
    weak var parent: DisplayTree<A>? = nil
    
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

struct ChooseBranchView: View {
    @Environment(\.dismiss) private var dismiss

    @State var title: String = ""

    var body: some View {
        VStack(spacing: 10) {
            Text("Choose a branch")
                .font(.title)

            HStack {
                Button("Cancel") {
                    // Cancel saving and dismiss.
                    dismiss()
                }
                Spacer()
                Button("Confirm") {
                    // Save the article and dismiss.
                    dismiss()
                }
            }
        }
            .padding(20)
            .frame(width: 300, height: 200)
    }
}


enum BranchSheet: String, Identifiable, SheetEnum {
    case chooseBranch

    var id: String { rawValue }

    @ViewBuilder
    func view(coordinator: SheetCoordinator<BranchSheet>) -> some View {
        switch self {
        case .chooseBranch:
            ChooseBranchView()
        }
    }
}


struct DrawTree<A, Node>: View where Node: View {
    @EnvironmentObject var dataModel: AuditionDataModel
    @ObservedObject var tree: DisplayTree<A>
    @StateObject var sheetCoordinator = SheetCoordinator<BranchSheet>()
    
    @Binding var rendition: PKDrawing
    @Binding var updatesCounter: Int
    
    @Environment(\.dismiss) var dismiss
    
    var horizontalSpacing: CGFloat = 120
    var verticalSpacing: CGFloat = 120
    let node: (DisplayTree<A>) -> Node
    let nodeSize = CGSize(width: 100, height: 100)
    
    func cgPoint(for point: Point) -> CGPoint {
        CGPoint(x: CGFloat(point.x) * (nodeSize.width + horizontalSpacing), y: CGFloat(point.y) * (nodeSize.height + verticalSpacing))
    }
    
    func setDrawingData(commit: Commit) {
        // grab the blob that was included in the commit
        // we're assuming there will only be one, this will NOT BE TRUE in the future
        // once we are committing individual strokes instead of the entire drawing
        do {
            let aBlob = try dataModel.showBlobs(commit: commit.sha256DigestValue!)[0]
            let newDrawing = try aBlob.createDrawing()
            rendition = newDrawing
            updatesCounter += 1
            print("setDrawingData succeeded")
        } catch let error {
            print("setDrawingData FAILED to get blobs: \(error)")
        }
    }
    
    var body: some View {
        return ZStack(alignment: .topLeading) {
            ForEach(tree.allSubtrees) { (tree: DisplayTree<A>) in
                VStack {
                    self.node(tree)
                        .frame(width: self.nodeSize.width, height: self.nodeSize.height)
                        .onTapGesture {
                            do {
                                print("node tapped: \(tree.commit.sha256DigestValue!)")
                                // TODO: checkout the branch if it's pointed to
                                // if there are multiple branches, present a sheet to
                                // choose which branch to check out
                                sheetCoordinator.presentSheet(.chooseBranch)
//                                try dataModel.checkout(commit: tree.commit.sha256DigestValue!)
//                                setDrawingData(commit: tree.commit)
//                                dismiss()
                            } catch let error {
                                print("ERROR in SwiftUITreeView: Checking out ref failed: \(error)")
                            }
                        }
                        .sheetCoordinating(coordinator: sheetCoordinator)
                    BranchMarkers(branchNames: tree.branches)
                        .frame(maxWidth: nodeSize.width)
                }
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

struct SwiftUITreeView: View {
    var edgeFade = Gradient(stops:
                            [Gradient.Stop(color: Color.clear, location: 0.0),
                             Gradient.Stop(color: Color.black, location: 0.05),
                             Gradient.Stop(color: Color.black, location: 0.95),
                             Gradient.Stop(color: Color.clear, location: 1.0)])
    
    @EnvironmentObject var model: AuditionDataModel
    @State var tree: DisplayTree<String>?
    
    @Binding var rendition: PKDrawing
    @Binding var updatesCounter: Int
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            if let tree {
                DrawTree(tree: tree, rendition: $rendition, updatesCounter: $updatesCounter, node: { Node(x: $0) })
                    .animation(.default)
            } else {
                ContentUnavailableView("No Tree Available", image: "")
                    .onAppear {
                        tree = model.getRootsAsTrees().first
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

func generateSampleDataThreeStaticCommits() -> AuditionDataModel {
    let c1 = Commit(tree: "", parents: [], message: "", timestamp: .init(timeIntervalSince1970: 0))
    let c2 = Commit(tree: "", parents: [c1.sha256DigestValue!], message: "", timestamp: .init(timeIntervalSince1970: 1))
    let c3 = Commit(tree: "", parents: [c1.sha256DigestValue!], message: "", timestamp: .init(timeIntervalSince1970: 2))
    
    let a1 = AuditionDataModel()
    a1.unsafeSetObject(key: c1.sha256DigestValue!, value: c1)
    a1.unsafeSetObject(key: c2.sha256DigestValue!, value: c2)
    a1.unsafeSetObject(key: c3.sha256DigestValue!, value: c3)
    
    a1.unsafeSetBranch(branchName: "main", commitHash: c2.sha256DigestValue!)
    a1.unsafeSetBranch(branchName: "branch1", commitHash: c3.sha256DigestValue!)
    a1.unsafeSetBranch(branchName: "branch2", commitHash: c3.sha256DigestValue!)
    a1.unsafeSetBranch(branchName: "branch4", commitHash: c3.sha256DigestValue!)
    a1.unsafeSetBranch(branchName: "branch5", commitHash: c3.sha256DigestValue!)
    
    return a1
}

#Preview {
//    SwiftUITreeView(model: generateSampleData())
    var model: AuditionDataModel = generateSampleDataThreeStaticCommits()
    SwiftUITreeView(rendition: Binding.constant(PKDrawing()), updatesCounter: Binding.constant(0)).environmentObject(model)
}
