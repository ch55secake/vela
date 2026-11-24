import Foundation

public struct GitHubClient {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func fetchNotifications(
        token: String,
        lastModified: String? = nil
    ) async throws -> NotificationFetchResult {
        let request = makeRequest(token: token, lastModified: lastModified)
        let (data, response) = try await session.data(for: request)
        guard let response = response as? HTTPURLResponse else {
            throw GitHubClientError.invalidResponse
        }

        let responseLastModified = response.value(forHTTPHeaderField: "Last-Modified")
        let pollInterval = response.value(forHTTPHeaderField: "X-Poll-Interval")
            .flatMap(Int.init)

        if response.statusCode == 304 {
            return .notModified(
                lastModified: responseLastModified,
                pollInterval: pollInterval
            )
        }

        guard response.statusCode == 200 else {
            switch response.statusCode {
            case 401:
                throw GitHubClientError.unauthorized
            case 403:
                throw GitHubClientError.forbidden
            default:
                throw GitHubClientError.httpStatus(response.statusCode)
            }
        }

        let notifications = try JSONDecoder().decode(
            [GitHubNotification].self,
            from: data
        )
        return .updated(
            notifications,
            lastModified: responseLastModified,
            pollInterval: pollInterval
        )
    }

    func makeRequest(token: String, lastModified: String?) -> URLRequest {
        var request = URLRequest(
            url: URL(string: "https://api.github.com/notifications?per_page=50")!
        )
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(
            "application/vnd.github+json",
            forHTTPHeaderField: "Accept"
        )
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        request.setValue("Vela", forHTTPHeaderField: "User-Agent")
        if let lastModified {
            request.setValue(lastModified, forHTTPHeaderField: "If-Modified-Since")
        }
        return request
    }
}

public enum NotificationFetchResult: Sendable {
    case notModified(lastModified: String?, pollInterval: Int?)
    case updated(
        [GitHubNotification],
        lastModified: String?,
        pollInterval: Int?
    )
}

public enum GitHubClientError: LocalizedError {
    case unauthorized
    case forbidden
    case httpStatus(Int)
    case invalidResponse

    public var errorDescription: String? {
        switch self {
        case .unauthorized:
            "GitHub rejected the token. Check that it has the notifications scope."
        case .forbidden:
            "GitHub denied access. Check the token permissions and API rate limit."
        case .httpStatus(let status):
            "GitHub returned HTTP \(status). Try again later."
        case .invalidResponse:
            "GitHub returned an invalid response."
        }
    }
}
