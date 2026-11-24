import XCTest
@testable import VelaCore

final class GitHubClientTests: XCTestCase {
    func testNotificationRequestUsesAuthenticationAndLastModified() {
        let request = GitHubClient().makeRequest(
            token: "test-token",
            lastModified: "Tue, 24 Nov 2026 10:00:00 GMT"
        )

        XCTAssertEqual(
            request.url?.absoluteString,
            "https://api.github.com/notifications?per_page=50"
        )
        XCTAssertEqual(
            request.value(forHTTPHeaderField: "Authorization"),
            "Bearer test-token"
        )
        XCTAssertEqual(
            request.value(forHTTPHeaderField: "If-Modified-Since"),
            "Tue, 24 Nov 2026 10:00:00 GMT"
        )
        XCTAssertEqual(
            request.value(forHTTPHeaderField: "X-GitHub-Api-Version"),
            "2022-11-28"
        )
    }
}
