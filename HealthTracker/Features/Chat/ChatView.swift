import SwiftUI
import SwiftData

struct ChatView: View {
    @Environment(AppEnvironment.self) private var app
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ChatMessage.createdAt) private var messages: [ChatMessage]
    @State private var viewModel = ChatViewModel()

    var body: some View {
        @Bindable var viewModel = viewModel
        NavigationStack {
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 10) {
                            if messages.isEmpty {
                                Text("Ask about today's stats, Vitality Age, sleep, or an injured body part. Wellness guidance only - not medical advice.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .padding()
                            }
                            ForEach(messages, id: \.id) { message in
                                bubble(message)
                                    .id(message.id)
                            }
                            if viewModel.isTyping {
                                HStack {
                                    ProgressView()
                                    Text("Typing...")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                }
                                .padding(.horizontal)
                                .accessibilityLabel("Assistant is typing")
                            }
                        }
                        .padding(.vertical)
                    }
                    .onChange(of: messages.count) { _, _ in
                        if let last = messages.last {
                            withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                        }
                    }
                }

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                }

                HStack(spacing: 8) {
                    TextField("Ask a health question", text: $viewModel.input, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(1...4)
                    Button {
                        Task {
                            await viewModel.send(
                                using: app.chatService,
                                snapshot: app.lastSnapshot,
                                scores: app.latestScores,
                                modelContext: modelContext
                            )
                        }
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                    }
                    .disabled(
                        viewModel.input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            || viewModel.isTyping
                    )
                    .accessibilityLabel("Send")
                }
                .padding()
            }
            .navigationTitle("Chat")
        }
    }

    private func bubble(_ message: ChatMessage) -> some View {
        HStack {
            if message.role == .user {
                Spacer(minLength: 40)
            }
            Text(message.content)
                .padding(12)
                .background(
                    message.role == .user ? Color.accentColor.opacity(0.2) : Color.gray.opacity(0.15),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )
            if message.role != .user {
                Spacer(minLength: 40)
            }
        }
        .padding(.horizontal)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message.role == .user ? "You" : "Assistant")
        .accessibilityValue(message.content)
    }
}
