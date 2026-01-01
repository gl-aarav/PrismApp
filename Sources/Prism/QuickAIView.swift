import SwiftUI

struct QuickAIView: View {
    @StateObject private var chatManager = ChatManager(fileName: "quick_ai_history.json")
    @State private var inputText: String = ""
    @State private var isLoading: Bool = false
    @State private var selectedProvider: String = "Gemini API"
    @FocusState private var isFocused: Bool

    // Settings
    @AppStorage("GeminiKey") private var geminiKey: String = ""
    @AppStorage("GeminiModel") private var geminiModel: String = "gemini-1.5-flash"
    @AppStorage("OllamaURL") private var ollamaURL: String = "http://localhost:11434"
    @AppStorage("OllamaModel") private var ollamaModel: String = "gpt-oss:120b-cloud"
    @AppStorage("SystemPrompt") private var systemPrompt: String = ""
    @AppStorage("ShortcutPrivateCloud") private var shortcutPrivateCloud: String = "Ask AI Private"
    @AppStorage("ShortcutOnDevice") private var shortcutOnDevice: String = "Ask AI Device"
    @AppStorage("ShortcutChatGPT") private var shortcutChatGPT: String = "Ask ChatGPT"

    private let geminiService = GeminiService()
    private let ollamaService = OllamaService()
    private let shortcutService = ShortcutService()

