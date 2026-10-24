import SwiftUI
import SwiftData

/// Chat tab (replaces legacy ChatView.swift).
struct ChatScreen: View {
    @Environment(AppEnvironment.self) private var app
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ChatMessage.createdAt) private var messages: [ChatMessage]
    @State private var viewModel = ChatViewModel()

    var body: some View {
        @Bindable var viewModel = viewModel
        NavigationStack {
            VStack(spacing: 0) {
                messageList
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                }
                composer(viewModel: viewModel)
            }
            .navigationTitle("Chat")
        }
    }

    private var messageList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                if messages.isEmpty {
                    Text("Ask about stats, Vitality Age, sleep, or an injured body part. Wellness only — not medical advice.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding()
                }
                ForEach(messages, id: \.id) { message in
                    messageBubble(message)
                }
                if viewModel.isTyping {
                    HStack {
                        ProgressView()
                        Text("Typing...")
                            .font(.caption)
                        Spacer()
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }

    private func composer(viewModel: ChatViewModel) -> some View {
        @Bindable var viewModel = viewModel
        return HStack(spacing: 8) {
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
            .disabled(viewModel.input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isTyping)
        }
        .padding()
    }

    private func messageBubble(_ message: ChatMessage) -> some View {
        HStack {
            if message.role == .user { Spacer(minLength: 40) }
            Text(message.content)
                .padding(12)
                .background(
                    message.role == .user ? Color.accentColor.opacity(0.2) : Color.gray.opacity(0.15),
                    in: RoundedRectangle(cornerRadius: 14)
                )
            if message.role != .user { Spacer(minLength: 40) }
        }
        .padding(.horizontal)
    }
}
