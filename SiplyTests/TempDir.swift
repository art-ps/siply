import Foundation

/// Временная папка для тестов. Удаляется при деините.
final class TempDir {
    let url: URL

    init() {
        url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("siply-tests-\(UUID().uuidString)", isDirectory: true)
        try! FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    deinit { try? FileManager.default.removeItem(at: url) }

    @discardableResult
    func file(_ name: String, _ bytes: Data = Data()) -> URL {
        let u = url.appendingPathComponent(name)
        try! bytes.write(to: u)
        return u
    }

    @discardableResult
    func dir(_ name: String) -> URL {
        let u = url.appendingPathComponent(name, isDirectory: true)
        try! FileManager.default.createDirectory(at: u, withIntermediateDirectories: true)
        return u
    }
}
