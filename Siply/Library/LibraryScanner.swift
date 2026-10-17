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
    /// Старые ID3 пишут кириллицу в Windows-1251, а помечают Latin-1 — AVFoundation отдаёт «Êóðþ».
    /// Перекодируем, только если строка целиком в Latin-1 и больше половины её букв — из À–ÿ:
    /// так «Beyoncé» остаётся как есть.
    // ponytail: эвристика по доле букв À–ÿ; короткое «Éé» станет кириллицей — на практике не встречается
    static func repairTag(_ s: String) -> String {
        var high = 0, letters = 0
        for u in s.unicodeScalars {
            if u.value > 0xFF { return s }
            if u.value >= 0xC0 { high += 1; letters += 1 } else if u.properties.isAlphabetic { letters += 1 }
        }
        guard high * 2 > letters,
              let bytes = s.data(using: .isoLatin1),
              let fixed = String(data: bytes, encoding: .windowsCP1251) else { return s }
        return fixed
    }

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
                    if let s = try? await item.load(.stringValue), !s.isEmpty { track.title = repairTag(s) }
                case .commonKeyArtist?:
                    track.artist = repairTag((try? await item.load(.stringValue)) ?? "")
                case .commonKeyAlbumName?:
                    track.album = repairTag((try? await item.load(.stringValue)) ?? "")
                case .commonKeyArtwork?:
                    track.artwork = try? await item.load(.dataValue)
                default:
                    break
                }
            }
        }
        let nums = await numbers(from: asset)
        if let n = nums.track { track.trackNumber = n }
        if let d = nums.disc { track.discNumber = d }
        return track
    }

    /// Номера трека и диска из ID3 («3/12») или iTunes-атомов (big-endian в байтах 2–3).
    private static func numbers(from asset: AVURLAsset) async -> (track: Int?, disc: Int?) {
        guard let items = try? await asset.load(.metadata) else { return (nil, nil) }
        var track: Int?, disc: Int?
        func id3(_ item: AVMetadataItem) async -> Int? {
            guard let s = try? await item.load(.stringValue),
                  let n = Int(s.split(separator: "/").first ?? ""), n > 0 else { return nil }
            return n
        }
        func atom(_ item: AVMetadataItem) async -> Int? {
            guard let d = try? await item.load(.dataValue), d.count >= 4 else { return nil }
            let n = Int(d[d.startIndex + 2]) << 8 | Int(d[d.startIndex + 3])
            return n > 0 ? n : nil
        }
        for item in items {
            switch item.identifier {
            case .id3MetadataTrackNumber?: if let n = await id3(item) { track = n }
            case .iTunesMetadataTrackNumber?: if let n = await atom(item) { track = n }
            case .id3MetadataPartOfASet?: if let n = await id3(item) { disc = n }
            case .iTunesMetadataDiscNumber?: if let n = await atom(item) { disc = n }
            default: continue
            }
        }
        return (track, disc)
    }

    /// AVFoundation сыграет файл: контейнер читается и нет DRM. Ошибка загрузки — не играется.
    static func isPlayable(_ url: URL) async -> Bool {
        let asset = AVURLAsset(url: url)
        guard let (playable, protected) = try? await asset.load(.isPlayable, .hasProtectedContent) else { return false }
        return playable && !protected
    }

    /// Все играемые треки папки с тегами, параллельно, отсортированные.
    static func tracks(in folder: URL) async -> [Track] {
        let urls = audioFiles(in: folder)
        let loaded = await withTaskGroup(of: Track?.self) { group in
            for url in urls {
                group.addTask { await isPlayable(url) ? await loadTrack(url) : nil }
            }
            var out: [Track] = []
            for await t in group { if let t { out.append(t) } }
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
