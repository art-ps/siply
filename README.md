<p align="center">
  <img src="site/assets/icon.png" width="128" height="128" alt="Siply icon">
</p>

<h1 align="center">Siply</h1>

<p align="center">
  A lightweight macOS music player for your folders.<br>
  Open a folder — listen. No import, no library database.
</p>

<p align="center">
  <a href="https://github.com/art-ps/siply/releases/latest"><b>Download for macOS</b></a> ·
  <a href="https://art-ps.github.io/siply/en/">Website</a> ·
  <a href="README.ru.md">Русский</a>
</p>

<p align="center">
  <img src="site/assets/screenshot.png" alt="Siply window: folder tree on the left, tracks with artwork on the right, floating player bar">
</p>

## Why

Music apps want to own your collection: import it, index it, sync it. Siply does the opposite. Your folders already are the library — Siply just shows them in a clean, Apple Music-style window and plays them.

## Features

- **Folders are the library.** The sidebar mirrors your folder tree; the main pane lists the tracks of the selected folder.
- **Native formats.** MP3, AAC/M4A, FLAC, WAV, AIFF, CAF — everything AVFoundation plays, lossless included.
- **Tags and artwork.** Titles, artists, albums and covers come from file tags. Old Cyrillic ID3 tags in Windows-1251 are shown correctly, not as mojibake.
- **Apple Music feel.** Album header with Play and Shuffle, track table, floating Liquid Glass player bar on macOS 26.
- **Choose the output device.** Play Siply through a Bluetooth speaker while system sounds stay on the Mac speakers. If the speaker disconnects, music keeps playing and returns to it on reconnect.
- **Search in folder**, resizable columns that remember their widths.
- **Keyboard and media keys.** Space plays/pauses, Enter plays the selected track; Control Center and media keys work.
- **Tiny and native.** Swift + SwiftUI + AVFoundation, zero third-party dependencies.

## Install

1. Download `Siply-x.y.z.dmg` from [Releases](https://github.com/art-ps/siply/releases/latest).
2. Open it and drag **Siply** to **Applications**.

Requires macOS 14 Sonoma or later. Universal build for Apple Silicon and Intel, signed and notarized by Apple.

## Build from source

```bash
brew install xcodegen
xcodegen generate
xcodebuild -scheme Siply -configuration Release build
```

Tests: `xcodebuild test -scheme Siply -destination 'platform=macOS'`.
Release (sign, notarize, DMG): `scripts/release.sh`.

---

<p align="center">
  Built with AI. Featured on <a href="https://vibecoded.ru/products/siply">vibecoded.ru</a>.
</p>
