import Foundation

enum CleanupAction: Equatable {
    case removePath(String, requiresAdmin: Bool)
    case removePaths([String], requiresAdmin: Bool)
    case removeDirectoryContents(String, requiresAdmin: Bool)
    case shell(command: String, requiresAdmin: Bool)
    case sqlite(databasePath: String, statement: String)
}

struct TaskScanComponent: Identifiable, Equatable {
    let id: String
    let title: String
    let detail: String
    let reclaimableBytes: Int64?
    let itemCount: Int?
    let selectedByDefault: Bool
    let cleanupAction: CleanupAction?

    var countLabel: String? {
        guard let itemCount else { return nil }
        return NumberFormatter.localizedString(from: NSNumber(value: itemCount), number: .decimal)
    }
}

struct TaskScanFinding: Equatable {
    let message: String
    let reclaimableBytes: Int64?
    let itemCount: Int?
    let components: [TaskScanComponent]
}

enum TaskScanState: Equatable {
    case idle
    case scanning
    case ready(TaskScanFinding)
    case unavailable(String)
}

actor MaintenanceScanner {
    private let fileManager = FileManager.default
    private let byteFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB, .useTB]
        formatter.countStyle = .file
        formatter.includesUnit = true
        formatter.isAdaptive = true
        return formatter
    }()

    func scan(taskID: MaintenanceTaskID) async -> TaskScanState {
        switch taskID {
        case .trash:
            return reviewState(
                components: [
                    directoryComponent(
                        id: "trash_main",
                        title: "Trash",
                        detail: "Files and folders currently in the Trash.",
                        path: home(".Trash"),
                        selectedByDefault: true,
                        cleanupAction: deleteContentsAction(for: home(".Trash"), requiresAdmin: false)
                    )
                ],
                emptyMessage: "The Trash is already empty."
            )

        case .chrome:
            return reviewState(
                components: [
                    directoryComponent(
                        id: "chrome_cache",
                        title: "Chrome cache",
                        detail: "Saved website files that Chrome can download again later.",
                        path: home("Library/Caches/Google/Chrome"),
                        selectedByDefault: true,
                        cleanupAction: deleteContentsAction(for: home("Library/Caches/Google/Chrome"), requiresAdmin: false)
                    )
                ],
                emptyMessage: "Chrome cache is already small."
            )

        case .firefox:
            return reviewState(
                components: [
                    directoryComponent(
                        id: "firefox_cache",
                        title: "Firefox cache",
                        detail: "Saved website files from Firefox profiles.",
                        path: home("Library/Caches/Firefox/Profiles"),
                        selectedByDefault: true,
                        cleanupAction: deleteContentsAction(for: home("Library/Caches/Firefox/Profiles"), requiresAdmin: false)
                    )
                ],
                emptyMessage: "Firefox cache is already small."
            )

        case .mailAttachments:
            return reviewState(
                components: [
                    directoryComponent(
                        id: "mail_downloads",
                        title: "Mail attachments",
                        detail: "Attachments Apple Mail has downloaded to your Mac.",
                        path: home("Library/Containers/com.apple.mail/Data/Library/Mail Downloads"),
                        selectedByDefault: true,
                        cleanupAction: deleteContentsAction(for: home("Library/Containers/com.apple.mail/Data/Library/Mail Downloads"), requiresAdmin: false)
                    )
                ],
                emptyMessage: "No downloaded Mail attachments were found here."
            )

        case .safari:
            return reviewState(
                components: [
                    fileComponent(
                        id: "safari_history",
                        title: "Browsing history",
                        detail: "The list of websites you visited in Safari.",
                        path: home("Library/Safari/History.db"),
                        selectedByDefault: true,
                        cleanupAction: .sqlite(
                            databasePath: home("Library/Safari/History.db").path,
                            statement: "DELETE FROM history_items; DELETE FROM history_visits;"
                        )
                    ),
                    fileComponent(
                        id: "safari_downloads",
                        title: "Downloads history",
                        detail: "The list of downloaded items shown by Safari.",
                        path: home("Library/Safari/Downloads.plist"),
                        selectedByDefault: false,
                        cleanupAction: .removePath(home("Library/Safari/Downloads.plist").path, requiresAdmin: false)
                    ),
                    fileComponent(
                        id: "safari_last_session",
                        title: "Last session data",
                        detail: "Recently closed tabs and last session information.",
                        path: home("Library/Safari/LastSession.plist"),
                        selectedByDefault: false,
                        cleanupAction: .removePaths(
                            [
                                home("Library/Safari/LastSession.plist").path,
                                home("Library/Safari/RecentlyClosedTabs.plist").path
                            ],
                            requiresAdmin: false
                        )
                    ),
                    directoryComponent(
                        id: "safari_favicons",
                        title: "Website icons",
                        detail: "Small website icons Safari keeps for faster loading.",
                        path: home("Library/Safari/Favicon Cache"),
                        selectedByDefault: false,
                        cleanupAction: deleteContentsAction(for: home("Library/Safari/Favicon Cache"), requiresAdmin: false)
                    )
                ],
                emptyMessage: "No Safari data was found that needs attention right now."
            )

        case .cookies:
            return reviewState(
                components: [
                    fileComponent(
                        id: "cookies_safari",
                        title: "Safari cookies",
                        detail: "Saved website logins and preferences used by Safari.",
                        path: home("Library/Cookies/Cookies.binarycookies"),
                        selectedByDefault: false,
                        cleanupAction: .removePath(home("Library/Cookies/Cookies.binarycookies").path, requiresAdmin: false)
                    ),
                    fileComponent(
                        id: "cookies_chrome",
                        title: "Chrome cookies",
                        detail: "Saved website logins and website settings used by Google Chrome.",
                        path: home("Library/Application Support/Google/Chrome/Default/Cookies"),
                        selectedByDefault: false,
                        cleanupAction: .removePath(home("Library/Application Support/Google/Chrome/Default/Cookies").path, requiresAdmin: false)
                    ),
                    shellMatchedComponent(
                        id: "cookies_firefox",
                        title: "Firefox cookies",
                        detail: "Saved website logins and settings used by Firefox profiles.",
                        message: "Firefox cookie files can be reviewed and removed profile by profile.",
                        selectedByDefault: false,
                        shellCommand: "find ~/Library/Application\\ Support/Firefox/Profiles -name 'cookies.sqlite' -delete",
                        scanBytes: Int64(0),
                        scanCount: 0
                    )
                ],
                emptyMessage: "No browser cookie stores were found here."
            )

        case .imessage:
            return reviewState(
                components: [
                    prefixComponent(
                        id: "imessage_local_db",
                        title: "Messages database",
                        detail: "Local chat databases for the Messages app on this Mac.",
                        directory: home("Library/Messages"),
                        prefix: "chat.db",
                        selectedByDefault: false,
                        requiresAdmin: false
                    )
                ],
                emptyMessage: "No local Messages database files were found."
            )

        case .facetime:
            return reviewState(
                components: [
                    fileComponent(
                        id: "facetime_local_data",
                        title: "FaceTime local data",
                        detail: "A small FaceTime settings file stored on this Mac.",
                        path: home("Library/Preferences/com.apple.FaceTime.bag.plist"),
                        selectedByDefault: false,
                        cleanupAction: .removePath(home("Library/Preferences/com.apple.FaceTime.bag.plist").path, requiresAdmin: false)
                    )
                ],
                emptyMessage: "No FaceTime local data file was found."
            )

        case .agents:
            return launchAgentsReview()

        case .cache:
            return reviewState(
                components: [
                    directoryComponent(
                        id: "general_cache",
                        title: "General cache",
                        detail: "Temporary cache files kept by apps and macOS in your user account.",
                        path: home("Library/Caches"),
                        selectedByDefault: true,
                        cleanupAction: deleteContentsAction(for: home("Library/Caches"), requiresAdmin: false)
                    )
                ],
                emptyMessage: "No temporary files worth clearing were found."
            )

        case .downloadsReview:
            return reviewState(
                components: [
                    directoryComponent(
                        id: "downloads_folder",
                        title: "Downloads folder",
                        detail: "Files in your Downloads folder that may be safe to review and remove by hand.",
                        path: home("Downloads"),
                        selectedByDefault: false,
                        cleanupAction: nil
                    )
                ],
                emptyMessage: "Your Downloads folder looks small right now."
            )

        case .cloudAudit:
            return reviewState(
                components: [
                    directoryComponent(
                        id: "icloud_drive_local",
                        title: "iCloud Drive files",
                        detail: "Files that are stored locally from iCloud Drive.",
                        path: home("Library/Mobile Documents"),
                        selectedByDefault: false,
                        cleanupAction: nil
                    ),
                    directoryComponent(
                        id: "cloudstorage_local",
                        title: "Other cloud folders",
                        detail: "Files stored locally by synced cloud apps such as Dropbox or OneDrive.",
                        path: home("Library/CloudStorage"),
                        selectedByDefault: false,
                        cleanupAction: nil
                    )
                ],
                emptyMessage: "No local cloud storage folders with visible files were found."
            )

        case .logs:
            return .unavailable("This one needs deeper system access, so the app will clean it live when you run it.")
        case .localizations:
            return .unavailable("This one checks inside apps themselves, so it is safer to confirm and run it live.")
        case .ram, .dns, .restart:
            return .unavailable("This task speeds things up live and does not have separate cleanup parts.")
        case .scripts:
            return .ready(
                TaskScanFinding(
                    message: "macOS 26.x handles scheduled housekeeping in the background now. Open the report to see the current launchd status.",
                    reclaimableBytes: nil,
                    itemCount: nil,
                    components: []
                )
            )
        case .update, .brew, .activityMonitor, .loginItems, .appStoreUpdates:
            return .unavailable("This task opens or updates something, so there is nothing to remove beforehand.")
        case .malware:
            return .unavailable("This task does a full safety scan first when you run it.")
        case .uninstall, .reset:
            return .unavailable("This task depends on the app or settings you choose, so there is no fixed preview yet.")
        case .disk:
            return .ready(
                TaskScanFinding(
                    message: "This opens a storage map first. Nothing is deleted until you decide what to remove.",
                    reclaimableBytes: nil,
                    itemCount: nil,
                    components: []
                )
            )
        case .largeOldFiles:
            return .ready(
                TaskScanFinding(
                    message: "This shows a read-only report of large and older files in Desktop, Documents, and Downloads.",
                    reclaimableBytes: nil,
                    itemCount: nil,
                    components: []
                )
            )
        case .duplicates:
            return .ready(
                TaskScanFinding(
                    message: "This lists duplicate file candidates first and does not remove anything by itself.",
                    reclaimableBytes: nil,
                    itemCount: nil,
                    components: []
                )
            )
        case .checkDependencies:
            return .ready(
                TaskScanFinding(
                    message: "This checks whether the helper tools the app needs are already installed.",
                    reclaimableBytes: nil,
                    itemCount: nil,
                    components: []
                )
            )
        }
    }

    private func reviewState(components: [TaskScanComponent], emptyMessage: String) -> TaskScanState {
        let available = components.filter { component in
            (component.reclaimableBytes ?? 0) > 0
                || (component.itemCount ?? 0) > 0
                || component.cleanupAction == nil
                || shouldKeepProtectedComponentVisible(component)
        }

        guard !available.isEmpty else {
            return .ready(TaskScanFinding(message: emptyMessage, reclaimableBytes: 0, itemCount: 0, components: []))
        }

        let totalBytes = available.reduce(Int64(0)) { $0 + ($1.reclaimableBytes ?? 0) }
        let totalItems = available.reduce(Int32(0)) { $0 + Int32($1.itemCount ?? 0) }

        let bytesText = totalBytes > 0 ? byteFormatter.string(fromByteCount: totalBytes) : nil
        let itemsText = totalItems > 0 ? NumberFormatter.localizedString(from: NSNumber(value: totalItems), number: .decimal) : nil

        let message: String
        if let bytesText, let itemsText {
            message = localized("About \(bytesText) in \(itemsText) item(s) was found here. Open Review to choose what to clean.", "Hier is ongeveer \(bytesText) in \(itemsText) item(s) gevonden. Open Bekijken om te kiezen wat u wilt opschonen.")
        } else if let bytesText {
            message = localized("About \(bytesText) was found here. Open Review to choose what to clean.", "Hier is ongeveer \(bytesText) gevonden. Open Bekijken om te kiezen wat u wilt opschonen.")
        } else {
            message = localized("Open Review to choose exactly what you want to clean.", "Open Bekijken om precies te kiezen wat u wilt opschonen.")
        }

        return .ready(
            TaskScanFinding(
                message: message,
                reclaimableBytes: totalBytes,
                itemCount: Int(totalItems),
                components: available
            )
        )
    }

    private func launchAgentsReview() -> TaskScanState {
        let folder = home("Library/LaunchAgents")
        guard fileManager.fileExists(atPath: folder.path) else {
            return .ready(TaskScanFinding(message: "No LaunchAgents were found in your user Library.", reclaimableBytes: 0, itemCount: 0, components: []))
        }

        let urls = (try? fileManager.contentsOfDirectory(at: folder, includingPropertiesForKeys: [.fileSizeKey], options: [.skipsHiddenFiles])) ?? []
        let components = urls.map { url in
            TaskScanComponent(
                id: "launchagent_" + url.lastPathComponent.replacingOccurrences(of: ".", with: "_"),
                title: url.lastPathComponent,
                detail: "This item starts or helps run something in the background when you log in.",
                reclaimableBytes: fileSize(for: url),
                itemCount: 1,
                selectedByDefault: false,
                cleanupAction: .removePath(url.path, requiresAdmin: false)
            )
        }

        return reviewState(components: components, emptyMessage: "No LaunchAgents were found in your user Library.")
    }

    private func directoryComponent(id: String, title: String, detail: String, path: URL, selectedByDefault: Bool, cleanupAction: CleanupAction?) -> TaskScanComponent {
        let stats = directoryStats(for: path)
        return TaskScanComponent(
            id: id,
            title: title,
            detail: detail,
            reclaimableBytes: stats.bytes,
            itemCount: stats.files,
            selectedByDefault: selectedByDefault,
            cleanupAction: cleanupAction
        )
    }

    private func fileComponent(id: String, title: String, detail: String, path: URL, selectedByDefault: Bool, cleanupAction: CleanupAction?) -> TaskScanComponent {
        let size = fileSize(for: path)
        return TaskScanComponent(
            id: id,
            title: title,
            detail: detail,
            reclaimableBytes: size,
            itemCount: fileManager.fileExists(atPath: path.path) ? 1 : 0,
            selectedByDefault: selectedByDefault,
            cleanupAction: cleanupAction
        )
    }

    private func prefixComponent(id: String, title: String, detail: String, directory: URL, prefix: String, selectedByDefault: Bool, requiresAdmin: Bool) -> TaskScanComponent {
        let children = (try? fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.fileSizeKey], options: [.skipsHiddenFiles])) ?? []
        let matches = children.filter { $0.lastPathComponent.hasPrefix(prefix) }
        let totalBytes = matches.reduce(Int64(0)) { $0 + fileSize(for: $1) }
        return TaskScanComponent(
            id: id,
            title: title,
            detail: detail,
            reclaimableBytes: totalBytes,
            itemCount: matches.count,
            selectedByDefault: selectedByDefault,
            cleanupAction: matches.isEmpty ? nil : .removePaths(matches.map(\.path), requiresAdmin: requiresAdmin)
        )
    }

    private func shellMatchedComponent(id: String, title: String, detail: String, message: String, selectedByDefault: Bool, shellCommand: String, scanBytes: Int64, scanCount: Int) -> TaskScanComponent {
        TaskScanComponent(
            id: id,
            title: title,
            detail: detail + " " + message,
            reclaimableBytes: scanBytes,
            itemCount: scanCount,
            selectedByDefault: selectedByDefault,
            cleanupAction: .shell(command: shellCommand, requiresAdmin: false)
        )
    }

    private func deleteContentsAction(for path: URL, requiresAdmin: Bool) -> CleanupAction {
        .removeDirectoryContents(path.path, requiresAdmin: requiresAdmin)
    }

    private func shouldKeepProtectedComponentVisible(_ component: TaskScanComponent) -> Bool {
        guard let action = component.cleanupAction else { return false }

        switch action {
        case let .removePath(path, _):
            return isLikelyProtectedPath(path) && fileManager.fileExists(atPath: path)
        case let .removePaths(paths, _):
            return paths.contains { isLikelyProtectedPath($0) && fileManager.fileExists(atPath: $0) }
        case let .removeDirectoryContents(path, _):
            return isLikelyProtectedPath(path) && fileManager.fileExists(atPath: path)
        case let .sqlite(databasePath, _):
            return isLikelyProtectedPath(databasePath) && fileManager.fileExists(atPath: databasePath)
        case .shell:
            return false
        }
    }

    private func isLikelyProtectedPath(_ path: String) -> Bool {
        let lowered = path.lowercased()
        return lowered.contains("/.trash")
            || lowered.contains("/library/caches")
            || lowered.contains("/library/safari/")
            || lowered.contains("/library/messages")
            || lowered.contains("com.apple.mail")
            || lowered.contains("/library/cookies")
    }

    private func home(_ relativePath: String) -> URL {
        fileManager.homeDirectoryForCurrentUser.appendingPathComponent(relativePath)
    }

    private func shellQuote(_ raw: String) -> String {
        "'" + raw.replacingOccurrences(of: "'", with: "'\"'\"'") + "'"
    }

    private func directoryStats(for rootURL: URL) -> (bytes: Int64, files: Int) {
        guard fileManager.fileExists(atPath: rootURL.path) else {
            return (0, 0)
        }

        var totalBytes: Int64 = 0
        var totalFiles = 0

        guard let enumerator = fileManager.enumerator(
            at: rootURL,
            includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey],
            options: [.skipsHiddenFiles],
            errorHandler: { _, _ in true }
        ) else {
            return (0, 0)
        }

        for case let fileURL as URL in enumerator {
            let values = try? fileURL.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey])
            if values?.isRegularFile == true {
                totalFiles += 1
                totalBytes += Int64(values?.fileSize ?? 0)
            }
        }

        return (totalBytes, totalFiles)
    }

    private func fileSize(for url: URL) -> Int64 {
        guard fileManager.fileExists(atPath: url.path) else { return 0 }
        let values = try? url.resourceValues(forKeys: [.fileSizeKey])
        return Int64(values?.fileSize ?? 0)
    }
}