    var body: some View {
        VStack(spacing: 0) {
            // Header / Drag Area
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple], startPoint: .topLeading,
                            endPoint: .bottomTrailing))
                Text("Quick AI")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)

                Spacer()

                Picker("", selection: $selectedProvider) {
                    Text("Gemini").tag("Gemini API")
                    Text("Ollama").tag("Ollama")
                    Text("Private").tag("Private Cloud")
                    Text("Device").tag("On-Device")
                    Text("ChatGPT").tag("ChatGPT")
                }
                .labelsHidden()
                .frame(width: 100)
                .controlSize(.small)

                Button(action: {
                    chatManager.deleteAllSessions()
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Clear Chat")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)

            Divider()

            // Messages Area
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        if chatManager.getCurrentMessages().isEmpty {
                            VStack(spacing: 12) {
                                Spacer()
                                Image(systemName: "command")
                                    .font(.system(size: 40))
                                    .foregroundStyle(.tertiary)
                                Text("How can I help you today?")
                                    .font(.title3)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }
                            .frame(maxWidth: .infinity, minHeight: 200)
                        } else {
                            ForEach(chatManager.getCurrentMessages()) { message in
                                QuickAIMessageView(message: message)
                            }
                        }

                        if isLoading {
                            HStack {
                                TypingIndicator()
                                Spacer()
                            }
                            .padding(.horizontal)
                            .id("loading")
                        }
                    }
                    .padding(16)
                }
                .onChange(of: chatManager.getCurrentMessages().count) { _, _ in
                    if let lastId = chatManager.getCurrentMessages().last?.id {
                        withAnimation {
                            proxy.scrollTo(lastId, anchor: .bottom)
                        }
                    }
                }
                .onChange(of: isLoading) { _, loading in
                    if loading {
                        withAnimation {
                            proxy.scrollTo("loading", anchor: .bottom)
                        }
                    }
                }
            }

            Divider()

            // Input Area
            HStack(alignment: .bottom, spacing: 12) {
                TextField("Ask anything...", text: $inputText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
                    .lineLimit(1...8)
                    .focused($isFocused)
                    .onSubmit {
                        sendMessage()
                    }
                    .onAppear {
                        isFocused = true
                    }

                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 24))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(
                            inputText.isEmpty ? Color.gray.gradient : Color.blue.gradient)
                }
                .buttonStyle(.plain)
                .disabled(inputText.isEmpty || isLoading)
            }
            .padding(16)
            .background(.ultraThinMaterial)
        }
        .background(VisualEffectView(material: .hudWindow, blendingMode: .behindWindow))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }

    func sendMessage() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let content = inputText
        inputText = ""

        let userMsg = Message(content: content, image: nil, isUser: true)
        chatManager.addMessage(userMsg)
        isLoading = true

        Task {
            if selectedProvider == "Gemini API" {
                if !geminiKey.isEmpty {
                    let aiMsgId = UUID()
                    var aiMsg = Message(content: "", isUser: false)
                    aiMsg.id = aiMsgId

                    DispatchQueue.main.async {
                        self.chatManager.addMessage(aiMsg)
                    }

                    do {
                        var fullContent = ""
                        for try await chunk in geminiService.sendMessageStream(
                            history: chatManager.getCurrentMessages(), apiKey: geminiKey,
                            model: geminiModel, systemPrompt: systemPrompt)
                        {
                            fullContent += chunk
                            let contentToUpdate = fullContent
                            DispatchQueue.main.async {
                                self.chatManager.updateMessage(
                                    id: aiMsgId, content: contentToUpdate)
                            }
                        }
                        DispatchQueue.main.async {
                            self.chatManager.finalizeMessageUpdate()
                            self.isLoading = false
                        }
                    } catch {
                        DispatchQueue.main.async {
                            self.chatManager.updateMessage(
                                id: aiMsgId, content: "Error: \(error.localizedDescription)")
                            self.chatManager.finalizeMessageUpdate()
                            self.isLoading = false
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        let aiMsg = Message(
                            content: "Please set your API Key in the main app settings.",
                            isUser: false)
                        self.chatManager.addMessage(aiMsg)
                        self.isLoading = false
                    }
                }
            } else if selectedProvider == "Ollama" {
                let aiMsgId = UUID()
                var aiMsg = Message(content: "", isUser: false)
                aiMsg.id = aiMsgId

                DispatchQueue.main.async {
                    self.chatManager.addMessage(aiMsg)
                }

                do {
                    var fullContent = ""
                    var fullThinking = ""

                    for try await (contentChunk, thinkingChunk) in ollamaService.sendMessageStream(
                        history: chatManager.getCurrentMessages(), endpoint: ollamaURL,
                        model: ollamaModel, systemPrompt: systemPrompt)
                    {
                        fullContent += contentChunk
                        if let thinking = thinkingChunk {
                            fullThinking += thinking
                        }

                        let contentToUpdate = fullContent
                        let thinkingToUpdate = fullThinking.isEmpty ? nil : fullThinking

                        DispatchQueue.main.async {
                            self.chatManager.updateMessage(
                                id: aiMsgId, content: contentToUpdate,
                                thinkingContent: thinkingToUpdate)
                        }
                    }
                    DispatchQueue.main.async {
                        self.chatManager.finalizeMessageUpdate()
                        self.isLoading = false
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.chatManager.updateMessage(
                            id: aiMsgId, content: "Error: \(error.localizedDescription)")
                        self.chatManager.finalizeMessageUpdate()
                        self.isLoading = false
                    }
                }
            } else {
                // Shortcuts
                let shortcutName: String
                switch selectedProvider {
                case "Private Cloud": shortcutName = shortcutPrivateCloud
                case "On-Device": shortcutName = shortcutOnDevice
                case "ChatGPT": shortcutName = shortcutChatGPT
                default: shortcutName = shortcutPrivateCloud
                }

                // Build transcript
                var transcript = "Please reply to the last message:\n\n"
                for msg in chatManager.getCurrentMessages().suffix(5) {
                    let role = msg.isUser ? "User" : "Assistant"
                    transcript += "\(role): \(msg.content)\n"
                }
                transcript += "Assistant:"

                do {
                    let result = try await shortcutService.runShortcut(
                        name: shortcutName, input: transcript, image: nil)
                    DispatchQueue.main.async {
                        let aiMsg = Message(content: result.0, image: nil, isUser: false)
                        self.chatManager.addMessage(aiMsg)
                        self.isLoading = false
                    }
                } catch {
                    DispatchQueue.main.async {
                        let aiMsg = Message(
                            content: "Error: \(error.localizedDescription)", isUser: false)
                        self.chatManager.addMessage(aiMsg)
                        self.isLoading = false
                    }
                }
            }
        }
    }
}

struct QuickAIMessageView: View {
    let message: Message

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if message.isUser {
                Spacer()
                Text(message.content)
                    .font(.system(size: 14))
                    .padding(12)
                    .background(Color.blue.opacity(0.8))
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                Image(systemName: "sparkles")
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple], startPoint: .topLeading,
                            endPoint: .bottomTrailing)
                    )
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(.ultraThinMaterial))

                VStack(alignment: .leading, spacing: 8) {
                    if let thinking = message.thinkingContent {
                        Text(thinking)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .padding(8)
                            .background(Color.gray.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    MarkdownView(blocks: message.blocks)
                }
                .padding(12)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Spacer()
            }
        }
    }
}

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let visualEffectView = NSVisualEffectView()
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
        visualEffectView.state = .active
        return visualEffectView
    }

    func updateNSView(_ visualEffectView: NSVisualEffectView, context: Context) {
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
    }
}
