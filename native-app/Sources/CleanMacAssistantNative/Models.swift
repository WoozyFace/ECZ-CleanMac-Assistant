import SwiftUI

enum MaintenanceModuleID: String, CaseIterable, Identifiable {
    case smartCare
    case cleanup
    case protection
    case performance
    case applications
    case files
    case spaceLens

    var id: String { rawValue }
}

enum MaintenanceTaskID: String, CaseIterable, Identifiable, Hashable {
    case checkDependencies
    case trash
    case cache
    case logs
    case localizations
    case chrome
    case firefox
    case mailAttachments
    case ram
    case scripts
    case dns
    case restart
    case update
    case brew
    case activityMonitor
    case loginItems
    case safari
    case imessage
    case cookies
    case facetime
    case malware
    case agents
    case uninstall
    case orphanedFiles
    case reset
    case appStoreUpdates
    case disk
    case largeOldFiles
    case duplicates
    case installerFiles
    case downloadsReview
    case cloudAudit

    var id: String { rawValue }
}

enum TaskImpact: String {
    case light
    case medium
    case high
    case longRunning

    var title: String {
        switch self {
        case .light:
            return localized("Light", "Licht")
        case .medium:
            return localized("Medium", "Middel")
        case .high:
            return localized("High", "Hoog")
        case .longRunning:
            return localized("Long-running", "Langdurig")
        }
    }

    var tint: Color {
        switch self {
        case .light:
            return Color(red: 0.38, green: 0.76, blue: 0.98)
        case .medium:
            return Color(red: 0.32, green: 0.84, blue: 0.69)
        case .high:
            return Color(red: 1.0, green: 0.53, blue: 0.42)
        case .longRunning:
            return Color(red: 0.96, green: 0.75, blue: 0.36)
        }
    }
}

enum TaskCommandKind: Hashable {
    case dependencyCheck
    case shell(command: String, requiresAdmin: Bool)
    case inlineReport(command: String)
    case openTerminal(command: String)
    case uninstallApplication
    case resetPreferences
}

enum PromptStyle: Equatable {
    case informational
    case warning
    case critical
}

enum TaskRunState: Equatable {
    case idle
    case queued
    case running
    case succeeded(summary: String)
    case failed(summary: String)
    case skipped

    var badgeText: String {
        switch self {
        case .idle:
            return "Ready"
        case .queued:
            return "Queued"
        case .running:
            return "Running"
        case .succeeded:
            return "Done"
        case .failed:
            return "Issue"
        case .skipped:
            return "Skipped"
        }
    }

    var tint: Color {
        switch self {
        case .idle:
            return Color.white.opacity(0.28)
        case .queued:
            return Color(red: 0.47, green: 0.69, blue: 0.96)
        case .running:
            return Color(red: 0.37, green: 0.82, blue: 0.98)
        case .succeeded:
            return Color(red: 0.35, green: 0.86, blue: 0.63)
        case .failed:
            return Color(red: 1.0, green: 0.47, blue: 0.38)
        case .skipped:
            return Color(red: 0.75, green: 0.77, blue: 0.83)
        }
    }

    var resultSummary: String? {
        switch self {
        case let .succeeded(summary), let .failed(summary):
            return summary
        case .skipped:
            return localized("Skipped for now.", "Voor nu overgeslagen.")
        case .idle, .queued, .running:
            return nil
        }
    }

    var isTerminal: Bool {
        switch self {
        case .succeeded, .failed, .skipped:
            return true
        case .idle, .queued, .running:
            return false
        }
    }
}

struct TaskPrompt {
    let title: String
    let message: String
    let placeholder: String
    let actionTitle: String
}

struct TaskConfirmation {
    let title: String
    let message: String
    let confirmTitle: String
    let style: PromptStyle
}

struct ModuleTheme {
    let top: Color
    let bottom: Color
    let accent: Color
    let mist: Color
}

