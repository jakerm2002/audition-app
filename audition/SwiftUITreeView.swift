//
//  SwiftUITreeView.swift
//  audition
//
//  Created by Jake Medina on 2/7/25.
//

import SwiftUI
import PencilKit

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
        // TODO: in the future, make the height adapt to the available vertical space between the nodes, which is defined by TreeContentView's verticalSpacing property. If the height cannot fit the maximum number of markers displayed in non-expanded mode, dynamically reduce the number of markers displayed until it fits.
        .frame(height: 100)
    }
}


struct Node<A: CustomStringConvertible>: View {
    @EnvironmentObject var dataModel: AuditionDataModel
    @ObservedObject var x: NodeData<A>
    
    @State var img: UIImage = UIImage(ciImage: .empty())
    
    var body: some View {
        return ZStack {
            // NOTE: Using conditionals here to display a different
            // View if the image was nil causes the view to break for some reason.
            // Symptoms can be seen when tapping the node very fast when the TreeView
            // is first displayed. TreeContentView has an onTapGesture that captures which Node
            // was pressed. If conditionals are used, TreeContentView will sometimes behave
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


struct BranchDetailView<A>: View {
    @Environment(\.dismiss) private var dismiss
    
    var node: NodeData<A>
    var setDrawing: (_ tree: NodeData<A>, _ branch: String) -> Void
    
    @State var selectedBranch: String?
    
    var body: some View {
        NavigationStack {
            List(node.branches, id: \.self, selection: $selectedBranch) { branch in
                Text(branch)
            }
            .navigationTitle("Choose branch")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onChange(of: selectedBranch) { old, new in
                if let new {
                    print("branch selected: \(new)")
                    dismiss()
                    setDrawing(node, new)
                }
            }
        }
    }
}


struct TreeContentView<A, Node>: View where Node: View {
    @EnvironmentObject var dataModel: AuditionDataModel
    @ObservedObject var tree: NodeData<A>
    @State private var selected: NodeData<A>?
    
    @Binding var rendition: PKDrawing
    @Binding var updatesCounter: Int
    
    @Environment(\.dismiss) var dismiss
    
    var horizontalSpacing: CGFloat = 120
    var verticalSpacing: CGFloat = 120
    let node: (NodeData<A>) -> Node
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
    
    func setDrawingFromBranch(tree: NodeData<A>, branch: String) {
        do {
            try dataModel.checkout(branch: branch)
            setDrawingData(commit: tree.commit)
            dismiss()
        } catch let error {
            print("ERROR in SwiftUITreeView: Checking out branch failed: \(error)")
        }
    }
    
    var body: some View {
        return ZStack(alignment: .topLeading) {
            // currently, nodes are layered on top of one another
            // in the order returned from tree.allSubtrees.
            // this ordering could be reversed if needed by enumerating the results
            // by index and then setting the .zIndex modifier to -index.
            ForEach(tree.allSubtrees) { (tree: NodeData<A>) in
                VStack {
                    self.node(tree)
                        .frame(width: self.nodeSize.width, height: self.nodeSize.height)
                        .onTapGesture {
                            do {
                                print("node tapped: \(tree.commit.sha256DigestValue!)")
                                // checkout the branch if it's pointed to
                                // if there are multiple branches, present a sheet to
                                // choose which branch to check out
                                // TODO: in the future, regarding commits pointed to by branches, consider giving the user the option to long-press these nodes to checkout the COMMIT and bypass checking out any of the branches.
                                if (tree.branches.count > 1) {
                                    selected = tree
                                } else if let branch = tree.branches.first {
                                    setDrawingFromBranch(tree: tree, branch: branch)
                                } else {
                                    try dataModel.checkout(commit: tree.commit.sha256DigestValue!)
                                    setDrawingData(commit: tree.commit)
                                    dismiss()
                                }
                            } catch let error {
                                print("ERROR in SwiftUITreeView: Checking out ref failed: \(error)")
                            }
                        }
                        .sheet(item: $selected, content: { node in
                            BranchDetailView(node: node, setDrawing: setDrawingFromBranch)
                        })
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
    @State var tree: NodeData<String>?
    
    @Binding var rendition: PKDrawing
    @Binding var updatesCounter: Int
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            if let tree {
                TreeContentView(tree: tree, rendition: $rendition, updatesCounter: $updatesCounter, node: { Node(x: $0) })
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


#Preview {
    var model: AuditionDataModel = generateSampleDataThreeStaticCommits()
    SwiftUITreeView(rendition: Binding.constant(PKDrawing()), updatesCounter: Binding.constant(0)).environmentObject(model)
}
