import SwiftUI

struct HistoryPanel: View {
    @Bindable var viewModel: AppState
    @State private var showClearConfirmation = false

    var body: some View {
        VStack(spacing: 0) {
            if let previewItem = viewModel.selectedForPreview {
                PreviewPanel(
                    item: previewItem,
                    onClose: { viewModel.selectedForPreview = nil },
                    onCopy: {
                        copyItem(previewItem)
                        viewModel.selectedForPreview = nil
                    },
                    onDelete: {
                        if let id = previewItem.id {
                            viewModel.deleteItem(id)
                        }
                        viewModel.selectedForPreview = nil
                    }
                )
            } else {
                HistoryListView(viewModel: viewModel)
            }

            Divider()

            HStack {
                Button {
                    viewModel.showSettings()
                } label: {
                    Label("Settings", systemImage: "gearshape")
                        .font(.system(size: 11))
                }
                .buttonStyle(.plain)

                Spacer()

                Button("Clear All") {
                    showClearConfirmation = true
                }
                .buttonStyle(.plain)
                .font(.system(size: 11))
                .foregroundColor(.red)
                .help("Delete all clipboard history")

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.plain)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(nsColor: .controlBackgroundColor))
        }
        .frame(width: 320, height: 440)
        .background(Color(nsColor: .windowBackgroundColor))
        .confirmationDialog(
            "Clear all clipboard history?",
            isPresented: $showClearConfirmation
        ) {
            Button("Clear All", role: .destructive) {
                viewModel.clearAll()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone. All copied items and images will be permanently deleted.")
        }
    }

    private func copyItem(_ item: HistoryItem) {
        ClipboardMonitor.skipNext = true
        let pb = NSPasteboard.general
        pb.clearContents()
        if item.type == .text, let text = item.content {
            pb.setString(text, forType: .string)
        } else if item.type == .image, let path = item.imagePath {
            let url = Database.shared.imageURL(for: path)
            if let image = NSImage(contentsOf: url) {
                pb.writeObjects([image])
            }
        }
    }
}
