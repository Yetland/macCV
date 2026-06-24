import SwiftUI

struct HistoryListView: View {
    @Bindable var viewModel: AppState
    @State private var selectedItem: HistoryItem?

    var body: some View {
        VStack(spacing: 0) {
            // Top area — fixed height to match PreviewPanel toolbar
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search history...", text: $viewModel.searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                        .onChange(of: viewModel.searchText) { _, _ in
                            viewModel.refresh()
                        }
                    if !viewModel.searchText.isEmpty {
                        Button(action: { viewModel.searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 8)

                // Type filter
                HStack(spacing: 4) {
                    FilterButton(title: "All", isSelected: viewModel.filterType == nil) {
                        viewModel.filterType = nil
                        viewModel.refresh()
                    }
                    FilterButton(title: "Text", isSelected: viewModel.filterType == .text) {
                        viewModel.filterType = .text
                        viewModel.refresh()
                    }
                    FilterButton(title: "Image", isSelected: viewModel.filterType == .image) {
                        viewModel.filterType = .image
                        viewModel.refresh()
                    }
                    Spacer()
                    Text("\(viewModel.items.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.trailing, 4)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
            }
            .frame(height: 64)
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            // History list
            if viewModel.items.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "clipboard")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary.opacity(0.4))
                    Text("No clipboard history yet")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    Text("Copy something to get started")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary.opacity(0.7))
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollViewReader { proxy in
                    List(viewModel.items) { item in
                        HistoryItemRow(item: item)
                            .tag(item.id)
                            .onTapGesture {
                                selectedItem = item
                                viewModel.selectedForPreview = item
                            }
                            .contextMenu {
                                Button("Copy") { copyItem(item) }
                                Button("Delete", role: .destructive) {
                                    if let id = item.id {
                                        viewModel.deleteItem(id)
                                    }
                                }
                            }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
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

struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 3)
                .background(isSelected ? Color.accentColor : Color(nsColor: .separatorColor).opacity(0.2))
                .cornerRadius(4)
        }
        .buttonStyle(.plain)
    }
}