struct MaintenanceModule: Identifiable {
    let id: MaintenanceModuleID
    let eyebrow: String
    let title: String
    let subtitle: String
    let symbolName: String
    let theme: ModuleTheme
    let taskIDs: [MaintenanceTaskID]
}

struct MaintenanceTaskDefinition: Identifiable {
    let id: MaintenanceTaskID
    let moduleID: MaintenanceModuleID
    let title: String
    let subtitle: String
    let detail: String
    let symbolName: String
    let impact: TaskImpact
    let estimatedTime: String
    let command: TaskCommandKind
    let prompt: TaskPrompt?
    let confirmation: TaskConfirmation?
}

struct ActivityEntry: Identifiable {
    let id = UUID()
    let timestamp: Date
    let title: String
    let detail: String
    let isError: Bool
}

struct RunTaskReport: Identifiable {
    let id: MaintenanceTaskID
    let title: String
    let state: TaskRunState
    let summary: String
    let output: String?
}

struct RunCompletionReport: Identifiable {
    let id = UUID()
    let title: String
    let summary: String
    let completedCount: Int
    let skippedCount: Int
    let failureCount: Int
    let timestamp: Date
    let tasks: [RunTaskReport]
}

enum MaintenanceCatalog {
    static let modules: [MaintenanceModule] = [
        MaintenanceModule(
            id: .smartCare,
            eyebrow: "Overview and smart scan",
            title: "Home",
            subtitle: "Start here with a calmer smart scan, quick health context, and the main cleanup lanes for this Mac.",
            symbolName: "sparkles",
            theme: ModuleTheme(
                top: Color(red: 0.12, green: 0.25, blue: 0.46),
                bottom: Color(red: 0.14, green: 0.14, blue: 0.28),
                accent: Color(red: 0.50, green: 0.76, blue: 1.0),
                mist: Color(red: 0.78, green: 0.88, blue: 1.0)
            ),
            taskIDs: [.checkDependencies, .cache, .scripts]
        ),
        MaintenanceModule(
            id: .cleanup,
            eyebrow: "Storage cleanup",
            title: "Disk Cleaner",
            subtitle: "Review junk files, caches, browser leftovers, mail downloads, and other storage clutter that quietly piles up.",
            symbolName: "trash.slash.fill",
            theme: ModuleTheme(
                top: Color(red: 0.10, green: 0.34, blue: 0.38),
                bottom: Color(red: 0.08, green: 0.16, blue: 0.20),
                accent: Color(red: 0.42, green: 0.86, blue: 0.82),
                mist: Color(red: 0.78, green: 0.98, blue: 0.94)
            ),
            taskIDs: [.trash, .cache, .logs, .localizations, .chrome, .firefox, .mailAttachments]
        ),
        MaintenanceModule(
            id: .protection,
            eyebrow: "Privacy and safety",
            title: "Privacy",
            subtitle: "Cover malware, browser traces, chat leftovers, login items, and persistence points in one cleaner privacy lane.",
            symbolName: "shield.lefthalf.filled",
            theme: ModuleTheme(
                top: Color(red: 0.18, green: 0.32, blue: 0.24),
                bottom: Color(red: 0.08, green: 0.14, blue: 0.12),
                accent: Color(red: 0.47, green: 0.87, blue: 0.64),
                mist: Color(red: 0.86, green: 0.98, blue: 0.91)
            ),
            taskIDs: [.malware, .agents, .loginItems, .safari, .cookies, .imessage, .facetime]
        ),
        MaintenanceModule(
            id: .performance,
            eyebrow: "Speed and maintenance",
            title: "Performance",
            subtitle: "Handle maintenance routines, refresh caches and core processes, check updates, and keep the Mac feeling responsive.",
            symbolName: "gauge.with.dots.needle.67percent",
            theme: ModuleTheme(
                top: Color(red: 0.39, green: 0.19, blue: 0.40),
                bottom: Color(red: 0.17, green: 0.12, blue: 0.24),
                accent: Color(red: 0.95, green: 0.48, blue: 0.73),
                mist: Color(red: 0.98, green: 0.83, blue: 0.93)
            ),
            taskIDs: [.ram, .scripts, .dns, .restart, .update, .brew, .activityMonitor]
        ),
        MaintenanceModule(
            id: .applications,
            eyebrow: "Apps and leftovers",
            title: "Applications",
            subtitle: "Remove apps, review orphaned leftovers, reset broken preferences, and jump straight into update surfaces.",
            symbolName: "shippingbox.fill",
            theme: ModuleTheme(
                top: Color(red: 0.39, green: 0.27, blue: 0.14),
                bottom: Color(red: 0.17, green: 0.11, blue: 0.07),
                accent: Color(red: 0.98, green: 0.76, blue: 0.43),
                mist: Color(red: 1.0, green: 0.92, blue: 0.77)
            ),
            taskIDs: [.uninstall, .orphanedFiles, .reset, .appStoreUpdates]
        ),
        MaintenanceModule(
            id: .files,
            eyebrow: "Duplicates and files",
            title: "Files",
            subtitle: "Review duplicate files, large and older files, installer packages, and the Downloads folder from one place.",
            symbolName: "doc.on.doc.fill",
            theme: ModuleTheme(
                top: Color(red: 0.34, green: 0.23, blue: 0.31),
                bottom: Color(red: 0.16, green: 0.11, blue: 0.18),
                accent: Color(red: 0.96, green: 0.58, blue: 0.66),
                mist: Color(red: 1.0, green: 0.86, blue: 0.90)
            ),
            taskIDs: [.largeOldFiles, .duplicates, .installerFiles, .downloadsReview]
        ),
        MaintenanceModule(
            id: .spaceLens,
            eyebrow: "Storage overview",
            title: "Space Lens",
            subtitle: "Map disk usage interactively and audit synced cloud folders so storage-heavy areas are easier to spot before cleanup.",
            symbolName: "internaldrive.fill",
            theme: ModuleTheme(
                top: Color(red: 0.18, green: 0.22, blue: 0.44),
                bottom: Color(red: 0.09, green: 0.10, blue: 0.22),
                accent: Color(red: 0.64, green: 0.73, blue: 1.0),
                mist: Color(red: 0.87, green: 0.90, blue: 1.0)
            ),
            taskIDs: [.disk, .cloudAudit]
        )
    ]

