import Foundation

public struct GitHubNotification: Decodable, Identifiable, Sendable {
    public let id: String
    public let unread: Bool
    public let updatedAt: String
    public let reason: String
    public let subject: Subject
    public let repository: Repository

    enum CodingKeys: String, CodingKey {
        case id
        case unread
        case updatedAt = "updated_at"
        case reason
        case subject
        case repository
    }

    public struct Subject: Decodable, Sendable {
        public let title: String
        public let type: String
        public let url: String?
    }

    public struct Repository: Decodable, Sendable {
        public let fullName: String
        public let htmlURL: String

        enum CodingKeys: String, CodingKey {
            case fullName = "full_name"
            case htmlURL = "html_url"
        }
    }

    public var webURL: URL? {
        guard
            let apiURL = subject.url,
            let components = URLComponents(string: apiURL),
            let number = components.path.split(separator: "/").last,
            let repositoryURL = URL(string: repository.htmlURL)
        else {
            return nil
        }

        let pathComponents = components.path.split(separator: "/")
        let webResource: String
        if pathComponents.contains("pulls") {
            webResource = "pull"
        } else if pathComponents.contains("issues") {
            webResource = "issues"
        } else {
            return nil
        }

        return repositoryURL
            .appendingPathComponent(webResource)
            .appendingPathComponent(String(number))
    }

    public var reasonDescription: String {
        switch reason {
        case "assign":
            "Assigned to you"
        case "author":
            "You created this"
        case "comment":
            "New comment"
        case "invitation":
            "Invitation"
        case "manual":
            "You subscribed"
        case "mention":
            "You were mentioned"
        case "review_requested":
            "Review requested"
        case "security_alert":
            "Security alert"
        case "state_change":
            "State changed"
        case "subscribed":
            "Subscribed"
        case "team_mention":
            "Your team was mentioned"
        case "ci_activity":
            "Checks updated"
        default:
            reason.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }
}
