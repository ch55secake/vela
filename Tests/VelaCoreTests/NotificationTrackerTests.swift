import Foundation
import XCTest
@testable import VelaCore

final class NotificationTrackerTests: XCTestCase {
    func testFirstResponseEstablishesBaselineWithoutAlerting() throws {
        var tracker = NotificationTracker()
        let existing = try notification(id: "1", updatedAt: "2026-11-24T10:00:00Z")

        XCTAssertTrue(tracker.update(with: [existing]).isEmpty)
        XCTAssertEqual(tracker.knownUpdates["1"], existing.updatedAt)
    }

    func testNewAndUpdatedUnreadNotificationsAreReportedOnlyOnce() throws {
        let original = try notification(id: "1", updatedAt: "2026-11-24T10:00:00Z")
        let newThread = try notification(id: "2", updatedAt: "2026-11-24T10:01:00Z")
        var tracker = NotificationTracker(knownUpdates: ["1": original.updatedAt])

        XCTAssertEqual(tracker.update(with: [original, newThread]).map(\.id), ["2"])
        XCTAssertTrue(tracker.update(with: [original, newThread]).isEmpty)

        let updatedThread = try notification(
            id: "2",
            updatedAt: "2026-11-24T10:02:00Z"
        )
        XCTAssertEqual(tracker.update(with: [original, updatedThread]).map(\.id), ["2"])
    }

    func testReadNotificationsDoNotTriggerAlerts() throws {
        let read = try notification(
            id: "1",
            updatedAt: "2026-11-24T10:00:00Z",
            unread: false
        )
        var tracker = NotificationTracker(knownUpdates: [:])

        XCTAssertTrue(tracker.update(with: [read]).isEmpty)
    }

    private func notification(
        id: String,
        updatedAt: String,
        unread: Bool = true
    ) throws -> GitHubNotification {
        let object: [String: Any] = [
            "id": id,
            "unread": unread,
            "updated_at": updatedAt,
            "reason": "review_requested",
            "subject": [
                "title": "Review this change",
                "type": "PullRequest",
                "url": "https://api.github.com/repos/octo/project/pulls/42",
            ],
            "repository": [
                "full_name": "octo/project",
                "html_url": "https://github.com/octo/project",
            ],
        ]
        let data = try JSONSerialization.data(withJSONObject: object)
        return try JSONDecoder().decode(GitHubNotification.self, from: data)
    }
}
