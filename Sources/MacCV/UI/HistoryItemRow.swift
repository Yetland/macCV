import SwiftUI
import AppKit

struct HistoryItemRow: View {
    let item: HistoryItem
    @State private var justCopied = false

    private let dateFormatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f
    }()

    var body: some View {
        HStack(spacing: 10) {
            // Type icon
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(item.type == .text ? Color.blue.opacity(0.12) : Color.green.opacity(0.12))
                    .frame(width: 36, height: 36)

                if item.type == .text {
                    Image(systemName: "doc.text")
                        .font(.system(size: 14))
                        .foregroundColor(.blue)
                } else {
                    if let path = item.imagePath, let thumb = ImageCache.shared.thumbnail(for: path) {
                        Image(nsImage: thumb)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 34, height: 34)
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                    } else {
                        Image(systemName: "photo")
                            .font(.system(size: 14))
                            .foregroundColor(.green)
                    }
                }
            }

            // Content preview
            VStack(alignment: .leading, spacing: 2) {
                if item.type == .text, let text = item.content {
                    Text(text.previewText)
                        .lineLimit(2)
                        .font(.system(size: 13))
                        .foregroundColor(.primary)
                } else {
                    Text("Image")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }

                Text(dateFormatter.localizedString(for: item.createdAt, relativeTo: Date()))
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button {
                copyItem(item)
                justCopied = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    justCopied = false
                }
            } label: {
                Image(systemName: justCopied ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 11))
                    .foregroundColor(justCopied ? .green : .secondary.opacity(0.6))
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Copy")
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .contentShape(Rectangle())
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

extension String {
    var previewText: String {
        let cleaned = trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.count > 120 {
            return String(cleaned.prefix(120)) + "..."
        }
        return cleaned
    }
}
