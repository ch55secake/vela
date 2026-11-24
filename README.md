# Vela

A lightweight macOS menu bar app for GitHub notifications.

Vela checks GitHub every five minutes, uses conditional requests to avoid
downloading unchanged notifications, and can show new notifications through
macOS Notification Center. It runs as a menu bar-only app.

## Requirements

- macOS 13 or later
- Swift 6 toolchain
- A GitHub classic personal access token with the `notifications` scope

## Build and run

Build the app bundle and launch it:

```sh
./scripts/build.sh
open build/Vela.app
```

Click the bell in the menu bar and choose **Connect to GitHub…**. Enter a
classic personal access token with the `notifications` scope. Vela validates
the token against GitHub and stores it in the macOS Keychain.

To build and run the test suite without creating an app bundle:

```sh
swift test
```

## Privacy and behavior

Vela sends the token only to `api.github.com`, over HTTPS. It does not send
notification data to any other service. The token is stored in the login
Keychain and can be removed from the menu bar app with **Disconnect from
GitHub**.

Vela must be running to check for new notifications. It polls GitHub's
`GET /notifications` endpoint every five minutes; **Check Now** triggers an
immediate check. Requests use GitHub's `Last-Modified` response header and
honor `X-Poll-Interval`; unchanged inboxes return `304 Not Modified` without
consuming the API's primary rate limit.

On first connection, Vela establishes a baseline without alerting on existing
items. Later new or updated unread threads produce a macOS notification, using
the GitHub reason (for example, a review request or mention). Clicking an alert
opens the related pull request or issue. macOS notification permission is
requested on connection.

This reflects GitHub's notifications inbox, limited to repositories and
threads visible to the token. Vela does not scan every repository for pull
requests or generate events GitHub hasn't put in the inbox.

## Releases

To make a release, update `CFBundleShortVersionString` in
`Resources/Info.plist`, merge the change to `main`, then push the matching
`vMAJOR.MINOR.PATCH` tag. GitHub Actions builds and publishes a zipped `.app`
for Apple silicon and Intel, along with a SHA-256 checksum for each archive.

Download `Vela-arm64.zip` for Apple silicon or `Vela-x86_64.zip` for Intel,
verify it with its `.sha256` file if desired, unzip it, and move `Vela.app` to
the Applications folder.

Release apps are ad-hoc signed and are not notarized. macOS may require opening
the app from **System Settings → Privacy & Security** on first launch.

## Development

The app uses AppKit, `UserNotifications`, and Swift Package Manager. Pull
requests are checked on macOS with `swift build` and `swift test`.

## License

MIT
