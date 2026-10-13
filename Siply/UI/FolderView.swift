import SwiftUI

/// Выбранная папка: шапка + таблица треков + поиск по ним.
struct FolderView: View {
    @Environment(Library.self) private var library
    @Environment(PlayerModel.self) private var player
    let folder: FolderNode

    @State private var tracks: [Track] = []
    @State private var artwork: Data?
    @State private var search = ""
    @State private var loading = true

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            FolderHeader(folder: folder, tracks: tracks, artwork: artwork)
                .padding(24)
            if tracks.isEmpty && !loading {
                ContentUnavailableView("В этой папке нет музыки", systemImage: "music.note")
            } else {
                TrackTable(tracks: Track.filter(tracks, query: search)) { track in
                    // Очередь — вся папка в исходном порядке, не отфильтрованная.
                    if let i = tracks.firstIndex(of: track) {
                        player.play(queue: tracks, startingAt: i)
                    }
                }
            }
        }
        .searchable(text: $search, placement: .toolbar, prompt: "Найти в папке")
        .navigationTitle(folder.name)
        .task(id: "\(folder.url.path)#\(library.generation)") { await load() }
    }

    private func load() async {
        loading = true
        search = ""
        // Сначала имена файлов — таблица видна сразу, теги подъедут следом.
        tracks = LibraryScanner.audioFiles(in: folder.url).map(Track.init)
        tracks = await LibraryScanner.tracks(in: folder.url)
        artwork = LibraryScanner.folderArtwork(for: folder.url, tracks: tracks)
        loading = false
    }
}
