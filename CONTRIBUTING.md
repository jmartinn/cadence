# Contributing

Thanks for taking the time to improve Cadence.

## Development Setup

- Xcode with the iOS 26.5 SDK.
- A physical iPhone is preferred for local development; the iPhone 17 simulator can be used for compile/test checks.
- Open `Cadence.xcodeproj` and run the `Cadence` scheme.

## Git Hooks

Activate the tracked hooks once per clone:

```bash
git config core.hooksPath .githooks
git config commit.template .gitmessage
```

Commit and PR titles use Conventional Commits, subject only, and 72 characters or fewer.

## Before Opening A PR

- Keep changes focused.
- Run the relevant checks for the files you changed.
- For Swift changes, run formatting, linting, build, and test checks before opening a PR.
- For documentation-only changes, check Markdown rendering, links, and factual claims.

## Pull Requests

Use the pull request template. Include a short summary, the user-visible changes, and the verification you ran.

## Code Of Conduct

Participation is covered by the [Code of Conduct](CODE_OF_CONDUCT.md).
