import Foundation

/// Трек — файл в папке. Теги могут быть не загружены: тогда title = имя файла.
struct Track: Identifiable, Hashable {
    var url: URL
    var title: String
    var artist: String = ""
    var album: String = ""
    var duration: TimeInterval = 0
    var trackNumber: Int?
    var artwork: Data?

    var id: URL { url }

    /// Только по имени файла — пока теги не прочитаны или не читаются.
    init(url: URL) {
        self.url = url
        let name = url.deletingPathExtension().lastPathComponent
        self.title = name
        self.trackNumber = Track.leadingNumber(in: name)
    }

    init(url: URL, title: String, artist: String = "", album: String = "",
         duration: TimeInterval = 0, trackNumber: Int? = nil, artwork: Data? = nil) {
        self.url = url
        self.title = title
        self.artist = artist
        self.album = album
        self.duration = duration
        self.trackNumber = trackNumber
        self.artwork = artwork
    }

    /// «03 - Song» → 3, «1-07 Song» → 7, «12. Song» → 12, «1999» → nil.
    /// Номер — 1–3 цифры с разделителем после; опционально «диск-» перед.
    static func leadingNumber(in name: String) -> Int? {
        let regex = /^\s*(?:\d{1,2}[-.])?\s*(\d{1,3})[\s.\-_)]/
        guard let match = name.firstMatch(of: regex) else { return nil }
        return Int(match.1)
    }

    /// По номеру трека (без номера — в конец), затем по имени файла как в Finder.
    static func sorted(_ tracks: [Track]) -> [Track] {
        tracks.sorted { a, b in
            switch (a.trackNumber, b.trackNumber) {
            case let (x?, y?) where x != y:
                return x < y
            case (.some, .none):
                return true
            case (.none, .some):
                return false
            default:
                return a.url.lastPathComponent.localizedStandardCompare(b.url.lastPathComponent) == .orderedAscending
            }
        }
    }

    /// «1 трек», «2 трека», «5 треков».
    static func countLabel(_ n: Int) -> String {
        let mod10 = n % 10, mod100 = n % 100
        let word: String
        if mod10 == 1 && mod100 != 11 { word = "трек" }
        else if (2...4).contains(mod10) && !(12...14).contains(mod100) { word = "трека" }
        else { word = "треков" }
        return "\(n) \(word)"
    }

    /// Подстрока без учёта регистра по названию, артисту, альбому. Пустой запрос — всё.
    static func filter(_ tracks: [Track], query: String) -> [Track] {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return tracks }
        return tracks.filter { t in
            [t.title, t.artist, t.album].contains { $0.localizedCaseInsensitiveContains(q) }
        }
    }
}

extension TimeInterval {
    /// 83 → «1:23». NaN, 0 и отрицательные → «0:00».
    var mmss: String {
        guard isFinite, self > 0 else { return "0:00" }
        let total = Int(rounded())
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
