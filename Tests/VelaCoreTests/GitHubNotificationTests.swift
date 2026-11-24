import Foundation
import XCTest
@testable import VelaCore

final class GitHubNotificationTests: XCTestCase {
    func testDecodesNotificationAndBuildsPullRequestURL() throws {
        let data = Data(
            """
            {
              "id": "12345",
              "unread": true,
              "updated_at": "2026-11-24T10:15:00Z",
              "reason": "review_requested",
              "subject": {
                "title": "Add a new feature",
                "type": "PullRequest",
                "url": "https://api.github.com/repos/octo/project/pulls/42"
              },
              "repository": {
                "full_name": "octo/project",
                "html_url": "https://github.com/octo/project"
              }
            }
            """.utf8
        )

        let notification = try JSONDecoder().decode(
            GitHubNotification.self,
            from: data
        )

        XCTAssertEqual(notification.id, "12345")
        XCTAssertTrue(notification.unread)
        XCTAssertEqual(notification.reasonDescription, "Review requested")
        XCTAssertEqual(
            notification.webURL?.absoluteString,
            "https://github.com/octo/project/pull/42"
        )
    }

    func testUnknownReasonsRemainReadable() {
        let notification = makeNotification(reason: "future_reason")

        XCTAssertEqual(notification.reasonDescription, "Future Reason")
    }

    private func makeNotification(reason: String) -> GitHubNotification {
        let data = Data(
            """
            {
              "id": "1",
              "unread": false,
              "updated_at": "2026-11-24T10:15:00Z",
              "reason": "\(reason)",
              "subject": {
                "title": "An issue",
                "type": "Issue",
                "url": "https://api.github.com/repos/octo/project/issues/8"
              },
              "repository": {
                "full_name": "octo/project",
                "html_url": "https://github.com/octo/project"
              }
            }
            """.utf8
        )
        return try! JSONDecoder().decode(GitHubNotification.self, from: data)
    }
}
