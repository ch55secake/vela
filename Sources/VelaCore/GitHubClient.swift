import Foundation

public struct GitHubClient {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func fetchNotifications(
        token: String,
        etag: String? = nil
    ) async throws -> NotificationFetchResult {
        let request = makeRequest(token: token, etag: etag)
        let (data, response) = try await session.data(for: request)
        guard let response = response as? HTTPURLResponse else {
            throw GitHubClientError.invalidResponse
        }

        if response.statusCode == 304 {
            return .notModified
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
        return .updated(notifications, etag: response.value(forHTTPHeaderField: "ETag"))
    }

    func makeRequest(token: String, etag: String?) -> URLRequest {
        var request = URLRequest(
            url: URL(string: "https://api.github.com/notifications?per_page=100")!
        )
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(
            "application/vnd.github+json",
            forHTTPHeaderField: "Accept"
        )
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        request.setValue("Vela", forHTTPHeaderField: "User-Agent")
        if let etag {
            request.setValue(etag, forHTTPHeaderField: "If-None-Match")
        }
        return request
    }
}

public enum NotificationFetchResult: Sendable {
    case notModified
    case updated([GitHubNotification], etag: String?)
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
