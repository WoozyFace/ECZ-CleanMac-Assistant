import Foundation

struct ManagedFileAccessFolder: Identifiable, Equatable {
    let url: URL

    var id: String { url.path }

    var displayName: String {
        let homePath = FileManager.default.homeDirectoryForCurrentUser.path
        if url.path == homePath + "/Desktop" {
            return localized("Desktop", "Bureaublad")
        }
        if url.path == homePath + "/Documents" {
            return localized("Documents", "Documenten")
        }
        if url.path == homePath + "/Downloads" {
            return localized("Downloads", "Downloads")
        }
        return url.lastPathComponent
    }

    var displayPath: String {
        let homePath = FileManager.default.homeDirectoryForCurrentUser.path
        if url.path.hasPrefix(homePath + "/") {
            return "~/" + String(url.path.dropFirst(homePath.count + 1))
        }
        return url.path
    }
}

struct ManagedFileAccessEntry {
    let url: URL
    let startedSecurityScope: Bool
}

enum ManagedFileAccessStore {
    private static let bookmarksKey = "managedFileAccessBookmarks"

    static func storedFolders() -> [ManagedFileAccessFolder] {
        resolvedURLsWithoutAccess().map { ManagedFileAccessFolder(url: $0) }
    }

    static func save(urls: [URL]) {
        let uniqueURLs = Array(Set(urls.map { $0.standardizedFileURL.path }))
            .map { URL(fileURLWithPath: $0, isDirectory: true) }
            .sorted { preferredOrder(for: $0) < preferredOrder(for: $1) }

        let bookmarkData = uniqueURLs.compactMap { url in
            try? url.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil)
        }
        UserDefaults.standard.set(bookmarkData, forKey: bookmarksKey)
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: bookmarksKey)
    }

    static func beginAccess() -> [ManagedFileAccessEntry] {
        storedBookmarkData().compactMap { bookmarkData in
            var isStale = false
            guard let url = try? URL(
                resolvingBookmarkData: bookmarkData,
                options: [.withSecurityScope, .withoutUI],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            ) else {
                return nil
            }

            if isStale, let refreshedBookmark = try? url.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil) {
                refreshBookmark(refreshedBookmark, forResolvedURL: url)
            }

            let startedSecurityScope = url.startAccessingSecurityScopedResource()
            return ManagedFileAccessEntry(url: url, startedSecurityScope: startedSecurityScope)
        }
    }

    static func endAccess(_ entries: [ManagedFileAccessEntry]) {
        for entry in entries where entry.startedSecurityScope {
            entry.url.stopAccessingSecurityScopedResource()
        }
    }

    private static func resolvedURLsWithoutAccess() -> [URL] {
        storedBookmarkData().compactMap { bookmarkData in
            var isStale = false
            guard let url = try? URL(
                resolvingBookmarkData: bookmarkData,
                options: [.withSecurityScope, .withoutUI],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            ) else {
                return nil
            }

            if isStale, let refreshedBookmark = try? url.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil) {
                refreshBookmark(refreshedBookmark, forResolvedURL: url)
            }

            return url
        }
        .sorted { preferredOrder(for: $0) < preferredOrder(for: $1) }
    }

    private static func storedBookmarkData() -> [Data] {
        UserDefaults.standard.array(forKey: bookmarksKey) as? [Data] ?? []
    }

    private static func refreshBookmark(_ data: Data, forResolvedURL url: URL) {
        var refreshed = storedBookmarkData()
        let path = url.standardizedFileURL.path

        if let index = refreshed.firstIndex(where: { existing in
            var isStale = false
            guard let existingURL = try? URL(
                resolvingBookmarkData: existing,
                options: [.withSecurityScope, .withoutUI],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            ) else {
                return false
            }
            return existingURL.standardizedFileURL.path == path
        }) {
            refreshed[index] = data
            UserDefaults.standard.set(refreshed, forKey: bookmarksKey)
        }
    }

    private static func preferredOrder(for url: URL) -> Int {
        let homePath = FileManager.default.homeDirectoryForCurrentUser.path
        switch url.path {
        case homePath + "/Desktop":
            return 0
        case homePath + "/Documents":
            return 1
        case homePath + "/Downloads":
            return 2
        default:
            return 10
        }
    }
}
