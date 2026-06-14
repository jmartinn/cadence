# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Cadence is a SwiftUI iOS app (Xcode) — a single-user subscription tracker + spending forecaster; a native rewrite of a Next.js PWA. Local-first via SwiftData (CloudKit deferred), no backend for the MVP.

Architecture in place (Slices 1–4 done): a pure value-type domain layer in `Cadence/Domain/**` (`BillingSchedule`, `Forecaster`, `SubscriptionPlan` — **locked & fully tested; reuse read-only, don't edit without explicit reason**); SwiftData persistence in `Cadence/Persistence/**` (`@Model Subscription`/`BalanceAnchor`, `CadenceStore`); and the first UI in `Cadence/Subscriptions/**` + `Cadence/App/RootTabView.swift` (MV architecture, no view-models). Money is always `Decimal`, never `Double`.

- Bundle ID: `com.jmartinn.Cadence`
- Platform: iOS (SDK `iphoneos`), deployment target **iOS 26.5**, universal (iPhone + iPad, `TARGETED_DEVICE_FAMILY = "1,2"`)
- Swift version: 5.0
- Single scheme: `Cadence`. Three targets: `Cadence` (app), `CadenceTests` (unit), `CadenceUITests` (UI)

## Commands

**Closeout gate (run at the end of every implementation):**
```bash
./scripts/verify.sh
```
Builds + tests in Debug on the connected physical iPhone (no simulator) and FAILS on any build error, test failure, or compiler warning in our own sources. `scripts/` is git-excluded (local-only). This is the required gate before considering work done.

**Dev workflow is device-first** — the app is built/run on a physical iPhone, not the simulator. Manual `xcodebuild` against a device:
```bash
DEVICE_ID=$(xcrun devicectl list devices | grep -i available | grep -oE '[0-9A-F]{8}-([0-9A-F]{4}-){3}[0-9A-F]{12}' | head -1)
xcodebuild build -project Cadence.xcodeproj -scheme Cadence -configuration Debug \
  -destination "platform=iOS,id=$DEVICE_ID" -allowProvisioningUpdates
```

For a simulator build (compiles, never launches Simulator.app), pick an installed one with `xcrun simctl list devices available` (this machine has the iPhone 17 line, not 16):
```bash
xcodebuild build -project Cadence.xcodeproj -scheme Cadence \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

Run all tests (unit + UI) — substitute a device or simulator destination:
```bash
xcodebuild test -project Cadence.xcodeproj -scheme Cadence \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

Run a single test target / class / method via `-only-testing`:
```bash
# whole target
xcodebuild test ... -only-testing:CadenceTests
# a Swift Testing struct (unit tests)
xcodebuild test ... -only-testing:CadenceTests/CadenceTests
# a single XCTest UI method
xcodebuild test ... -only-testing:CadenceUITests/CadenceUITests/testExample
```

> `xcodebuild` defaults to the **Release** configuration when `-configuration` is omitted; pass `-configuration Debug` for normal dev/test runs.

## Testing conventions

Two different frameworks are in use, which matters when adding tests:

- **`CadenceTests`** uses the **Swift Testing** framework (`import Testing`, `@Test` functions, `#expect(...)`). Source under test is reached via `@testable import Cadence`.
- **`CadenceUITests`** uses **XCTest** (`XCTestCase` subclasses, `@MainActor func test...`, `XCUIApplication`).

Match the framework already used by the target you are editing rather than mixing them.

## Design reference — Apple HIG knowledge base

A local, near-verbatim digest of Apple's **Human Interface Guidelines** (iOS scope, 141 pages) lives in **`docs/hig/`** (git-excluded). **Consult it for any UI/design decision** — when designing or implementing a new component, screen, or interaction; when unsure of a convention (even slightly); or to double-check an approach. Start at `docs/hig/index.md`, then read the relevant page (e.g. `tab-bars.md`, `lists-and-tables.md`, `sheets.md`, `color.md`). Each page carries Apple's "Best practices" and a `## Related` cross-link section. (Same content also mirrored to the user's Obsidian vault at `3-Resources/HIG/`.)

Visual source of truth is the user's **Figma** frames — match them exactly; the HIG governs interaction patterns and conventions, not the specific visual design. Color direction: **monochrome base + a single user-customizable accent** via `.tint` (no hardcoded brand colors).

## Local-only files (never commit / push)

These are git-excluded via `.git/info/exclude` and must never be `git add`-ed: `docs/superpowers/` (AI specs/plans), `docs/hig/` (HIG digest — Apple's copyrighted content, local reference only), `scripts/` (AI tooling), and local editor/build state (`.nvim/`, `buildServer.json`, `xcuserdata/`). New `.swift` files auto-join targets (`PBXFileSystemSynchronizedRootGroup`) — no `.pbxproj` editing needed.
