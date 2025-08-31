import SwiftUI
import AppKit

class DebugLogger: ObservableObject {
    @Published var logs: [String] = []
    static let shared = DebugLogger()
    
    private init() {}
    
    func log(_ message: String) {
        DispatchQueue.main.async {
            let timestamp = DateFormatter().string(from: Date())
            self.logs.append("[\(timestamp)] \(message)")
            // 只保留最近100条日志
            if self.logs.count > 100 {
                self.logs.removeFirst()
            }
        }
    }
    
    func clear() {
        DispatchQueue.main.async {
            self.logs.removeAll()
        }
    }
    
    func copyAllLogs() -> String {
        return logs.joined(separator: "\n")
    }
}

struct DebugConsoleView: View {
    @StateObject private var logger = DebugLogger.shared
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerView
            
            if isExpanded {
                logContentView
            }
        }
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
    
    private var headerView: some View {
        HStack {
            HStack {
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                Text("调试日志 (\(logger.logs.count))")
                Spacer()
                if !logger.logs.isEmpty {
                    copyButton
                    clearButton
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation {
                    isExpanded.toggle()
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.1))
    }
    
    private var copyButton: some View {
        Button("复制") {
            let allLogs = logger.copyAllLogs()
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(allLogs, forType: .string)
        }
        .buttonStyle(BorderlessButtonStyle())
    }
    
    private var clearButton: some View {
        Button("清空") {
            logger.clear()
        }
        .buttonStyle(BorderlessButtonStyle())
    }
    
    private var logContentView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 1) {
                    ForEach(Array(logger.logs.enumerated()), id: \.offset) { index, log in
                        logRowView(log: log, index: index)
                    }
                }
                .padding(.vertical, 4)
            }
            .frame(minHeight: 100, maxHeight: 300)
            .background(Color.black.opacity(0.02))
            .border(Color.gray.opacity(0.3), width: 1)
            .onChange(of: logger.logs.count) { _ in
                if !logger.logs.isEmpty {
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo(logger.logs.count - 1, anchor: .bottom)
                    }
                }
            }
        }
    }
    
    private func logRowView(log: String, index: Int) -> some View {
        Text(log)
            .font(.system(.caption, design: .monospaced))
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(index % 2 == 0 ? Color.clear : Color.gray.opacity(0.05))
            .id(index)
    }
}