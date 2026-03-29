import Foundation

enum AppBuildFlavor {
    static let currentVersion = "1.0.3"

    #if DEVELOPER_BUILD
    static let isDeveloper = true
    #else
    static let isDeveloper = false
    #endif

    static var appName: String {
        isDeveloper ? "CleanMac Assistant Dev" : "CleanMac Assistant"
    }

    static var buildLabel: String {
        isDeveloper
            ? localized("Developer build", "Ontwikkelbuild")
            : localized("Release build", "Releasebuild")
    }
}
