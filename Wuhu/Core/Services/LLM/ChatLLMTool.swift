import Foundation

/// Provider-neutral function declaration. `parametersJSON` is an OpenAPI-style JSON Schema object,
/// stored as a string so the type stays `Sendable`.
struct ChatLLMTool: Sendable, Equatable {
    var name: String
    var description: String
    var parametersJSON: String

    /// Schema decoded for request bodies. Returns `nil` if the stored JSON is invalid.
    var parametersObject: [String: Any]? {
        guard let data = parametersJSON.data(using: .utf8) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
    }
}

extension ChatLLMTool {
    /// Name the orchestrator matches when applying Body Map updates.
    static let updateWearAndTearName = "update_wear_and_tear"

    /// Lets the model record soreness, injuries, or recovery the user describes.
    /// Part ids are constrained to `BodyPart` raw values; the executor still validates everything.
    static let updateWearAndTear: ChatLLMTool = {
        let schema: [String: Any] = [
            "type": "object",
            "properties": [
                "actions": [
                    "type": "array",
                    "description": "One entry per body part the user described.",
                    "items": [
                        "type": "object",
                        "properties": [
                            "part": [
                                "type": "string",
                                "description": "Body part id.",
                                "enum": BodyPart.allCases.map(\.rawValue),
                            ],
                            "status": [
                                "type": "string",
                                "description": "Use injured only when the user explicitly says it is injured or in pain.",
                                "enum": ["healthy", "sore", "injured"],
                            ],
                            "severity": [
                                "type": "integer",
                                "description": "1 (mild) to 5 (severe). Omit for healthy.",
                                "minimum": 1,
                                "maximum": 5,
                            ],
                            "note": [
                                "type": "string",
                                "description": "Short note in the user's own words.",
                            ],
                        ],
                        "required": ["part", "status"],
                    ],
                ],
            ],
            "required": ["actions"],
        ]
        let data = (try? JSONSerialization.data(withJSONObject: schema, options: [.sortedKeys])) ?? Data("{}".utf8)
        return ChatLLMTool(
            name: updateWearAndTearName,
            description: "Update the user's Body Map wear and tear from what they said (soreness, injury, or a part feeling better).",
            parametersJSON: String(data: data, encoding: .utf8) ?? "{}"
        )
    }()
}
