import ActivityKit
import Foundation

/// Starts, updates, and ends the workout Live Activity so the session stays visible on the
/// Lock Screen and Dynamic Island while the app is in the background or closed.
@MainActor
enum WorkoutLiveActivityController {

    private static func activity(for sessionID: UUID) -> Activity<WorkoutActivityAttributes>? {
        Activity<WorkoutActivityAttributes>.activities.first { $0.attributes.sessionID == sessionID }
    }

    static func start(_ session: HubSession) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled, activity(for: session.id) == nil else {
            update(session)
            return
        }
        let attributes = WorkoutActivityAttributes(
            sessionID: session.id,
            title: session.title,
            symbol: session.kind.symbol
        )
        let content = ActivityContent(state: state(for: session), staleDate: nil)
        _ = try? Activity.request(attributes: attributes, content: content, pushType: nil)
    }

    static func update(_ session: HubSession) {
        guard let activity = activity(for: session.id) else { return }
        let content = ActivityContent(state: state(for: session), staleDate: nil)
        Task { await activity.update(content) }
    }

    static func end(sessionID: UUID) {
        guard let activity = activity(for: sessionID) else { return }
        Task { await activity.end(nil, dismissalPolicy: .immediate) }
    }

    /// On launch: keep exactly one activity for the in-progress session (restarts it if the
    /// system removed it) and end any left over from finished or deleted sessions.
    static func reconcile(activeSession: HubSession?) {
        for activity in Activity<WorkoutActivityAttributes>.activities
        where activity.attributes.sessionID != activeSession?.id {
            Task { await activity.end(nil, dismissalPolicy: .immediate) }
        }
        if let activeSession {
            start(activeSession)
        }
    }

    private static func state(for session: HubSession) -> WorkoutActivityAttributes.ContentState {
        WorkoutActivityAttributes.ContentState(startedAt: session.startedAt, detail: detail(for: session))
    }

    static func detail(for session: HubSession) -> String {
        switch session.kind {
        case .lifting:
            let total = session.exercises.flatMap(\.sets).count
            return "\(session.completedSetCount)/\(total) sets · \(HomeFormat.grouped(Int(session.totalVolumeLbs.rounded()))) lbs"
        case .running:
            var text = HubFormat.miles(session.totalMiles)
            if let pace = session.averagePaceSecondsPerMile { text += " · \(HubFormat.pace(pace))" }
            return text
        }
    }
}
