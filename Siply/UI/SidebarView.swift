import SwiftUI

/// Дерево папок. Только папки, корень раскрыт при старте.
struct SidebarView: View {
    let root: FolderNode
    @Binding var selection: FolderNode?
    @State private var rootExpanded = true

    var body: some View {
        List(selection: $selection) {
            DisclosureGroup(isExpanded: $rootExpanded) {
                OutlineGroup(root.children ?? [], children: \.children) { node in
                    row(node)
                }
            } label: {
                row(root)
            }
        }
        .listStyle(.sidebar)
        .navigationSplitViewColumnWidth(min: 180, ideal: 240)
    }

    private func row(_ node: FolderNode) -> some View {
        Label(node.name, systemImage: "folder")
            .tag(node)
    }
}
