import AVFoundation

/// Чтение папки с музыкой: файлы, теги, обложка. Без состояния.
enum LibraryScanner {
    /// Только то, что AVFoundation играет сам. ALAC приходит как m4a.
    static let audioExtensions: Set<String> = ["mp3", "m4a", "aac", "flac", "wav", "aif", "aiff", "caf"]

    /// Аудиофайлы прямо в папке (подпапки не трогаем), по имени как в Finder.
    static func audioFiles(in folder: URL) -> [URL] {
        guard let items = try? FileManager.default.contentsOfDirectory(
            at: folder, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles]
        ) else { return [] }
        return items
            .filter { audioExtensions.contains($0.pathExtension.lowercased()) }
            .filter { (try? $0.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true }
            .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
    }

    /// Трек с тегами. Никогда не бросает: что не прочиталось — остаётся фолбэк по имени файла.
    static func loadTrack(_ url: URL) async -> Track {
        var track = Track(url: url)
        let asset = AVURLAsset(url: url)

        if let d = try? await asset.load(.duration), d.isNumeric, d.seconds.isFinite {
            track.duration = d.seconds
        }
        if let items = try? await asset.load(.commonMetadata) {
            for item in items {
                switch item.commonKey {
                case .commonKeyTitle?:
                    if let s = try? await item.load(.stringValue), !s.isEmpty { track.title = s }
                case .commonKeyArtist?:
                    track.artist = (try? await item.load(.stringValue)) ?? ""
                case .commonKeyAlbumName?:
                    track.album = (try? await item.load(.stringValue)) ?? ""
                case .commonKeyArtwork?:
                    track.artwork = try? await item.load(.dataValue)
                default:
                    break
                }
            }
        }
        if let n = await trackNumber(from: asset) { track.trackNumber = n }
        return track
    }

    /// Номер трека из ID3 («3/12») или iTunes-атома (big-endian в байтах 2–3).
    private static func trackNumber(from asset: AVURLAsset) async -> Int? {
        guard let items = try? await asset.load(.metadata) else { return nil }
        for item in items {
            switch item.identifier {
            case .id3MetadataTrackNumber?:
                if let s = try? await item.load(.stringValue),
                   let n = Int(s.split(separator: "/").first ?? ""), n > 0 { return n }
            case .iTunesMetadataTrackNumber?:
                if let d = try? await item.load(.dataValue), d.count >= 4 {
                    let n = Int(d[d.startIndex + 2]) << 8 | Int(d[d.startIndex + 3])
                    if n > 0 { return n }
                }
            default:
                continue
            }
        }
        return nil
    }

    /// Все треки папки с тегами, параллельно, отсортированные.
    static func tracks(in folder: URL) async -> [Track] {
        let urls = audioFiles(in: folder)
        let loaded = await withTaskGroup(of: (Int, Track).self) { group in
            for (i, url) in urls.enumerated() {
                group.addTask { (i, await loadTrack(url)) }
            }
            var out = urls.map(Track.init)
            for await (i, t) in group { out[i] = t }
            return out
        }
        return Track.sorted(loaded)
    }

    /// Обложка папки: первый трек с artwork, иначе cover.jpg / cover.png / folder.jpg.
    static func folderArtwork(for folder: URL, tracks: [Track]) -> Data? {
        if let data = tracks.lazy.compactMap(\.artwork).first { return data }
        for name in ["cover.jpg", "cover.png", "folder.jpg"] {
            if let data = try? Data(contentsOf: folder.appendingPathComponent(name)) { return data }
        }
        return nil
    }
}
