import AppKit
import UserNotifications
import VelaCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private static let defaultPollIntervalSeconds = 5 * 60
    private static let knownUpdatesKey = "known-notification-updates"

    private let tokenStore = GitHubTokenStore()
    private let client = GitHubClient()
    private let menu = NSMenu()
    private let defaults = UserDefaults.standard
    private weak var tokenFieldForPaste: NSSecureTextField?

    private var statusItem: NSStatusItem!
    private var notifications: [GitHubNotification] = []
    private var lastModified: String?
    private var serverPollInterval: Int?
    private var notificationTracker: NotificationTracker
    private var isConnected = false
    private var isRefreshing = false
    private var lastError: String?
    private var pollingTask: Task<Void, Never>?

    override init() {
        let storedUpdates = defaults.dictionary(
            forKey: Self.knownUpdatesKey
        ) as? [String: String]
        notificationTracker = NotificationTracker(knownUpdates: storedUpdates)
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(
            withLength: NSStatusItem.variableLength
        )
        statusItem.button?.image = NSImage(
            systemSymbolName: "bell",
            accessibilityDescription: "GitHub notifications"
        )
        statusItem.button?.image?.isTemplate = true

        menu.delegate = self
        statusItem.menu = menu

        UNUserNotificationCenter.current().delegate = self

        do {
            isConnected = try tokenStore.load() != nil
            if isConnected {
                startPolling(immediate: true)
            }
        } catch {
            lastError = error.localizedDescription
        }
        rebuildMenu()
    }

    func applicationWillTerminate(_ notification: Notification) {
        pollingTask?.cancel()
    }

    func menuWillOpen(_ menu: NSMenu) {
        rebuildMenu()
    }

    private func startPolling(immediate: Bool) {
        pollingTask?.cancel()
        pollingTask = Task { [weak self] in
            if immediate {
                await self?.refresh(notifyNew: true)
            }

            while !Task.isCancelled {
                let interval = max(
                    Self.defaultPollIntervalSeconds,
                    self?.serverPollInterval ?? 0
                )
                do {
                    try await Task.sleep(for: .seconds(Int64(interval)))
                } catch {
                    break
                }
                guard !Task.isCancelled else { break }
                await self?.refresh(notifyNew: true)
            }
        }
    }

    private func refresh(notifyNew: Bool) async {
        guard !isRefreshing else { return }
        do {
            guard let token = try tokenStore.load() else {
                isConnected = false
                notifications = []
                lastError = nil
                updateStatusIcon()
                rebuildMenu()
                return
            }

            isRefreshing = true
            rebuildMenu()
            defer { isRefreshing = false }

            switch try await client.fetchNotifications(
                token: token,
                lastModified: lastModified
            ) {
            case .notModified(let responseLastModified, let pollInterval):
                absorbPollHeaders(
                    lastModified: responseLastModified,
                    pollInterval: pollInterval
                )
                lastError = nil
            case .updated(let latest, let responseLastModified, let pollInterval):
                absorbPollHeaders(
                    lastModified: responseLastModified,
                    pollInterval: pollInterval
                )
                accept(latest, notifyNew: notifyNew)
                lastError = nil
            }
        } catch {
            lastError = error.localizedDescription
        }
        updateStatusIcon()
        rebuildMenu()
    }

    private func absorbPollHeaders(lastModified: String?, pollInterval: Int?) {
        if let lastModified {
            self.lastModified = lastModified
        }
        if let pollInterval, pollInterval > 0 {
            serverPollInterval = pollInterval
        }
    }

    private func accept(
        _ latest: [GitHubNotification],
        notifyNew: Bool
    ) {
        let changedNotifications = notificationTracker.update(
            with: latest,
            notifyChanges: notifyNew
        )
        defaults.set(notificationTracker.knownUpdates, forKey: Self.knownUpdatesKey)
        changedNotifications.forEach(deliver)
        notifications = latest
    }

    private func connect(token: String) async {
        guard !isRefreshing else { return }
        isRefreshing = true
        rebuildMenu()
        defer {
            isRefreshing = false
            rebuildMenu()
        }

        do {
            let response = try await client.fetchNotifications(token: token)
            try tokenStore.save(token)
            isConnected = true
            lastModified = nil
            serverPollInterval = nil

            switch response {
            case .notModified(let responseLastModified, let pollInterval):
                absorbPollHeaders(
                    lastModified: responseLastModified,
                    pollInterval: pollInterval
                )
            case .updated(let latest, let responseLastModified, let pollInterval):
                absorbPollHeaders(
                    lastModified: responseLastModified,
                    pollInterval: pollInterval
                )
                accept(latest, notifyNew: false)
            }

            lastError = nil
            Task {
                _ = try? await UNUserNotificationCenter.current()
                    .requestAuthorization(options: [.alert, .sound])
            }
            startPolling(immediate: false)
        } catch {
            showError("Could not connect to GitHub", detail: error.localizedDescription)
        }

        updateStatusIcon()
        rebuildMenu()
    }

    private func disconnect() {
        do {
            try tokenStore.delete()
            pollingTask?.cancel()
            pollingTask = nil
            isConnected = false
            notifications = []
            lastModified = nil
            serverPollInterval = nil
            lastError = nil
            updateStatusIcon()
            rebuildMenu()
        } catch {
            showError("Could not disconnect", detail: error.localizedDescription)
        }
    }

    private func deliver(_ item: GitHubNotification) {
        let content = UNMutableNotificationContent()
        content.title = item.reasonDescription
        content.body = "\(item.repository.fullName): \(item.subject.title)"
        content.sound = .default
        if let url = item.webURL {
            content.userInfo["url"] = url.absoluteString
        }

        let request = UNNotificationRequest(
            identifier: "\(item.id)-\(item.updatedAt)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    private func rebuildMenu() {
        menu.removeAllItems()

        let heading = NSMenuItem(
            title: "GitHub Notifications",
            action: nil,
            keyEquivalent: ""
        )
        heading.isEnabled = false
        menu.addItem(heading)
        menu.addItem(.separator())

        if !isConnected {
            let statusItem = NSMenuItem(
                title: isRefreshing
                    ? "Connecting to GitHub…"
                    : "Connect to see your notifications",
                action: nil,
                keyEquivalent: ""
            )
            statusItem.isEnabled = false
            menu.addItem(statusItem)
        } else if let lastError {
            let errorItem = NSMenuItem(
                title: lastError,
                action: nil,
                keyEquivalent: ""
            )
            errorItem.isEnabled = false
            errorItem.toolTip = lastError
            menu.addItem(errorItem)
        } else if notifications.isEmpty {
            let emptyItem = NSMenuItem(
                title: isRefreshing ? "Checking GitHub…" : "You're all caught up",
                action: nil,
                keyEquivalent: ""
            )
            emptyItem.isEnabled = false
            menu.addItem(emptyItem)
        } else {
            for item in notifications.prefix(10) {
                let kind = item.subject.type == "PullRequest" ? "PR" : "Issue"
                let title = "\(kind) · \(item.repository.fullName): \(item.subject.title)"
                let menuItem = NSMenuItem(
                    title: title,
                    action: #selector(openNotification(_:)),
                    keyEquivalent: ""
                )
                menuItem.target = self
                menuItem.toolTip = "\(item.reasonDescription) — \(item.subject.title)"
                menuItem.representedObject = item.webURL
                menu.addItem(menuItem)
            }
        }

        menu.addItem(.separator())

        if isConnected {
            let checkItem = NSMenuItem(
                title: isRefreshing ? "Checking…" : "Check Now",
                action: #selector(checkNow),
                keyEquivalent: ""
            )
            checkItem.target = self
            checkItem.isEnabled = !isRefreshing
            menu.addItem(checkItem)

            let disconnectItem = NSMenuItem(
                title: "Disconnect from GitHub",
                action: #selector(disconnectFromGitHub),
                keyEquivalent: ""
            )
            disconnectItem.target = self
            menu.addItem(disconnectItem)
        } else {
            let connectItem = NSMenuItem(
                title: isRefreshing ? "Connecting…" : "Connect to GitHub…",
                action: #selector(configureToken),
                keyEquivalent: ""
            )
            connectItem.target = self
            connectItem.isEnabled = !isRefreshing
            menu.addItem(connectItem)
        }

        menu.addItem(.separator())
        let quitItem = NSMenuItem(
            title: "Quit Vela",
            action: #selector(quit),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)
    }

    private func updateStatusIcon() {
        let symbol = notifications.contains(where: \.unread) ? "bell.badge" : "bell"
        statusItem.button?.image = NSImage(
            systemSymbolName: symbol,
            accessibilityDescription: "GitHub notifications"
        )
        statusItem.button?.image?.isTemplate = true
    }

    private func showError(_ title: String, detail: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = detail
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    @objc private func configureToken() {
        let alert = NSAlert()
        alert.messageText = "Connect to GitHub"
        alert.informativeText =
            "Enter a personal access token with the notifications scope. Vela stores it in your macOS Keychain."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Connect")
        alert.addButton(withTitle: "Cancel")

        let tokenField = NSSecureTextField(
            frame: NSRect(x: 0, y: 0, width: 320, height: 24)
        )
        tokenField.placeholderString = "ghp_…"
        let accessoryView = NSView(
            frame: NSRect(x: 0, y: 0, width: 400, height: 28)
        )
        accessoryView.addSubview(tokenField)

        let pasteButton = NSButton(
            title: "Paste",
            target: self,
            action: #selector(pasteToken(_:))
        )
        pasteButton.bezelStyle = .rounded
        pasteButton.frame = NSRect(x: 328, y: 0, width: 72, height: 28)
        accessoryView.addSubview(pasteButton)

        alert.accessoryView = accessoryView
        alert.window.initialFirstResponder = tokenField
        tokenFieldForPaste = tokenField

        let response = alert.runModal()
        tokenFieldForPaste = nil
        guard response == .alertFirstButtonReturn else { return }
        let token = tokenField.stringValue.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard !token.isEmpty else { return }

        Task { await connect(token: token) }
    }

    @objc private func pasteToken(_ sender: NSButton) {
        guard
            let tokenField = tokenFieldForPaste,
            let clipboardText = NSPasteboard.general.string(forType: .string)
        else {
            return
        }

        tokenField.stringValue = clipboardText.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        tokenField.window?.makeFirstResponder(tokenField)
    }

    @objc private func checkNow() {
        Task { await refresh(notifyNew: true) }
    }

    @objc private func disconnectFromGitHub() {
        disconnect()
    }

    @objc private func openNotification(_ sender: NSMenuItem) {
        guard let url = sender.representedObject as? URL else { return }
        NSWorkspace.shared.open(url)
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let urlString = response.notification.request.content.userInfo["url"] as? String
        Task { @MainActor in
            if let urlString, let url = URL(string: urlString) {
                NSWorkspace.shared.open(url)
            }
            completionHandler()
        }
    }
}
