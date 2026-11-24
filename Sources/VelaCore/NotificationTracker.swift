public struct NotificationTracker: Sendable {
    public private(set) var knownUpdates: [String: String]
    private var hasBaseline: Bool

    public init(knownUpdates: [String: String]? = nil) {
        self.knownUpdates = knownUpdates ?? [:]
        hasBaseline = knownUpdates != nil
    }

    public mutating func update(
        with notifications: [GitHubNotification],
        notifyChanges: Bool = true
    ) -> [GitHubNotification] {
        let currentUpdates = Dictionary(
            notifications.map { ($0.id, $0.updatedAt) },
            uniquingKeysWith: { first, _ in first }
        )

        let changedNotifications: [GitHubNotification]
        if hasBaseline && notifyChanges {
            changedNotifications = notifications.filter {
                $0.unread && knownUpdates[$0.id] != $0.updatedAt
            }
        } else {
            changedNotifications = []
        }

        knownUpdates = currentUpdates
        hasBaseline = true
        return changedNotifications
    }
}
