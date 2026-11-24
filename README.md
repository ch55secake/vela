# Vela

macOS menu bar app for GitHub notifications.

## Install

```sh
brew install --cask ch55secake/tap/vela
```

Requires macOS 13 or later and a GitHub classic personal access token with the
`notifications` scope. Paste the token on first launch; Vela stores it in the
macOS Keychain.

Vela is not notarized. On first launch, macOS may require allowing it in
**System Settings → Privacy & Security**.

## Development

```sh
./scripts/build.sh
swift test
```

## Releases

Update the app version in `Resources/Info.plist`, merge to `main`, then push a
matching `vMAJOR.MINOR.PATCH` tag. GitHub Actions publishes `.app` archives for
Apple silicon and Intel.

## License

MIT
