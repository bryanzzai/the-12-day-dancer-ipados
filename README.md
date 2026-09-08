# The 12 Day Dancer — native iPadOS probe

This repository is the native iPadOS port of Bryan MacKayne's 12 Spilledåser.

The first milestone is deliberately small and testable: a real SwiftUI/AVFoundation app for iPadOS 17 with **no WebKit in the media path**. It contains the full eight-track Dies Apri album plus one Dies Akita / Brumbrum film as bundled local media.

## What GitHub builds

The workflow `Build native iPadOS probe` runs on macOS, downloads the browser-ready media from `bryanzzai/bryanmackayne`, generates the Xcode project, compiles it for the iPad Simulator with code signing disabled, and packages a ready-to-open Xcode project with its local media.

## What Bryan eventually does on the Mac

After the GitHub build is green, download the artifact named `The-12-Day-Dancer-iPadOS-Probe`, unzip it, open `The12DayDancer.xcodeproj`, choose the connected iPad and a Personal Team under Signing & Capabilities, then press Run. Xcode/Apple may ask for Developer Mode on the iPad.

The app's deployment target is iPadOS 17.0 and its target device family is iPad only.

## Probe scope

- 12-slot native panel so the final navigation can be judged on the real 12.9-inch iPad.
- Dies Apri: 8 local `.web.m4a` tracks, native `AVPlayer`, play/pause, previous/next, seek, and per-player volume.
- Dies Akita / Brumbrum: one local MP4 in native `VideoPlayer` / `AVPlayer`.
- No network access is required by the app itself after installation.
- No `WKWebView`, no HTML audio/video element, no WebKit workaround.

If this physical-device probe behaves correctly, the remaining ten audio cycles and all nine Brumbrum films can be folded into the same native architecture.