    static let tasks: [MaintenanceTaskDefinition] = [
        MaintenanceTaskDefinition(
            id: .checkDependencies,
            moduleID: .smartCare,
            title: "Prepare Tools",
            subtitle: "Verify Homebrew, ClamAV, ncdu, and jdupes.",
            detail: "Makes sure the core tooling for malware scans, disk mapping, and duplicate scans is installed before deeper maintenance starts.",
            symbolName: "shippingbox.circle.fill",
            impact: .light,
            estimatedTime: "Usually under 1 minute unless installs are needed",
            command: .dependencyCheck,
            prompt: nil,
            confirmation: nil
        ),
        MaintenanceTaskDefinition(
            id: .trash,
            moduleID: .cleanup,
            title: "Empty Trash",
            subtitle: "Permanently remove everything from the Trash.",
            detail: "A direct storage win, but it is irreversible once the command completes.",
            symbolName: "trash.fill",
            impact: .medium,
            estimatedTime: "A few seconds",
            command: .shell(command: "if [ -d ~/.Trash ]; then find ~/.Trash -mindepth 1 -maxdepth 1 -exec rm -rf {} +; fi", requiresAdmin: false),
            prompt: nil,
            confirmation: TaskConfirmation(
                title: "Empty Trash?",
                message: "Everything currently in the Trash will be deleted permanently.",
                confirmTitle: "Empty Trash",
                style: .warning
            )
        ),
        MaintenanceTaskDefinition(
            id: .cache,
            moduleID: .cleanup,
            title: "Clear Cache",
            subtitle: "Refresh temporary cache state.",
            detail: "Performs a lighter cache refresh without wiping broad user data collections.",
            symbolName: "wind.circle.fill",
            impact: .light,
            estimatedTime: "A few seconds",
            command: .shell(command: "if [ -d ~/Library/Caches ]; then find ~/Library/Caches -mindepth 1 -maxdepth 1 -exec rm -rf {} +; fi", requiresAdmin: false),
            prompt: nil,
            confirmation: nil
        ),
        MaintenanceTaskDefinition(
            id: .logs,
            moduleID: .cleanup,
            title: "Clear Log Files",
            subtitle: "Remove local system log files.",
            detail: "Useful for cleanup, but it also erases local troubleshooting history.",
            symbolName: "doc.text.fill",
            impact: .high,
            estimatedTime: "A few seconds",
            command: .shell(command: "rm -rf /private/var/log/*", requiresAdmin: true),
            prompt: nil,
            confirmation: TaskConfirmation(
                title: "Delete system logs?",
                message: "This removes local log files from /private/var/log and can make troubleshooting harder afterward.",
                confirmTitle: "Delete Logs",
                style: .critical
            )
        ),
        MaintenanceTaskDefinition(
            id: .localizations,
            moduleID: .cleanup,
            title: "Remove Language Files",
            subtitle: "Delete non-English .lproj folders from Applications.",
            detail: "Aggressive space-saving option that can affect language support inside installed apps.",
            symbolName: "globe",
            impact: .high,
            estimatedTime: "A few seconds to a minute",
            command: .shell(command: "find /Applications -name '*.lproj' ! -name 'en.lproj' -type d -exec rm -rf {} +", requiresAdmin: true),
            prompt: nil,
            confirmation: TaskConfirmation(
                title: "Remove language files?",
                message: "This strips non-English localization folders from apps in /Applications.",
                confirmTitle: "Remove Files",
                style: .critical
            )
        ),
        MaintenanceTaskDefinition(
            id: .chrome,
            moduleID: .cleanup,
            title: "Clear Chrome Cache",
            subtitle: "Delete cached Chrome data from your user Library.",
            detail: "Useful when websites are serving stale assets or the browser cache has grown too large.",
            symbolName: "circle.grid.2x2.fill",
            impact: .medium,
            estimatedTime: "A few seconds",
            command: .shell(command: "rm -rf ~/Library/Caches/Google/Chrome/*", requiresAdmin: false),
            prompt: nil,
            confirmation: nil
        ),
        MaintenanceTaskDefinition(
            id: .firefox,
            moduleID: .cleanup,
            title: "Clear Firefox Cache",
            subtitle: "Delete cached Firefox profile data.",
            detail: "Clears local Firefox cache assets while leaving the browser installation itself intact.",
            symbolName: "flame.fill",
            impact: .medium,
            estimatedTime: "A few seconds",
            command: .shell(command: "rm -rf ~/Library/Caches/Firefox/Profiles/*", requiresAdmin: false),
            prompt: nil,
            confirmation: nil
        ),
        MaintenanceTaskDefinition(
            id: .mailAttachments,
            moduleID: .cleanup,
            title: "Clear Mail Attachments",
            subtitle: "Remove Mail Downloads cache from Apple Mail.",
            detail: "Targets attachment downloads cached by Apple Mail, which can quietly take a surprising amount of space.",
            symbolName: "paperclip.circle.fill",
            impact: .medium,
            estimatedTime: "A few seconds",
            command: .shell(command: "rm -rf ~/Library/Containers/com.apple.mail/Data/Library/Mail\\ Downloads/*", requiresAdmin: false),
            prompt: nil,
            confirmation: TaskConfirmation(
                title: "Remove Mail Downloads?",
                message: "Downloaded Mail attachments stored in the local Mail Downloads folder will be removed.",
                confirmTitle: "Clear Attachments",
                style: .warning
            )
        ),
        MaintenanceTaskDefinition(
            id: .ram,
            moduleID: .performance,
            title: "Free Up RAM",
            subtitle: "Run purge to release inactive memory.",
            detail: "A forceful memory refresh that can help before heavier workloads or after long uptime.",
            symbolName: "memorychip.fill",
            impact: .light,
            estimatedTime: "A few seconds",
            command: .shell(command: "purge", requiresAdmin: true),
            prompt: nil,
            confirmation: nil
        ),
        MaintenanceTaskDefinition(
            id: .scripts,
            moduleID: .performance,
            title: "Check Maintenance Status",
            subtitle: "Show how macOS background housekeeping is scheduled now.",
            detail: "Recent macOS releases handle routine housekeeping with background launchd services instead of the old periodic command-line scripts.",
            symbolName: "clock.arrow.circlepath",
            impact: .light,
            estimatedTime: "A few seconds",
            command: .inlineReport(command: "__SYSTEM_MAINTENANCE_STATUS__"),
            prompt: nil,
            confirmation: nil
        ),
        MaintenanceTaskDefinition(
            id: .dns,
            moduleID: .performance,
            title: "Flush DNS Cache",
            subtitle: "Clear resolver caches and restart mDNSResponder.",
            detail: "Useful when websites resolve incorrectly or internal hostnames seem stale.",
            symbolName: "network",
            impact: .light,
            estimatedTime: "A few seconds",
            command: .shell(command: "dscacheutil -flushcache; killall -HUP mDNSResponder", requiresAdmin: true),
            prompt: nil,
            confirmation: nil
        ),
        MaintenanceTaskDefinition(
            id: .restart,
            moduleID: .performance,
            title: "Restart Finder, Dock, and System UI",
            subtitle: "Refresh core interface processes.",
            detail: "A quick reset when Finder, Dock, or SystemUIServer feels glitchy or visually stuck.",
            symbolName: "arrow.triangle.2.circlepath.circle.fill",
            impact: .light,
            estimatedTime: "A few seconds",
            command: .shell(command: "killall Finder; killall Dock; killall SystemUIServer", requiresAdmin: false),
            prompt: nil,
            confirmation: nil
        ),
        MaintenanceTaskDefinition(
            id: .update,
            moduleID: .performance,
            title: "Install macOS Updates",
            subtitle: "Run softwareupdate for available system updates.",
            detail: "Installs available macOS updates and may require restart behavior afterward.",
            symbolName: "arrow.down.circle.fill",
            impact: .longRunning,
            estimatedTime: "Potentially several minutes",
            command: .shell(command: "softwareupdate --install --all", requiresAdmin: true),
            prompt: nil,
            confirmation: TaskConfirmation(
                title: "Install macOS updates?",
                message: "This can take a while and may affect system restart behavior afterward.",
                confirmTitle: "Install Updates",
                style: .warning
            )
        ),
        MaintenanceTaskDefinition(
            id: .brew,
            moduleID: .performance,
            title: "Update Homebrew Packages",
            subtitle: "Run brew doctor, update, and upgrade.",
            detail: "Refreshes Homebrew metadata and upgrades installed packages in one pass.",
            symbolName: "cup.and.saucer.fill",
            impact: .longRunning,
            estimatedTime: "Usually a few minutes",
            command: .shell(command: "__BREW_UPDATE__", requiresAdmin: false),
            prompt: nil,
            confirmation: nil
        ),
        MaintenanceTaskDefinition(
            id: .activityMonitor,
            moduleID: .performance,
            title: "Open Activity Monitor",
            subtitle: "Jump straight into the native live process view.",
            detail: "A fast handoff into macOS' own live monitoring surface for CPU, memory, energy, and disk activity.",
            symbolName: "waveform.path.ecg.rectangle.fill",
            impact: .light,
            estimatedTime: "Opens immediately",
            command: .shell(command: "open -a 'Activity Monitor'", requiresAdmin: false),
            prompt: nil,
            confirmation: nil
        ),
        MaintenanceTaskDefinition(
            id: .loginItems,
            moduleID: .protection,
            title: "Review Login Items",
            subtitle: "Open the Login Items settings page.",
            detail: "Useful for spotting apps or background components that start automatically and affect privacy or performance.",
            symbolName: "person.crop.circle.badge.checkmark",
            impact: .light,
            estimatedTime: "Opens immediately",
            command: .shell(command: "open 'x-apple.systempreferences:com.apple.LoginItems-Settings.extension'", requiresAdmin: false),
            prompt: nil,
            confirmation: nil
        ),
        MaintenanceTaskDefinition(
            id: .safari,
            moduleID: .protection,
            title: "Clear Safari History",
            subtitle: "Delete Safari history from the local history database.",
            detail: "Removes recorded Safari browsing history from this Mac.",
            symbolName: "safari.fill",
            impact: .high,
            estimatedTime: "A few seconds",
            command: .shell(command: "sqlite3 ~/Library/Safari/History.db 'DELETE FROM history_items;'", requiresAdmin: false),
            prompt: nil,
            confirmation: TaskConfirmation(
                title: "Clear Safari history?",
                message: "This removes browsing history records from Safari on this Mac.",
                confirmTitle: "Clear History",
                style: .warning
            )
        ),
        MaintenanceTaskDefinition(
            id: .imessage,
            moduleID: .protection,
            title: "Clear iMessage Logs",
            subtitle: "Delete local Messages database files.",
            detail: "Removes local Messages database files stored in your Library.",
            symbolName: "message.fill",
            impact: .high,
            estimatedTime: "A few seconds",
            command: .shell(command: "rm -rf ~/Library/Messages/chat.db*", requiresAdmin: false),
            prompt: nil,
            confirmation: TaskConfirmation(
                title: "Delete local iMessage data?",
                message: "This removes local Messages database files from your account.",
                confirmTitle: "Delete Data",
                style: .critical
            )
        ),
        MaintenanceTaskDefinition(
            id: .cookies,
            moduleID: .protection,
            title: "Clear Browser Cookies",
            subtitle: "Delete cookie files from your Library.",
            detail: "Reduces saved browser traces and can sign websites out of cookie-based sessions.",
            symbolName: "lock.open.rotation",
            impact: .medium,
            estimatedTime: "A few seconds",
            command: .shell(command: "rm -rf ~/Library/Cookies/*", requiresAdmin: false),
            prompt: nil,
            confirmation: TaskConfirmation(
                title: "Remove cookies?",
                message: "Websites may sign you out after cookie files are removed.",
                confirmTitle: "Remove Cookies",
                style: .warning
            )
        ),
        MaintenanceTaskDefinition(
            id: .facetime,
            moduleID: .protection,
            title: "Clear FaceTime Logs",
            subtitle: "Remove the FaceTime preferences bag file.",
            detail: "A small, targeted cleanup of local FaceTime state stored in your preferences directory.",
            symbolName: "video.fill",
            impact: .medium,
            estimatedTime: "A few seconds",
            command: .shell(command: "rm -rf ~/Library/Preferences/com.apple.FaceTime.bag.plist", requiresAdmin: false),
            prompt: nil,
            confirmation: nil
        ),
        MaintenanceTaskDefinition(
            id: .malware,
            moduleID: .protection,
            title: "Run Malware Scan",
            subtitle: "Scan the system recursively with ClamAV.",
            detail: "A deeper security task that can take a long time, but it is useful when you want a real threat sweep.",
            symbolName: "shield.lefthalf.filled.badge.checkmark",
            impact: .longRunning,
            estimatedTime: "Can take quite a while",
            command: .shell(command: "__CLAM_SCAN__", requiresAdmin: true),
            prompt: nil,
            confirmation: nil
        ),
        MaintenanceTaskDefinition(
            id: .agents,
            moduleID: .protection,
            title: "Remove Launch Agents",
            subtitle: "Delete LaunchAgents from your user Library.",
            detail: "Powerful cleanup for persistence items. Only use this if you understand the side effects.",
            symbolName: "bolt.horizontal.circle.fill",
            impact: .high,
            estimatedTime: "A few seconds",
            command: .shell(command: "rm -rf ~/Library/LaunchAgents/*", requiresAdmin: false),
            prompt: nil,
            confirmation: TaskConfirmation(
                title: "Remove LaunchAgents?",
                message: "This deletes every LaunchAgent in your user Library and can change startup behavior for apps.",
                confirmTitle: "Remove Agents",
                style: .critical
            )
        ),
        MaintenanceTaskDefinition(
            id: .uninstall,
            moduleID: .applications,
            title: "Uninstall App",
            subtitle: "Remove an app and clean common leftovers.",
            detail: "Pick an installed app from the list, then the assistant removes that app bundle and clears common user-library leftovers after confirmation.",
            symbolName: "app.badge.minus",
            impact: .high,
            estimatedTime: "A few seconds",
            command: .uninstallApplication,
            prompt: TaskPrompt(
                title: "Uninstall App",
                message: "Choose the installed app you want to remove.",
                placeholder: "Search installed apps",
                actionTitle: "Continue"
            ),
            confirmation: TaskConfirmation(
                title: "Remove app?",
                message: "The selected app bundle will be deleted from this Mac.",
                confirmTitle: "Remove App",
                style: .critical
            )
        ),
        MaintenanceTaskDefinition(
            id: .orphanedFiles,
            moduleID: .applications,
            title: "Review Orphaned Files",
            subtitle: "Find leftover app data that no longer matches an installed app.",
            detail: "Scans common user Library locations for bundle-ID leftovers whose app is no longer installed, then lets you review and remove only the items you trust.",
            symbolName: "shippingbox.circle.fill",
            impact: .medium,
            estimatedTime: "A few seconds",
            command: .inlineReport(command: "__ORPHANED_FILES__"),
            prompt: nil,
            confirmation: nil
        ),
        MaintenanceTaskDefinition(
            id: .reset,
            moduleID: .applications,
            title: "Reset App Preferences",
            subtitle: "Delete saved defaults for a bundle identifier.",
            detail: "Choose an installed app and delete its saved defaults when you want to reset broken settings without fully reinstalling it yet.",
            symbolName: "slider.horizontal.3",
            impact: .high,
            estimatedTime: "A few seconds",
            command: .resetPreferences,
            prompt: TaskPrompt(
                title: "Reset App Preferences",
                message: "Choose the installed app whose preferences you want to reset.",
                placeholder: "Search installed apps",
                actionTitle: "Continue"
            ),
            confirmation: TaskConfirmation(
                title: "Reset preferences?",
                message: "The saved defaults for the selected app will be deleted.",
                confirmTitle: "Reset Preferences",
                style: .warning
            )
        ),
        MaintenanceTaskDefinition(
            id: .appStoreUpdates,
            moduleID: .applications,
            title: "Open App Store Updates",
            subtitle: "Jump directly to the App Store updates page.",
            detail: "A quick way to check native App Store updates without digging through the App Store manually.",
            symbolName: "arrow.triangle.2.circlepath.circle",
            impact: .light,
            estimatedTime: "Opens immediately",
            command: .shell(command: "open 'macappstore://showUpdatesPage'", requiresAdmin: false),
            prompt: nil,
            confirmation: nil
        ),
        MaintenanceTaskDefinition(
            id: .disk,
            moduleID: .spaceLens,
            title: "Analyze Disk Usage",
            subtitle: "Open ncdu in a separate Terminal window.",
            detail: "Launches an interactive storage walk-through. This one still opens outside the app because ncdu is fully interactive.",
            symbolName: "externaldrive.fill.badge.magnifyingglass",
            impact: .longRunning,
            estimatedTime: "Opens immediately, exploration is up to you",
            command: .openTerminal(command: "__NCDU_COMMAND__"),
            prompt: nil,
            confirmation: nil
        ),
        MaintenanceTaskDefinition(
            id: .largeOldFiles,
            moduleID: .files,
            title: "Scan Large & Old Files",
            subtitle: "Review and remove bulky or stale files inside the app.",
            detail: "Scans Desktop, Documents, and Downloads for large or stale files and lets you choose exactly which ones to remove.",
            symbolName: "archivebox.fill",
            impact: .medium,
            estimatedTime: "A few seconds to a minute",
            command: .inlineReport(command: "__LARGE_OLD_FILES__"),
            prompt: nil,
            confirmation: nil
        ),
        MaintenanceTaskDefinition(
            id: .duplicates,
            moduleID: .files,
            title: "Scan Duplicate Files",
            subtitle: "Review duplicate copies and keep one original inside the app.",
            detail: "Scans for duplicate files in Desktop, Documents, and Downloads, keeps one suggested original per group, and lets you remove the extra copies.",
            symbolName: "square.on.square.fill",
            impact: .longRunning,
            estimatedTime: "Can take a while on larger folders",
            command: .inlineReport(command: "__DUPLICATE_SCAN__"),
            prompt: nil,
            confirmation: nil
        ),
        MaintenanceTaskDefinition(
            id: .installerFiles,
            moduleID: .files,
            title: "Clean Installer Files",
            subtitle: "Review and remove old installer packages inside the app.",
            detail: "Scans Downloads, Desktop, and Homebrew cache locations for older installer packages such as DMG, PKG, and XIP files, then lets you remove only the ones you select.",
            symbolName: "shippingbox.and.arrow.backward.fill",
            impact: .medium,
            estimatedTime: "A few seconds",
            command: .inlineReport(command: "__INSTALLER_REVIEW__"),
            prompt: nil,
            confirmation: nil
        ),
        MaintenanceTaskDefinition(
            id: .downloadsReview,
            moduleID: .files,
            title: "Review Downloads Folder",
            subtitle: "Open Downloads in Finder.",
            detail: "A quick manual review surface for installers, old archives, and forgotten downloads.",
            symbolName: "arrow.down.doc.fill",
            impact: .light,
            estimatedTime: "Opens immediately",
            command: .shell(command: "open ~/Downloads", requiresAdmin: false),
            prompt: nil,
            confirmation: nil
        ),
        MaintenanceTaskDefinition(
            id: .cloudAudit,
            moduleID: .spaceLens,
            title: "Audit Cloud Storage",
            subtitle: "Inspect local iCloud and CloudStorage usage inside the app.",
            detail: "Lists local synced cloud folders by size so you can spot space-heavy accounts before cleaning them manually.",
            symbolName: "icloud.and.arrow.down.fill",
            impact: .medium,
            estimatedTime: "A few seconds",
            command: .inlineReport(command: "__CLOUD_AUDIT__"),
            prompt: nil,
            confirmation: nil
        )
    ]

    static func module(for id: MaintenanceModuleID) -> MaintenanceModule {
        modules.first(where: { $0.id == id }) ?? modules[0]
    }

    static func task(for id: MaintenanceTaskID) -> MaintenanceTaskDefinition {
        tasks.first(where: { $0.id == id })!
    }

    static func tasks(for moduleID: MaintenanceModuleID) -> [MaintenanceTaskDefinition] {
        module(for: moduleID).taskIDs.map { task(for: $0) }
    }
}
