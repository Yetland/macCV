import SwiftUI

struct PreviewPanel: View {
    let item: HistoryItem
    let onClose: () -> Void
    let onCopy: () -> Void
    let onDelete: () -> Void

    @State private var justCopied = false

    var body: some View {
        VStack(spacing: 0) {
            // Top area — fixed height to match HistoryListView search+filter
            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    Button(action: onClose) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .buttonStyle(.plain)
                    .help("Back")

                    Text("Preview")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)

                    Spacer()

                    Button {
                        onCopy()
                        justCopied = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                            justCopied = false
                        }
                    } label: {
                        Image(systemName: justCopied ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 13))
                            .foregroundColor(justCopied ? .green : .primary)
                    }
                    .buttonStyle(.plain)
                    .help("Copy")

                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 13))
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.red)
                    .help("Delete")
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
            }
            .frame(height: 64)
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            // Content
            ScrollView {
                if item.type == .text, let text = item.content {
                    Text(text)
                        .font(.system(size: 13))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                } else if item.type == .image, let path = item.imagePath {
                    if let image = ImageCache.shared.image(for: path) {
                        let img = Image(nsImage: image)
                        img
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: 400, maxHeight: 400)
                            .padding(12)
                    } else {
                        ContentUnavailableView(
                            "Image not found",
                            systemImage: "photo.badge.exclamationmark",
                            description: Text("The image file may have been deleted.")
                        )
                        .padding()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
