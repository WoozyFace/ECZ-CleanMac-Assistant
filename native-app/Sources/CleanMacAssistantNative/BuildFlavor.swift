import Foundation

enum AppBuildFlavor {
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
