import Foundation

/// Google Gemini client using the Interactions API (`POST {base}/interactions`), stateless (`store: false`).
///
/// - Persona, rules, and compact health context go in `system_instruction`.
/// - History is sent as steps: `user_input` for the user, `model_output` for prior assistant replies.
/// - Body Map updates come back as `function_call` steps and are mapped to `ChatLLMToolCall`.
/// - Single round trip: the app applies tool calls itself and does not send `function_result` back.
/// - `generateContent` is not used: it returned empty 404s for this project's API key.
struct GeminiChatClient: ChatLLMProviding {
    var apiKey: String
    var baseURL: URL
    var model: String
    /// `low` keeps chat responsive; Gemini 3.x thinks at a higher level by default (~30 s replies).
    var thinkingLevel: String = "low"
    var session: URLSession = .shared

    private static let requestTimeout: TimeInterval = 90
    /// Retries for temporary Gemini errors ("high demand" 503, 429, 500).
    private static let maxRetries = 2
    private static let retryableStatuses: Set<Int> = [429, 500, 503]
    /// Used when history starts with the app's assistant check-in, so the first step is user input.
    private static let sessionStartMarker = "[Chat session started by the app's wellness check-in.]"

    func complete(
        systemInstructions: [String],
        messages: [ChatLLMMessage],
        tools: [ChatLLMTool],
        temperature: Double?
    ) async throws -> ChatLLMCompletion {
        let request = try makeRequest(
            systemInstructions: systemInstructions,
            messages: messages,
            tools: tools,
            temperature: temperature
        )

        var attempt = 0
        while true {
            let data: Data
            let response: URLResponse
            do {
                (data, response) = try await session.data(for: request)
            } catch {
                throw ChatLLMError.fromTransport(error)
            }
            guard let http = response as? HTTPURLResponse else {
                throw ChatLLMError.invalidResponse
            }
            if (200..<300).contains(http.statusCode) {
                return try Self.decodeCompletion(from: data)
            }
            if Self.retryableStatuses.contains(http.statusCode), attempt < Self.maxRetries {
                attempt += 1
                // 1.5 s, then 3 s.
                try await Task.sleep(nanoseconds: UInt64(attempt) * 1_500_000_000)
                continue
            }
            throw ChatLLMError.http(status: http.statusCode, message: Self.errorMessage(from: data))
        }
    }

    // MARK: - Request

    func makeRequest(
        systemInstructions: [String],
        messages: [ChatLLMMessage],
        tools: [ChatLLMTool],
        temperature: Double?
    ) throws -> URLRequest {
        let base = baseURL.absoluteString.hasSuffix("/")
            ? String(baseURL.absoluteString.dropLast())
            : baseURL.absoluteString
        guard !model.isEmpty, let url = URL(string: "\(base)/interactions") else {
            throw ChatLLMError.invalidRequest
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = Self.requestTimeout
        request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var body: [String: Any] = [
            "model": model,
            "store": false,
            "input": Self.steps(from: messages),
        ]

        let system = systemInstructions
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n\n")
        if !system.isEmpty {
            body["system_instruction"] = system
        }

        let functions: [[String: Any]] = tools.compactMap { tool in
            guard let parameters = tool.parametersObject else { return nil }
            return [
                "type": "function",
                "name": tool.name,
                "description": tool.description,
                "parameters": parameters,
            ]
        }
        if !functions.isEmpty {
            body["tools"] = functions
        }

        var generationConfig: [String: Any] = ["thinking_level": thinkingLevel]
        if let temperature {
            generationConfig["temperature"] = temperature
        }
        body["generation_config"] = generationConfig

        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }

    /// Maps turns to Interactions steps, merges consecutive same-role turns,
    /// and guarantees the first step is user input.
    static func steps(from messages: [ChatLLMMessage]) -> [[String: Any]] {
        var merged: [(role: ChatLLMMessage.Role, text: String)] = []
        for message in messages {
            let text = message.content.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { continue }
            if let last = merged.last, last.role == message.role {
                merged[merged.count - 1].text = last.text + "\n\n" + text
            } else {
                merged.append((message.role, text))
            }
        }
        if merged.first?.role == .assistant {
            merged.insert((.user, sessionStartMarker), at: 0)
        }
        return merged.map { turn in
            switch turn.role {
            case .user:
                return ["type": "user_input", "content": turn.text]
            case .assistant:
                return ["type": "model_output", "content": [["type": "text", "text": turn.text]]]
            }
        }
    }

    // MARK: - Response

    static func decodeCompletion(from data: Data) throws -> ChatLLMCompletion {
        guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ChatLLMError.invalidResponse
        }
        if let status = root["status"] as? String, status == "failed" || status == "cancelled" {
            throw ChatLLMError.blocked(reason: status)
        }

        let steps = root["steps"] as? [[String: Any]] ?? []
        var texts: [String] = []
        var toolCalls: [ChatLLMToolCall] = []

        for (index, step) in steps.enumerated() {
            switch step["type"] as? String {
            case "model_output":
                let content = step["content"] as? [[String: Any]] ?? []
                for item in content where (item["type"] as? String) == "text" {
                    if let text = item["text"] as? String { texts.append(text) }
                }
            case "function_call":
                guard let name = step["name"] as? String else { continue }
                let args = step["arguments"] as? [String: Any] ?? [:]
                let argsData = (try? JSONSerialization.data(withJSONObject: args)) ?? Data("{}".utf8)
                toolCalls.append(
                    ChatLLMToolCall(
                        id: step["id"] as? String ?? "call_\(index)",
                        name: name,
                        argumentsJSON: String(data: argsData, encoding: .utf8) ?? "{}"
                    )
                )
            default:
                // "thought" and other internal steps are not shown to the user.
                continue
            }
        }

        let content = texts.joined().trimmingCharacters(in: .whitespacesAndNewlines)
        if content.isEmpty, toolCalls.isEmpty {
            throw ChatLLMError.invalidResponse
        }
        return ChatLLMCompletion(content: content, toolCalls: toolCalls)
    }

    /// Pulls `error.message` from a Gemini error body, truncated for display.
    private static func errorMessage(from data: Data) -> String? {
        guard
            let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let error = root["error"] as? [String: Any],
            let message = error["message"] as? String
        else { return nil }
        return String(message.prefix(200))
    }
}
