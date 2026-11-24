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

Click the bell in the menu bar and choose **Connect to GitHub…**. Vela stores
the token in the macOS Keychain. The first successful connection establishes a
baseline, so existing notifications do not all fire as new alerts.

To build and run the test suite without creating an app bundle:

```sh
swift test
```

## Privacy and behavior

Vela sends the token only to `api.github.com`, over HTTPS. It does not send
notification data to any other service. The token is stored in the login
Keychain and can be removed from the menu bar app with **Disconnect from
GitHub**.

Vela must be running to check for new notifications. The default polling
interval is five minutes; **Check Now** triggers an immediate check. GitHub
notifications are limited to repositories and threads visible to the token.

## Development

The app uses AppKit, `UserNotifications`, and Swift Package Manager. Pull
requests are checked on macOS with `swift build` and `swift test`.

## License

MIT
