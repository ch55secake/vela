import XCTest
@testable import VelaCore

final class GitHubClientTests: XCTestCase {
    func testNotificationRequestUsesAuthenticationAndConditionalETag() {
        let request = GitHubClient().makeRequest(
            token: "test-token",
            etag: "\"cached-response\""
        )

        XCTAssertEqual(
            request.url?.absoluteString,
            "https://api.github.com/notifications?per_page=100"
        )
        XCTAssertEqual(
            request.value(forHTTPHeaderField: "Authorization"),
            "Bearer test-token"
        )
        XCTAssertEqual(
            request.value(forHTTPHeaderField: "If-None-Match"),
            "\"cached-response\""
        )
        XCTAssertEqual(
            request.value(forHTTPHeaderField: "X-GitHub-Api-Version"),
            "2022-11-28"
        )
    }
}
