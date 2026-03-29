import AppKit
import SwiftUI

private enum AppPalette {
    static let canvasTop = Color(red: 0.34, green: 0.24, blue: 0.38)
    static let canvasMid = Color(red: 0.22, green: 0.22, blue: 0.32)
    static let canvasBottom = Color(red: 0.13, green: 0.17, blue: 0.27)

    static let sidebarTop = Color(red: 0.27, green: 0.22, blue: 0.33)
    static let sidebarBottom = Color(red: 0.16, green: 0.18, blue: 0.27)

    static let textPrimary = Color.white.opacity(0.97)
    static let textSecondary = Color.white.opacity(0.76)
    static let textTertiary = Color.white.opacity(0.5)

    static let card = Color.white.opacity(0.065)
    static let cardStrong = Color.white.opacity(0.11)
    static let line = Color.white.opacity(0.1)
    static let shadow = Color.black.opacity(0.24)

    static let iceBlue = Color(red: 0.73, green: 0.88, blue: 1.0)
    static let blueGlow = Color(red: 0.46, green: 0.71, blue: 1.0)
    static let pinkGlow = Color(red: 0.96, green: 0.38, blue: 0.72)
    static let violetGlow = Color(red: 0.62, green: 0.46, blue: 0.86)
    static let success = Color(red: 0.37, green: 0.89, blue: 0.61)
    static let error = Color(red: 1.0, green: 0.49, blue: 0.45)
}

private enum AppResources {
    private static let packageResourceBundleName = "CleanMacAssistantNative_CleanMacAssistantNative"
    private static let brandMarkAssetName = NSImage.Name("BrandMark")
    private static let brandMarkLegacySubdirectories = [
        "Assets.xcassets/BrandMark.imageset",
        "Contents/Resources/Assets.xcassets/BrandMark.imageset"
    ]

    private static let packagedBundle: Bundle? = {
        if let resourceURL = Bundle.main.resourceURL {
            let packagedBundleURL = resourceURL.appendingPathComponent("\(packageResourceBundleName).bundle")
            return Bundle(url: packagedBundleURL)
        }

        return nil
    }()

    static let brandMarkImage: NSImage? = {
        let candidateBundles: [Bundle] = [
            packagedBundle,
            .module,
            .main
        ].compactMap { $0 }

        for bundle in candidateBundles {
            if let image = bundle.image(forResource: brandMarkAssetName) {
                return image
            }

            for subdirectory in brandMarkLegacySubdirectories {
                if let url = bundle.url(
                    forResource: "brand-mark",
                    withExtension: "png",
                    subdirectory: subdirectory
                ), let image = NSImage(contentsOf: url) {
                    return image
                }
            }

            if let url = bundle.url(
                forResource: "brand-mark",
                withExtension: "png"
            ), let image = NSImage(contentsOf: url) {
                return image
            }
        }

        return nil
    }()
}

private struct LocalSystemSnapshot {
    let freeDisk: String
    let uptime: String
    let osVersion: String

    static var current: LocalSystemSnapshot {
        let fileManager = FileManager.default
        let freeDiskBytes = (try? fileManager.attributesOfFileSystem(forPath: NSHomeDirectory())[.systemFreeSize] as? NSNumber)?.int64Value ?? 0

        let byteFormatter = ByteCountFormatter()
        byteFormatter.allowedUnits = [.useGB, .useTB]
        byteFormatter.countStyle = .file
        byteFormatter.isAdaptive = true

        let version = ProcessInfo.processInfo.operatingSystemVersion
        return LocalSystemSnapshot(
            freeDisk: freeDiskBytes > 0 ? byteFormatter.string(fromByteCount: freeDiskBytes) : localized("Unknown", "Onbekend"),
            uptime: formattedUptime(ProcessInfo.processInfo.systemUptime),
            osVersion: "macOS \(version.majorVersion).\(version.minorVersion)"
        )
    }

    private static func formattedUptime(_ interval: TimeInterval) -> String {
        let totalHours = Int(interval / 3600)
        let days = totalHours / 24
        let hours = totalHours % 24

        if days > 0 {
            return localized("\(days)d \(hours)h", "\(days)d \(hours)u")
        }

        let minutes = Int(interval / 60) % 60
        return localized("\(hours)h \(minutes)m", "\(hours)u \(minutes)m")
    }
}

private struct BrandMarkArtwork: View {
    var body: some View {
        Group {
            if let brandMarkImage = AppResources.brandMarkImage {
                Image(nsImage: brandMarkImage)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
            } else {
                Image(systemName: "sparkles")
                    .resizable()
                    .scaledToFit()
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Color.white.opacity(0.88))
                    .padding(6)
            }
        }
    }
}

private extension View {
    @ViewBuilder
    func appScrollIndicators() -> some View {
        if #available(macOS 13.0, *) {
            self.scrollIndicators(.visible)
        } else {
            self
        }
    }
}

struct ContentView: View {
    @EnvironmentObject private var viewModel: AppViewModel

    var body: some View {
        ZStack {
            AppCanvasBackground(module: viewModel.selectedModule)

            HStack(spacing: 0) {
                SidebarPane()
                    .frame(width: 318)

                ModuleDetailPane(module: viewModel.selectedModule)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(AppShellBackground())
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(AppPalette.canvasBottom.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }
}

private struct AppCanvasBackground: View {
    let module: MaintenanceModule

    var body: some View {
        let tone = visualTone(for: module.id)

        ZStack {
            LinearGradient(
                colors: [
                    tone.canvasTop,
                    AppPalette.canvasMid,
                    tone.canvasBottom
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(tone.glowPrimary.opacity(0.2))
                .frame(width: 520, height: 520)
                .blur(radius: 90)
                .offset(x: -220, y: -320)

            Circle()
                .fill(tone.glowSecondary.opacity(0.18))
                .frame(width: 620, height: 620)
                .blur(radius: 120)
                .offset(x: 520, y: -120)

            Circle()
                .fill(tone.glowTertiary.opacity(0.16))
                .frame(width: 560, height: 560)
                .blur(radius: 120)
                .offset(x: 120, y: 380)
        }
        .ignoresSafeArea()
    }
}

private struct AppShellBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.23, green: 0.2, blue: 0.31),
                Color(red: 0.14, green: 0.17, blue: 0.26),
                Color(red: 0.11, green: 0.14, blue: 0.22)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

private struct ModuleVisualTone {
    let canvasTop: Color
    let canvasBottom: Color
    let glowPrimary: Color
    let glowSecondary: Color
    let glowTertiary: Color
    let headerTop: Color
    let headerBottom: Color
}

private func visualTone(for moduleID: MaintenanceModuleID) -> ModuleVisualTone {
    switch moduleID {
    case .smartCare:
        return ModuleVisualTone(
            canvasTop: Color(red: 0.29, green: 0.22, blue: 0.40),
            canvasBottom: Color(red: 0.12, green: 0.16, blue: 0.29),
            glowPrimary: AppPalette.blueGlow,
            glowSecondary: AppPalette.violetGlow,
            glowTertiary: AppPalette.iceBlue,
            headerTop: Color(red: 0.23, green: 0.33, blue: 0.58),
            headerBottom: Color(red: 0.16, green: 0.18, blue: 0.38)
        )
    case .cleanup:
        return ModuleVisualTone(
            canvasTop: Color(red: 0.20, green: 0.29, blue: 0.31),
            canvasBottom: Color(red: 0.10, green: 0.15, blue: 0.19),
            glowPrimary: Color(red: 0.35, green: 0.86, blue: 0.80),
            glowSecondary: Color(red: 0.27, green: 0.67, blue: 0.76),
            glowTertiary: Color(red: 0.66, green: 0.96, blue: 0.90),
            headerTop: Color(red: 0.14, green: 0.39, blue: 0.42),
            headerBottom: Color(red: 0.10, green: 0.18, blue: 0.22)
        )
    case .protection:
        return ModuleVisualTone(
            canvasTop: Color(red: 0.20, green: 0.27, blue: 0.25),
            canvasBottom: Color(red: 0.09, green: 0.13, blue: 0.12),
            glowPrimary: Color(red: 0.41, green: 0.84, blue: 0.61),
            glowSecondary: Color(red: 0.25, green: 0.57, blue: 0.45),
            glowTertiary: Color(red: 0.76, green: 0.97, blue: 0.86),
            headerTop: Color(red: 0.19, green: 0.36, blue: 0.27),
            headerBottom: Color(red: 0.11, green: 0.17, blue: 0.14)
        )
    case .performance:
        return ModuleVisualTone(
            canvasTop: Color(red: 0.34, green: 0.21, blue: 0.34),
            canvasBottom: Color(red: 0.14, green: 0.11, blue: 0.22),
            glowPrimary: AppPalette.pinkGlow,
            glowSecondary: Color(red: 0.86, green: 0.39, blue: 0.63),
            glowTertiary: Color(red: 0.98, green: 0.72, blue: 0.86),
            headerTop: Color(red: 0.43, green: 0.21, blue: 0.39),
            headerBottom: Color(red: 0.19, green: 0.12, blue: 0.24)
        )
    case .applications:
        return ModuleVisualTone(
            canvasTop: Color(red: 0.34, green: 0.24, blue: 0.20),
            canvasBottom: Color(red: 0.14, green: 0.10, blue: 0.09),
            glowPrimary: Color(red: 0.98, green: 0.72, blue: 0.45),
            glowSecondary: Color(red: 0.83, green: 0.56, blue: 0.24),
            glowTertiary: Color(red: 1.0, green: 0.90, blue: 0.72),
            headerTop: Color(red: 0.46, green: 0.31, blue: 0.16),
            headerBottom: Color(red: 0.20, green: 0.12, blue: 0.08)
        )
    case .files:
        return ModuleVisualTone(
            canvasTop: Color(red: 0.34, green: 0.20, blue: 0.29),
            canvasBottom: Color(red: 0.15, green: 0.09, blue: 0.16),
            glowPrimary: Color(red: 0.97, green: 0.54, blue: 0.63),
            glowSecondary: Color(red: 0.80, green: 0.32, blue: 0.52),
            glowTertiary: Color(red: 1.0, green: 0.84, blue: 0.89),
            headerTop: Color(red: 0.45, green: 0.24, blue: 0.33),
            headerBottom: Color(red: 0.18, green: 0.11, blue: 0.17)
        )
    case .spaceLens:
        return ModuleVisualTone(
            canvasTop: Color(red: 0.18, green: 0.22, blue: 0.40),
            canvasBottom: Color(red: 0.08, green: 0.10, blue: 0.22),
            glowPrimary: Color(red: 0.62, green: 0.72, blue: 1.0),
            glowSecondary: Color(red: 0.42, green: 0.63, blue: 0.98),
            glowTertiary: Color(red: 0.84, green: 0.89, blue: 1.0),
            headerTop: Color(red: 0.24, green: 0.28, blue: 0.50),
            headerBottom: Color(red: 0.11, green: 0.13, blue: 0.25)
        )
    }
}

private struct AssistantMark: View {
    let glow: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            glow,
                            AppPalette.iceBlue
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.22), lineWidth: 1)

            Circle()
                .fill(Color.white.opacity(0.22))
                .frame(width: 12, height: 12)
                .offset(x: -8, y: -8)

            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Color.white.opacity(0.92))
                .frame(width: 24, height: 6)
                .rotationEffect(.degrees(38))

            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Color.white.opacity(0.82))
                .frame(width: 13, height: 6)
                .rotationEffect(.degrees(-38))
                .offset(x: 8, y: 9)
        }
    }
}

private struct SidebarPane: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @Namespace private var sidebarSelection

    private var interactionLocked: Bool {
        #if DEVELOPER_BUILD
        viewModel.activeReviewTask != nil || viewModel.isRunning || viewModel.isShowingAbout || viewModel.isShowingDeveloperPanel
        #else
        viewModel.activeReviewTask != nil || viewModel.isRunning || viewModel.isShowingAbout
        #endif
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            header

            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 10) {
                    ForEach(viewModel.modules) { module in
                        Button {
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                                viewModel.selectModule(module.id)
                            }
                        } label: {
                            SidebarModuleRow(
                                module: module,
                                isSelected: viewModel.selectedModuleID == module.id,
                                selectionAnimation: sidebarSelection
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(interactionLocked)
                    }
                }
                .padding(.vertical, 4)
            }
            .appScrollIndicators()

            Spacer(minLength: 0)

            summaryCard

            VStack(spacing: 10) {
                SidebarActionButton(
                    title: localized("Site", "Website"),
                    subtitle: "cleanmac-assistant.easycompzeeland.nl",
                    symbol: "safari"
                ) {
                    viewModel.openWebsite()
                }
                SidebarActionButton(
                    title: localized("Support", "Ondersteuning"),
                    subtitle: "Hulp op afstand",
                    symbol: "lifepreserver"
                ) {
                    viewModel.openSupport()
                }
                SidebarActionButton(
                    title: localized("Homebrew", "Homebrew"),
                    subtitle: "brew.sh",
                    symbol: "shippingbox.fill"
                ) {
                    viewModel.openBrew()
                }
                SidebarActionButton(
                    title: localized("About", "Over"),
                    subtitle: viewModel.appVersionLabel,
                    symbol: "info.circle"
                ) {
                    viewModel.openAbout()
                }
                #if DEVELOPER_BUILD
                SidebarActionButton(
                    title: "Preview Tools",
                    subtitle: "Debug screenshots",
                    symbol: "wand.and.stars"
                ) {
                    viewModel.toggleDeveloperPanel()
                }
                #endif
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 20)
        .background(
            LinearGradient(
                colors: [
                    AppPalette.sidebarTop.opacity(0.97),
                    AppPalette.sidebarBottom.opacity(0.94)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(width: 1)
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 40, height: 40)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.white.opacity(0.10), lineWidth: 1)
                        )

                    BrandMarkArtwork()
                        .frame(width: 24, height: 24)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text(localized("CleanMac Assistant", "CleanMac Assistant"))
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(AppPalette.textPrimary)
                    Text(localized("EasyComp Zeeland", "EasyComp Zeeland"))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppPalette.textTertiary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)

            Text(localized("Cleaner Mac care, without the noise.", "Rustigere Mac-zorg, zonder ruis."))
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppPalette.textTertiary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        #if DEVELOPER_BUILD
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            viewModel.toggleDeveloperPanel()
        }
        .help("Double-click to open Preview Tools")
        #endif
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(localized("Last run", "Laatste run"), systemImage: "clock.arrow.circlepath")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(AppPalette.textTertiary)
                .textCase(.uppercase)

            Text(viewModel.lastRunSummary.appLocalized)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppPalette.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Rectangle()
                .fill(Color.white.opacity(0.07))
                .frame(height: 1)

            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(localized("Updates", "Updates"))
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(AppPalette.textTertiary)
                        .textCase(.uppercase)
                    Text(viewModel.updateStatusText)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppPalette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 12)

                Button(localized("Check now", "Nu controleren")) {
                    viewModel.checkForUpdates()
                }
                .buttonStyle(SidebarUtilityButtonStyle())
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(AppPalette.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
}

private struct SidebarModuleRow: View {
    let module: MaintenanceModule
    let isSelected: Bool
    let selectionAnimation: Namespace.ID

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 13) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? module.theme.accent.opacity(0.18) : (isHovered ? Color.white.opacity(0.05) : Color.clear))
                    .frame(width: 36, height: 36)

                Image(systemName: module.symbolName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(isSelected ? AppPalette.textPrimary : AppPalette.textSecondary)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(module.title.appLocalized)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppPalette.textPrimary)

                Text(module.eyebrow.appLocalized)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppPalette.textTertiary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(backgroundView)
        .scaleEffect(isHovered ? 1.012 : 1)
        .shadow(
            color: module.theme.accent.opacity(isSelected ? 0.08 : 0.02),
            radius: isSelected ? 10 : 4,
            y: isSelected ? 6 : 2
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.16)) {
                isHovered = hovering
            }
        }
    }

    @ViewBuilder
    private var backgroundView: some View {
        if isSelected {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(module.theme.accent.opacity(0.10))
                .matchedGeometryEffect(id: "sidebar-selection", in: selectionAnimation)
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(module.theme.accent.opacity(0.20), lineWidth: 0.5)
                }
                .overlay(alignment: .trailing) {
                    Circle()
                        .fill(module.theme.accent)
                        .frame(width: 6, height: 6)
                        .padding(.trailing, 10)
                }
        } else {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(isHovered ? 0.07 : 0.03))
        }
    }
}

private struct SidebarActionButton: View {
    let title: String
    let subtitle: String
    let symbol: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: symbol)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppPalette.iceBlue)
                    .frame(width: 22)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title.appLocalized)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(AppPalette.textPrimary)

                    Text(subtitle.appLocalized)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(AppPalette.textTertiary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .buttonStyle(SidebarUtilityButtonStyle())
    }
}

private struct ModuleDetailPane: View {
    @EnvironmentObject private var viewModel: AppViewModel
    let module: MaintenanceModule

    private var tasks: [MaintenanceTaskDefinition] {
        viewModel.selectedModuleTasks
    }

    private var currentTaskTitle: String {
        guard let currentTaskID = viewModel.currentTaskID else { return localized("maintenance", "onderhoud") }
        return MaintenanceCatalog.task(for: currentTaskID).title.appLocalized
    }

    private var reviewTask: MaintenanceTaskDefinition? {
        viewModel.activeReviewTask
    }

    private var overlayIsVisible: Bool {
        #if DEVELOPER_BUILD
        reviewTask != nil || viewModel.isShowingAbout || viewModel.isRunning || viewModel.lastRunReport != nil || viewModel.isShowingDeveloperPanel || viewModel.isShowingUpdateExperience
        #else
        reviewTask != nil || viewModel.isShowingAbout || viewModel.isRunning || viewModel.lastRunReport != nil || viewModel.isShowingUpdateExperience
        #endif
    }

    var body: some View {
        ZStack {
            mainBackground

            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 22) {
                    if module.id == .smartCare {
                        HomeDashboardView(module: module)
                    } else {
                        ModuleSectionHeader(module: module)
                    }

                    if viewModel.isScanningModule && !viewModel.isRunning {
                        ScanStatusPanel(tint: module.theme.accent)
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        HStack(alignment: .firstTextBaseline) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(module.id == .smartCare ? localized("Recommended tools", "Aanbevolen hulpmiddelen") : localized("Tools on this page", "Hulpmiddelen op deze pagina"))
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundStyle(AppPalette.textPrimary)

                                Text(module.id == .smartCare
                                     ? localized("Start with the first-pass actions below, or jump straight into another area from the sidebar.", "Begin met de eerste controles hieronder, of spring direct naar een ander onderdeel via de navigatie links.")
                                     : localized("Start with the suggested actions, then open deeper tools only when needed.", "Begin met de aanbevolen acties en open diepere hulpmiddelen alleen wanneer dat nodig is."))
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(AppPalette.textTertiary)
                            }

                            Spacer()

                            if viewModel.isRunning {
                                Label(localized("Running ", "Bezig met ") + currentTaskTitle.appLocalized, systemImage: "bolt.fill")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(AppPalette.textPrimary)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule()
                                            .fill(Color.white.opacity(0.08))
                                    )
                            } else {
                                HStack(spacing: 10) {
                                    if module.id == .files {
                                        Button(localized("Choose folders", "Mappen kiezen")) {
                                            viewModel.chooseFileAccessFolders()
                                        }
                                        .buttonStyle(SecondaryGlassButtonStyle())
                                    }

                                    Button(localized("Scan this page", "Deze pagina scannen")) {
                                        Task {
                                            await viewModel.scanCurrentModule()
                                        }
                                    }
                                    .buttonStyle(SecondaryGlassButtonStyle())
                                }
                            }
                        }

                        if module.id == .files {
                            FileAccessPanel(tint: module.theme.accent)
                        }

                        LazyVStack(spacing: 16) {
                            ForEach(Array(tasks.enumerated()), id: \.element.id) { index, task in
                                TaskCard(
                                    task: task,
                                    module: module,
                                    index: index
                                )
                            }
                        }
                    }

                    if viewModel.shouldShowActivityConsole {
                        ActivityConsole(tint: module.theme.accent)
                    }
                }
                .padding(30)
            }
            .appScrollIndicators()
            .blur(radius: overlayIsVisible ? 14 : 0)
            .scaleEffect(overlayIsVisible ? 0.985 : 1)
            .opacity(overlayIsVisible ? 0.42 : 1)
            .animation(.spring(response: 0.42, dampingFraction: 0.88), value: overlayIsVisible)

            if let reviewTask {
                TaskReviewWorkspace(
                    task: reviewTask,
                    module: MaintenanceCatalog.module(for: reviewTask.moduleID)
                )
                .padding(24)
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }

            if viewModel.isShowingAbout && !viewModel.isRunning {
                AboutWorkspace(module: module)
                    .padding(24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            if let report = viewModel.lastRunReport, !viewModel.isRunning {
                RunCompletionWorkspace(report: report, module: module)
                    .padding(24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            if viewModel.isShowingUpdateExperience && !viewModel.isRunning {
                Color.black.opacity(0.24)
                    .ignoresSafeArea()
                    .transition(.opacity)

                UpdateExperienceOverlay(module: module)
                    .padding(24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            #if DEVELOPER_BUILD
            if viewModel.isShowingDeveloperPanel && !viewModel.isRunning {
                Color.black.opacity(0.22)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.closeDeveloperPanel()
                    }
                    .transition(.opacity)

                DeveloperPreviewWorkspace(module: module)
                    .padding(24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            #endif

            if viewModel.isRunning {
                RunExperienceOverlay(module: module)
                    .padding(24)
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
        }
        .animation(.spring(response: 0.42, dampingFraction: 0.88), value: viewModel.reviewTaskID)
        .animation(.easeInOut(duration: 0.28), value: viewModel.isRunning)
    }

    private var mainBackground: some View {
        let tone = visualTone(for: module.id)

        return ZStack {
            LinearGradient(
                colors: [
                    tone.headerTop.opacity(0.10),
                    tone.headerBottom.opacity(0.02),
                    Color.black.opacity(0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottom
            )

            Circle()
                .fill(tone.glowPrimary.opacity(0.10))
                .frame(width: 420, height: 420)
                .blur(radius: 48)
                .offset(x: 260, y: -260)

            Circle()
                .fill(tone.glowSecondary.opacity(0.08))
                .frame(width: 360, height: 360)
                .blur(radius: 52)
                .offset(x: -220, y: 260)
        }
    }
}

private struct UpdateExperienceOverlay: View {
    @EnvironmentObject private var viewModel: AppViewModel
    let module: MaintenanceModule

    private var offer: AppUpdateOffer? {
        viewModel.availableUpdateOffer
    }

    private var installState: AppUpdateInstallState {
        viewModel.updateInstallState
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            Rectangle()
                .fill(Color.white.opacity(0.07))
                .frame(height: 1)

            if let offer {
                promptBody(for: offer)
            } else {
                installBody
            }
        }
        .frame(maxWidth: 680)
        .background(
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            module.theme.top.opacity(0.96),
                            module.theme.bottom.opacity(0.94),
                            Color.black.opacity(0.80)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 34, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
        )
        .shadow(color: module.theme.accent.opacity(0.24), radius: 40, y: 20)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(module.theme.accent.opacity(0.18))
                    .frame(width: 68, height: 68)

                Image(systemName: installState.isPresented ? "arrow.down.circle.fill" : "sparkles")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(AppPalette.textPrimary)
            }

            VStack(alignment: .leading, spacing: 6) {
                if let offer {
                    Text(localized("New version available", "Nieuwe versie beschikbaar"))
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(AppPalette.textPrimary)

                    Text(localized("Version \(offer.version) is ready to install.", "Versie \(offer.version) staat klaar om te installeren."))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppPalette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text(viewModel.updateInstallTitle.appLocalized)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(AppPalette.textPrimary)

                    Text(viewModel.updateInstallDetail.appLocalized)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(installState.isFailure ? AppPalette.error.opacity(0.96) : AppPalette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 12)

            if offer != nil {
                Button(localized("Later", "Later")) {
                    viewModel.dismissAvailableUpdateOffer()
                }
                .buttonStyle(SecondaryGlassButtonStyle())
            } else if installState.isFailure {
                Button(localized("Close", "Sluiten")) {
                    viewModel.dismissUpdateInstallState()
                }
                .buttonStyle(SecondaryGlassButtonStyle())
            }
        }
        .padding(28)
    }

    private func promptBody(for offer: AppUpdateOffer) -> some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 12) {
                Text(localized("What changed", "Wat is er gewijzigd"))
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(AppPalette.textTertiary)
                    .textCase(.uppercase)

                ScrollView(.vertical, showsIndicators: true) {
                    Text(offer.notes.appLocalized)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppPalette.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxHeight: 210)
                .appScrollIndicators()
            }

            HStack(spacing: 14) {
                Button {
                    viewModel.installAvailableUpdate()
                } label: {
                    Label(localized("Update now", "Nu bijwerken"), systemImage: "arrow.down.circle.fill")
                        .frame(minWidth: 190)
                }
                .buttonStyle(PrimaryAuraButtonStyle())

                if offer.downloadURL != nil {
                    Button(localized("Open download", "Download openen")) {
                        viewModel.openUpdateDownload()
                    }
                    .buttonStyle(SecondaryGlassButtonStyle())
                }
            }
        }
        .padding(28)
    }

    private var installBody: some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(localized("Update progress", "Updatevoortgang"))
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(AppPalette.textTertiary)
                        .textCase(.uppercase)

                    Spacer()

                    if let version = installState.version {
                        Text(version)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(AppPalette.textPrimary)
                    }
                }

                UpdateProgressBar(progress: installState.progressValue, tint: installState.isFailure ? AppPalette.error : module.theme.accent)

                Text(viewModel.updateInstallDetail.appLocalized)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(installState.isFailure ? AppPalette.error.opacity(0.96) : AppPalette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if installState.isFailure {
                HStack(spacing: 14) {
                    Button(localized("Try again", "Opnieuw proberen")) {
                        viewModel.dismissUpdateInstallState()
                        if viewModel.availableUpdateOffer != nil {
                            viewModel.installAvailableUpdate()
                        } else {
                            viewModel.checkForUpdates()
                        }
                    }
                    .buttonStyle(PrimaryAuraButtonStyle())

                    Button(localized("Open download", "Download openen")) {
                        viewModel.openUpdateDownload()
                    }
                    .buttonStyle(SecondaryGlassButtonStyle())
                }
            }
        }
        .padding(28)
    }
}

private struct UpdateProgressBar: View {
    let progress: Double
    let tint: Color

    var body: some View {
        GeometryReader { proxy in
            let width = max(proxy.size.width * max(0.04, min(progress, 1.0)), 16)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.08))

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                tint.opacity(0.86),
                                AppPalette.iceBlue.opacity(0.96)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: width)
                    .overlay(
                        Capsule()
                            .fill(Color.white.opacity(0.20))
                            .frame(width: max(34, width * 0.28))
                            .blur(radius: 8)
                            .padding(.leading, max(0, width - max(34, width * 0.28) - 8)),
                        alignment: .leading
                    )
            }
        }
        .frame(height: 16)
    }
}

private struct HomeDashboardView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    let module: MaintenanceModule

    var body: some View {
        let snapshot = LocalSystemSnapshot.current

        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(module.title.appLocalized)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(AppPalette.textPrimary)

                    Text(module.subtitle.appLocalized)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppPalette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                HStack(spacing: 8) {
                    Circle()
                        .fill(AppPalette.success)
                        .frame(width: 8, height: 8)
                        .shadow(color: AppPalette.success.opacity(0.5), radius: 4)

                    Text(localized("System ready", "Systeem klaar"))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppPalette.textSecondary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.06))
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                )
            }

            smartScanCard

            VStack(alignment: .leading, spacing: 14) {
                Text(localized("Quick stats", "Snelle status"))
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppPalette.textSecondary)

                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 12) {
                    compactStatCard(
                        title: localized("Free Disk", "Vrije schijf"),
                        value: snapshot.freeDisk,
                        subtitle: snapshot.osVersion,
                        icon: "internaldrive.fill",
                        tint: AppPalette.blueGlow
                    )

                    compactStatCard(
                        title: localized("Can Clean", "Kan opschonen"),
                        value: viewModel.selectedModuleEstimatedCleanup,
                        subtitle: viewModel.selectedModuleEstimatedCleanupCaption,
                        icon: "sparkles",
                        tint: AppPalette.pinkGlow
                    )

                    compactStatCard(
                        title: localized("Tools Ready", "Tools klaar"),
                        value: "\(viewModel.selectedModuleTasks.count)",
                        subtitle: localized("Available on this page", "Beschikbaar op deze pagina"),
                        icon: "square.grid.2x2.fill",
                        tint: AppPalette.success
                    )

                    compactStatCard(
                        title: localized("Uptime", "Uptime"),
                        value: snapshot.uptime,
                        subtitle: localized("Current session", "Huidige sessie"),
                        icon: "clock.fill",
                        tint: AppPalette.iceBlue
                    )
                }
            }

            VStack(alignment: .leading, spacing: 14) {
                Text(localized("Quick actions", "Snelle acties"))
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppPalette.textSecondary)

                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 12) {
                    quickActionCard(moduleID: .cleanup)
                    quickActionCard(moduleID: .files)
                    quickActionCard(moduleID: .applications)
                    quickActionCard(moduleID: .performance)
                }
            }
        }
    }

    private var smartScanCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .center, spacing: 20) {
                ZStack {
                    Circle()
                        .fill(module.theme.accent.opacity(0.10))
                        .frame(width: 112, height: 112)
                        .blur(radius: 18)

                    Circle()
                        .fill(Color.white.opacity(0.06))
                        .frame(width: 78, height: 78)
                        .overlay(
                            Circle()
                                .stroke(module.theme.accent.opacity(0.25), lineWidth: 1)
                        )

                    if viewModel.isScanningModule {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(module.theme.accent)
                    } else {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 30, weight: .medium))
                            .foregroundStyle(module.theme.accent)
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text(viewModel.isScanningModule ? localized("Scanning now", "Nu aan het scannen") : localized("Smart Scan", "Slimme scan"))
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppPalette.textPrimary)

                    Text(viewModel.isScanningModule
                         ? localized("Checking the main cleanup and maintenance areas before anything is changed.", "De belangrijkste opschoon- en onderhoudsgebieden worden eerst gecontroleerd voordat er iets verandert.")
                         : localized("Run a first pass across cleanup, files, applications, and performance to see where attention is needed.", "Voer eerst een controle uit over opschonen, bestanden, apps en prestaties om te zien waar aandacht nodig is."))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppPalette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 10) {
                        HeroTag(text: localized("\(viewModel.selectedTaskCount) selected", "\(viewModel.selectedTaskCount) geselecteerd"), tint: module.theme.accent)
                        HeroTag(text: viewModel.selectedModuleEstimatedCleanup, tint: AppPalette.pinkGlow)
                        HeroTag(text: localized("Uptime \(LocalSystemSnapshot.current.uptime)", "Uptime \(LocalSystemSnapshot.current.uptime)"), tint: AppPalette.iceBlue)
                    }
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: 12) {
                Button {
                    viewModel.runSmartCare()
                } label: {
                    Label(localized("Start Smart Scan", "Slimme scan starten"), systemImage: "play.fill")
                        .frame(minWidth: 184)
                }
                .buttonStyle(PrimaryAuraButtonStyle())
                .disabled(viewModel.isRunning)

                Button {
                    Task {
                        await viewModel.scanCurrentModule()
                    }
                } label: {
                    Label(localized("Analyze First", "Eerst analyseren"), systemImage: "magnifyingglass")
                        .frame(minWidth: 150)
                }
                .buttonStyle(SecondaryGlassButtonStyle())
                .disabled(viewModel.isRunning || viewModel.isScanningModule)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(28)
        .background(DarkPanelBackground(tint: module.theme.accent, isElevated: true))
    }

    private func compactStatCard(title: String, value: String, subtitle: String, icon: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(tint)

                Spacer()

                Circle()
                    .fill(tint.opacity(0.18))
                    .frame(width: 10, height: 10)
            }

            Text(title)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(AppPalette.textTertiary)
                .textCase(.uppercase)

            Text(value.appLocalized)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(AppPalette.textPrimary)

            Text(subtitle.appLocalized)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppPalette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(DarkPanelBackground(tint: tint, isElevated: false))
    }

    private func quickActionCard(moduleID: MaintenanceModuleID) -> some View {
        let targetModule = MaintenanceCatalog.module(for: moduleID)

        return Button {
            viewModel.selectModule(moduleID)
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: targetModule.symbolName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(targetModule.theme.accent)

                    Spacer()

                    Circle()
                        .fill(targetModule.theme.accent.opacity(0.22))
                        .frame(width: 10, height: 10)
                }

                Text(targetModule.title.appLocalized)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppPalette.textPrimary)

                Text(targetModule.eyebrow.appLocalized)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppPalette.textSecondary)
                    .lineLimit(2)
            }
        }
        .buttonStyle(.plain)
        .padding(16)
        .background(DarkPanelBackground(tint: targetModule.theme.accent, isElevated: false))
    }
}

private struct ModuleSectionHeader: View {
    @EnvironmentObject private var viewModel: AppViewModel
    let module: MaintenanceModule

    var body: some View {
        HStack(alignment: .top, spacing: 18) {
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(module.theme.accent.opacity(0.15))
                    .frame(width: 84, height: 84)

                Image(systemName: module.symbolName)
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(module.theme.accent)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(module.eyebrow.appLocalized.uppercased())
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .kerning(1.2)
                    .foregroundStyle(AppPalette.textTertiary)

                Text(module.title.appLocalized)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(AppPalette.textPrimary)

                Text(module.subtitle.appLocalized)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppPalette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 10) {
                    HeroTag(text: localized("\(viewModel.selectedTaskCount) selected", "\(viewModel.selectedTaskCount) geselecteerd"), tint: module.theme.accent)
                    HeroTag(text: viewModel.selectedModuleEstimatedCleanup, tint: AppPalette.pinkGlow)
                }
            }

            Spacer()
        }
        .padding(26)
        .background(DarkPanelBackground(tint: module.theme.accent, isElevated: true))
    }
}

private struct DashboardInfoPanel<Content: View>: View {
    let title: String
    let tint: Color
    let content: Content

    init(title: String, tint: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.tint = tint
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(AppPalette.textTertiary)
                .textCase(.uppercase)

            content
        }
        .padding(18)
        .background(DarkPanelBackground(tint: tint, isElevated: false))
    }
}

private struct DashboardValueRow: View {
    let label: String
    let value: String
    let tint: Color

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(tint.opacity(0.92))
                .frame(width: 8, height: 8)
                .padding(.top, 5)

            VStack(alignment: .leading, spacing: 3) {
                Text(label)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(AppPalette.textTertiary)
                    .textCase(.uppercase)

                Text(value.appLocalized)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppPalette.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct ModuleHeroArtwork: View {
    let module: MaintenanceModule
    let isAnimating: Bool

    var body: some View {
        switch module.id {
        case .smartCare:
            GenericHeroOrbScene(
                module: module,
                isAnimating: isAnimating,
                centerSymbol: "sparkles"
            )
        case .cleanup:
            CleanupHeroScene(module: module, isAnimating: isAnimating)
        case .protection:
            ProtectionHeroScene(module: module, isAnimating: isAnimating)
        case .performance:
            PerformanceHeroScene(module: module, isAnimating: isAnimating)
        case .applications:
            ApplicationsHeroScene(module: module, isAnimating: isAnimating)
        case .files:
            FilesHeroScene(module: module, isAnimating: isAnimating)
        case .spaceLens:
            SpaceLensHeroScene(module: module, isAnimating: isAnimating)
        }
    }
}

private struct GenericHeroOrbScene: View {
    let module: MaintenanceModule
    let isAnimating: Bool
    let centerSymbol: String

    var body: some View {
        ZStack {
            Circle()
                .stroke(module.theme.mist.opacity(0.22), lineWidth: 1)
                .frame(width: 220, height: 220)

            Circle()
                .stroke(module.theme.accent.opacity(0.22), lineWidth: 22)
                .frame(width: 112, height: 112)

            Circle()
                .fill(module.theme.accent.opacity(0.15))
                .frame(width: 168, height: 168)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.14), lineWidth: 1)
                )

            Circle()
                .fill(module.theme.mist.opacity(0.92))
                .frame(width: 20, height: 20)
                .offset(x: isAnimating ? 102 : -102, y: -24)

            Image(systemName: centerSymbol)
                .font(.system(size: 58, weight: .light))
                .foregroundStyle(Color.white.opacity(0.92))
        }
    }
}

private struct CleanupHeroScene: View {
    let module: MaintenanceModule
    let isAnimating: Bool

    var body: some View {
        ZStack {
            ForEach(0..<7, id: \.self) { index in
                Circle()
                    .fill(module.theme.accent.opacity(0.10 - Double(index) * 0.008))
                    .frame(width: CGFloat(68 + index * 26), height: CGFloat(68 + index * 26))
            }

            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [module.theme.accent.opacity(0.92), module.theme.top.opacity(0.82)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 190, height: 152)
                .rotationEffect(.degrees(isAnimating ? -4 : 4))

            Image(systemName: "trash.fill")
                .font(.system(size: 56, weight: .regular))
                .foregroundStyle(Color.white.opacity(0.94))
        }
    }
}

private struct ProtectionHeroScene: View {
    let module: MaintenanceModule
    let isAnimating: Bool

    var body: some View {
        ZStack {
            Circle()
                .stroke(module.theme.accent.opacity(0.18), lineWidth: 1)
                .frame(width: 220, height: 220)
            Circle()
                .stroke(module.theme.accent.opacity(0.18), lineWidth: 1)
                .frame(width: 164, height: 164)
            Circle()
                .stroke(module.theme.accent.opacity(0.18), lineWidth: 1)
                .frame(width: 108, height: 108)

            Circle()
                .trim(from: 0.08, to: 0.32)
                .stroke(module.theme.mist.opacity(0.9), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .frame(width: 216, height: 216)
                .rotationEffect(.degrees(isAnimating ? 190 : 10))

            Image(systemName: "shield.lefthalf.filled")
                .font(.system(size: 78, weight: .light))
                .foregroundStyle(module.theme.mist)
        }
    }
}

private struct PerformanceHeroScene: View {
    let module: MaintenanceModule
    let isAnimating: Bool

    var body: some View {
        ZStack {
            HStack(alignment: .bottom, spacing: 12) {
                ForEach(0..<6, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(module.theme.accent.opacity(0.30 + Double(index) * 0.08))
                        .frame(width: 24, height: CGFloat(48 + ((index % 3) * 30)))
                }
            }
            .offset(y: 34)

            Circle()
                .trim(from: 0.08, to: 0.92)
                .stroke(module.theme.mist.opacity(0.18), style: StrokeStyle(lineWidth: 16, lineCap: .round))
                .frame(width: 180, height: 180)

            Capsule()
                .fill(Color.white.opacity(0.88))
                .frame(width: 94, height: 8)
                .rotationEffect(.degrees(isAnimating ? -26 : -8))
                .offset(y: -8)

            Circle()
                .fill(Color.white)
                .frame(width: 18, height: 18)
                .offset(y: -8)
        }
    }
}

private struct ApplicationsHeroScene: View {
    let module: MaintenanceModule
    let isAnimating: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(module.theme.accent.opacity(0.26))
                .frame(width: 112, height: 112)
                .offset(x: -62, y: -24)
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(module.theme.mist.opacity(0.26))
                .frame(width: 112, height: 112)
                .offset(x: 62, y: -24)
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.12))
                .frame(width: 112, height: 112)
                .offset(y: 62)

            Image(systemName: "shippingbox.fill")
                .font(.system(size: 62, weight: .regular))
                .foregroundStyle(Color.white.opacity(0.94))
                .offset(y: isAnimating ? -6 : 4)
        }
    }
}

private struct FilesHeroScene: View {
    let module: MaintenanceModule
    let isAnimating: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(module.theme.accent.opacity(0.18))
                .frame(width: 240, height: 140)
                .offset(y: 18)

            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.10))
                .frame(width: 120, height: 150)
                .rotationEffect(.degrees(-8))
                .offset(x: -44, y: -10)

            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(module.theme.mist.opacity(0.16))
                .frame(width: 120, height: 150)
                .rotationEffect(.degrees(8))
                .offset(x: 44, y: -4)

            Image(systemName: "doc.on.doc.fill")
                .font(.system(size: 60, weight: .light))
                .foregroundStyle(Color.white.opacity(0.94))
                .offset(y: isAnimating ? -6 : 4)
        }
    }
}

private struct SpaceLensHeroScene: View {
    let module: MaintenanceModule
    let isAnimating: Bool

    var body: some View {
        ZStack {
            Circle()
                .stroke(module.theme.accent.opacity(0.18), lineWidth: 22)
                .frame(width: 178, height: 178)
            Circle()
                .stroke(module.theme.mist.opacity(0.18), lineWidth: 1)
                .frame(width: 236, height: 236)
            Circle()
                .stroke(module.theme.mist.opacity(0.18), lineWidth: 1)
                .frame(width: 120, height: 120)

            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.86))
                .frame(width: 86, height: 14)
                .rotationEffect(.degrees(isAnimating ? 42 : 32))
                .offset(x: 86, y: 84)

            Image(systemName: "scope")
                .font(.system(size: 68, weight: .light))
                .foregroundStyle(Color.white.opacity(0.94))
        }
    }
}

private struct HeroTag: View {
    let text: String
    let tint: Color

    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundStyle(AppPalette.textPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(tint.opacity(0.16))
                    .overlay(
                        Capsule()
                            .stroke(tint.opacity(0.22), lineWidth: 1)
                    )
            )
    }
}

private struct MetricCard: View {
    let title: String
    let value: String
    let caption: String
    let tint: Color

    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Capsule()
                .fill(tint)
                .frame(width: 44, height: 4)

            Text(title.appLocalized.uppercased())
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .kerning(1.3)
                .foregroundStyle(AppPalette.textTertiary)

            Text(value)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(AppPalette.textPrimary)

            Text(caption.appLocalized)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppPalette.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(DarkPanelBackground(tint: tint, isElevated: isHovered))
        .scaleEffect(isHovered ? 1.01 : 1)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.16)) {
                isHovered = hovering
            }
        }
    }
}

private struct RunExperienceOverlay: View {
    @EnvironmentObject private var viewModel: AppViewModel
    let module: MaintenanceModule
    @State private var progressGlow = false

    private var progressPercent: Int {
        Int(viewModel.runProgressFraction * 100)
    }

    private var recentEntries: [ActivityEntry] {
        Array(viewModel.activityEntries.prefix(3))
    }

    var body: some View {
        let tint = module.theme.accent

        ZStack {
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            module.theme.top.opacity(0.95),
                            module.theme.bottom.opacity(0.94),
                            Color.black.opacity(0.78)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 34, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )

            Circle()
                .fill(tint.opacity(0.22))
                .frame(width: 340, height: 340)
                .blur(radius: 56)
                .offset(x: 160, y: -120)

            Circle()
                .fill(AppPalette.iceBlue.opacity(0.16))
                .frame(width: 280, height: 280)
                .blur(radius: 70)
                .offset(x: -140, y: 120)

            VStack(alignment: .leading, spacing: 28) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(localized("Working", "Bezig"))
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .kerning(1.4)
                            .foregroundStyle(module.theme.mist.opacity(0.92))
                            .textCase(.uppercase)

                        Text(viewModel.runProgressTitle)
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundStyle(AppPalette.textPrimary)

                        Text(viewModel.runProgressDetail)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(AppPalette.textSecondary)
                    }

                    Spacer(minLength: 24)

                    VStack(alignment: .trailing, spacing: 14) {
                        #if DEVELOPER_BUILD
                        if viewModel.isPlaceboModeActive {
                            Button("Preview Tools") {
                                viewModel.reopenDeveloperPanel()
                            }
                            .buttonStyle(SecondaryGlassButtonStyle())
                        }
                        #endif

                        ZStack {
                            Circle()
                                .stroke(Color.white.opacity(0.10), lineWidth: 16)
                                .frame(width: 154, height: 154)

                            Circle()
                                .trim(from: 0, to: max(viewModel.runProgressFraction, 0.04))
                                .stroke(
                                    AngularGradient(
                                        colors: [AppPalette.iceBlue, tint, AppPalette.pinkGlow],
                                        center: .center
                                    ),
                                    style: StrokeStyle(lineWidth: 16, lineCap: .round)
                                )
                                .frame(width: 154, height: 154)
                                .rotationEffect(.degrees(-90))

                            Circle()
                                .stroke(tint.opacity(0.22), lineWidth: 1)
                                .frame(width: 168, height: 168)

                            Circle()
                                .fill(tint.opacity(progressGlow ? 0.22 : 0.12))
                                .frame(width: 86, height: 86)
                                .blur(radius: progressGlow ? 24 : 14)

                            VStack(spacing: 6) {
                                Text("\(progressPercent)%")
                                    .font(.system(size: 34, weight: .bold, design: .rounded))
                                    .foregroundStyle(AppPalette.textPrimary)
                                Text(localized("done", "klaar"))
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(AppPalette.textTertiary)
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(localized("Live progress", "Live voortgang"))
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(AppPalette.textPrimary)

                        Spacer()

                        Text(localized("\(viewModel.completedTaskCount) / \(max(viewModel.totalTaskCount, 1)) steps", "\(viewModel.completedTaskCount) / \(max(viewModel.totalTaskCount, 1)) stappen"))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(AppPalette.textTertiary)
                    }

                    GeometryReader { proxy in
                        let filledWidth = max(proxy.size.width * max(viewModel.runProgressFraction, 0.02), 18)

                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.07))

                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [AppPalette.iceBlue, tint, AppPalette.pinkGlow],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: filledWidth)
                                .shadow(color: tint.opacity(progressGlow ? 0.42 : 0.22), radius: progressGlow ? 16 : 10)
                                .overlay {
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    .clear,
                                                    Color.white.opacity(progressGlow ? 0.08 : 0.0),
                                                    Color.white.opacity(progressGlow ? 0.42 : 0.14),
                                                    .clear
                                                ],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: min(140, filledWidth))
                                        .offset(x: progressGlow ? max(filledWidth - 110, 0) : 0)
                                }
                                .overlay(alignment: .trailing) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.white.opacity(progressGlow ? 0.56 : 0.26))
                                            .frame(width: 28, height: 28)
                                            .blur(radius: progressGlow ? 12 : 6)

                                        Circle()
                                            .fill(Color.white.opacity(0.94))
                                            .frame(width: 12, height: 12)
                                    }
                                    .offset(x: -2)
                                }
                        }
                    }
                    .frame(height: 18)
                }

                HStack(spacing: 10) {
                    progressChip(text: module.title.appLocalized, tint: tint)
                    progressChip(
                        text: localized(
                            "\(viewModel.completedTaskCount) / \(max(viewModel.totalTaskCount, 1)) steps",
                            "\(viewModel.completedTaskCount) / \(max(viewModel.totalTaskCount, 1)) stappen"
                        ),
                        tint: AppPalette.iceBlue
                    )
                    progressChip(text: localized("Stay open", "Blijft open"), tint: AppPalette.pinkGlow)
                }

                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text(localized("Recent", "Recent"))
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(AppPalette.textPrimary)

                        Spacer()
                    }

                    VStack(spacing: 10) {
                        ForEach(recentEntries) { entry in
                            HStack(alignment: .top, spacing: 12) {
                                Circle()
                                    .fill(entry.isError ? AppPalette.error : tint)
                                    .frame(width: 10, height: 10)
                                    .padding(.top, 5)

                                VStack(alignment: .leading, spacing: 5) {
                                    HStack {
                                        Text(entry.title)
                                            .font(.system(size: 14, weight: .bold, design: .rounded))
                                            .foregroundStyle(AppPalette.textPrimary)

                                        Spacer()

                                        Text(entry.timestamp.formatted(date: .omitted, time: .standard))
                                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                                            .foregroundStyle(AppPalette.textTertiary)
                                    }

                                    Text(entry.detail)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(entry.isError ? AppPalette.error.opacity(0.94) : AppPalette.textSecondary)
                                        .lineLimit(3)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .fill(Color.white.opacity(0.05))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                                            .stroke(Color.white.opacity(0.07), lineWidth: 1)
                                    )
                            )
                        }
                    }
                }
            }
            .padding(32)
        }
        .shadow(color: tint.opacity(0.22), radius: 36, y: 20)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.15).repeatForever(autoreverses: true)) {
                progressGlow = true
            }
        }
    }

    private func progressChip(text: String, tint: Color) -> some View {
        Text(text.appLocalized)
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundStyle(AppPalette.textPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(tint.opacity(0.14))
                    .overlay(
                        Capsule()
                            .stroke(tint.opacity(0.18), lineWidth: 1)
                    )
            )
    }
}

private struct RunCompletionWorkspace: View {
    @EnvironmentObject private var viewModel: AppViewModel
    let report: RunCompletionReport
    let module: MaintenanceModule

    private var tint: Color {
        report.failureCount > 0 ? AppPalette.error : module.theme.accent
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 18) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(localized("Results", "Resultaten"))
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .kerning(1.4)
                        .foregroundStyle(module.theme.mist.opacity(0.92))
                        .textCase(.uppercase)

                    Text(report.title)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(AppPalette.textPrimary)

                    Text(report.summary.appLocalized)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppPalette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 12)

                VStack(alignment: .trailing, spacing: 10) {
                    Text(report.timestamp.formatted(date: .abbreviated, time: .shortened))
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundStyle(AppPalette.textTertiary)

                    Button(localized("Close", "Sluiten")) {
                        viewModel.dismissRunReport()
                    }
                    .buttonStyle(SecondaryGlassButtonStyle())
                }
            }
            .padding(28)

            Rectangle()
                .fill(Color.white.opacity(0.07))
                .frame(height: 1)

            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(spacing: 16) {
                        resultMetric(
                            title: localized("Done", "Klaar"),
                            value: "\(report.completedCount)",
                            tint: AppPalette.success
                        )
                        resultMetric(
                            title: localized("Skipped", "Overgeslagen"),
                            value: "\(report.skippedCount)",
                            tint: AppPalette.iceBlue
                        )
                        resultMetric(
                            title: localized("Issues", "Problemen"),
                            value: "\(report.failureCount)",
                            tint: report.failureCount > 0 ? AppPalette.error : tint
                        )
                    }

                    if report.failureCount > 0 {
                        Text(localized("A few items need attention. Open the details below for the exact reason.", "Een paar onderdelen vragen aandacht. Open hieronder de details voor de exacte reden."))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(AppPalette.error.opacity(0.92))
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(AppPalette.error.opacity(0.08))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                                            .stroke(AppPalette.error.opacity(0.18), lineWidth: 1)
                                    )
                            )
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text(localized("Task results", "Taakresultaten"))
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(AppPalette.textPrimary)

                        ForEach(report.tasks) { item in
                            RunCompletionTaskRow(task: item, tint: tint)
                        }
                    }
                }
                .padding(28)
            }
            .appScrollIndicators()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            module.theme.top.opacity(0.96),
                            module.theme.bottom.opacity(0.94),
                            Color.black.opacity(0.78)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 34, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
        )
        .shadow(color: tint.opacity(0.22), radius: 36, y: 20)
    }

    private func resultMetric(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.appLocalized.uppercased())
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .kerning(1.2)
                .foregroundStyle(AppPalette.textTertiary)

            Text(value)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(AppPalette.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(DarkPanelBackground(tint: tint, isElevated: true))
    }
}

private struct RunCompletionTaskRow: View {
    let task: RunTaskReport
    let tint: Color
    @State private var showsDetails = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text(task.title.appLocalized)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(AppPalette.textPrimary)

                Text(task.summary.appLocalized)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(summaryTint)
                    .fixedSize(horizontal: false, vertical: true)
            }

                Spacer(minLength: 10)

                StatusBadge(text: task.state.badgeText, tint: task.state.tint)
            }

            if let output = task.output, !output.isEmpty {
                Button(showsDetails ? localized("Hide details", "Details verbergen") : localized("Show details", "Details tonen")) {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        showsDetails.toggle()
                    }
                }
                .buttonStyle(SecondaryGlassButtonStyle())

                if showsDetails {
                    ScrollView(.vertical, showsIndicators: true) {
                        Text(output)
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundStyle(AppPalette.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                    }
                    .appScrollIndicators()
                    .frame(maxHeight: 160)
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(tint.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(tint.opacity(0.16), lineWidth: 1)
                            )
                    )
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.07), lineWidth: 1)
                )
        )
    }

    private var summaryTint: Color {
        switch task.state {
        case .failed:
            return AppPalette.error.opacity(0.94)
        default:
            return AppPalette.textSecondary
        }
    }
}

private struct ScanStatusPanel: View {
    let tint: Color

    var body: some View {
        HStack(spacing: 14) {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(tint)

            VStack(alignment: .leading, spacing: 3) {
                Text(localized("Checking this page", "Deze pagina wordt gecontroleerd"))
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(AppPalette.textPrimary)

                Text(localized("Looking for safe items to review first.", "Zoekt eerst naar veilige onderdelen om te bekijken."))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppPalette.textSecondary)
            }

            Spacer(minLength: 0)
        }
        .padding(18)
        .background(DarkPanelBackground(tint: tint, isElevated: false))
    }
}

private struct TaskComponentPreview: View {
    let components: [TaskScanComponent]
    let selectedIDs: Set<String>
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(localized("Review items", "Controle-onderdelen"))
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(AppPalette.textTertiary)
                .textCase(.uppercase)

            ForEach(Array(components.prefix(2))) { component in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: selectedIDs.contains(component.id) ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(selectedIDs.contains(component.id) ? tint : AppPalette.textTertiary)
                        .padding(.top, 2)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(component.title.appLocalized)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(AppPalette.textPrimary)

                        Text(component.detail.appLocalized)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(AppPalette.textTertiary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 8)

                    VStack(alignment: .trailing, spacing: 2) {
                        if let sizeText = formattedSize(component.reclaimableBytes) {
                            Text(sizeText)
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(AppPalette.textPrimary)
                        }

                        if let itemText = componentItemText(component.itemCount) {
                            Text(itemText)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(AppPalette.textTertiary)
                        }
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.white.opacity(0.04))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Color.white.opacity(0.06), lineWidth: 1)
                        )
                )
            }

            if components.count > 2 {
                Text(localized("+ \(components.count - 2) more part(s) in Review", "+ \(components.count - 2) extra onderdeel(en) in Controle"))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppPalette.textSecondary)
            }
        }
        .padding(.top, 4)
    }
}

private struct TaskOutputPreview: View {
    let output: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(localized("Result", "Resultaat"))
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(AppPalette.textTertiary)
                    .textCase(.uppercase)
            }

            ScrollView(.vertical, showsIndicators: true) {
                Text(output)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(AppPalette.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            .appScrollIndicators()
            .frame(maxHeight: 168)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(tint.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(tint.opacity(0.16), lineWidth: 1)
                    )
            )
        }
        .padding(.top, 4)
    }
}

private struct TaskCard: View {
    @EnvironmentObject private var viewModel: AppViewModel
    let task: MaintenanceTaskDefinition
    let module: MaintenanceModule
    let index: Int

    @State private var isHovered = false
    @State private var isVisible = false

    private var isRunning: Bool {
        viewModel.currentTaskID == task.id
    }

    private var hasExpandedContext: Bool {
        viewModel.scanFinding(for: task.id) != nil || viewModel.latestTaskOutput(for: task.id) != nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    module.theme.accent.opacity(0.26),
                                    Color.white.opacity(0.08)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 52, height: 52)

                    Image(systemName: task.symbolName)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(AppPalette.textPrimary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text(task.title.appLocalized)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(AppPalette.textPrimary)

                        StatusBadge(text: task.impact.title, tint: task.impact.tint)
                        StatusBadge(text: viewModel.state(for: task.id).badgeText, tint: viewModel.state(for: task.id).tint)

                        Spacer(minLength: 0)
                    }

                    Text(task.subtitle.appLocalized)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppPalette.textSecondary)
                        .lineLimit(1)

                    if !hasExpandedContext {
                        Text(task.detail.appLocalized)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(AppPalette.textTertiary)
                            .lineLimit(1)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    TaskScanSummary(state: viewModel.scanState(for: task.id))

                    if let finding = viewModel.scanFinding(for: task.id), !finding.components.isEmpty {
                        TaskComponentPreview(
                            components: finding.components,
                            selectedIDs: viewModel.reviewedSelection(for: task.id),
                            tint: module.theme.accent
                        )
                    }

                    if let output = viewModel.latestTaskOutput(for: task.id) {
                        TaskOutputPreview(output: output, tint: module.theme.accent)
                    }
                }
            }

            Rectangle()
                .fill(Color.white.opacity(0.07))
                .frame(height: 1)

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(localized("Include", "Meenemen"))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppPalette.textPrimary)
                    Text(task.estimatedTime.appLocalized)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(AppPalette.textTertiary)
                }

                Toggle(
                    "",
                    isOn: Binding(
                        get: { viewModel.isTaskEnabled(task.id) },
                        set: { viewModel.setTaskEnabled(task.id, enabled: $0) }
                    )
                )
                .labelsHidden()
                .toggleStyle(.switch)
                .tint(AppPalette.blueGlow)
                .disabled(viewModel.isRunning)

                Spacer(minLength: 0)

                Button {
                    viewModel.runTask(task)
                } label: {
                    Label(viewModel.actionTitle(for: task), systemImage: viewModel.isTaskReviewable(task) ? "slider.horizontal.3" : "play.fill")
                }
                .buttonStyle(TaskActionButtonStyle(tint: module.theme.accent))
                .disabled(viewModel.isRunning || viewModel.scanState(for: task.id) == .scanning)
            }
        }
        .padding(22)
        .background(
            DarkPanelBackground(
                tint: isRunning ? module.theme.accent : module.theme.top,
                isElevated: isHovered || isRunning
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(
                    isRunning ? module.theme.accent.opacity(0.46) : Color.white.opacity(0.08),
                    lineWidth: isRunning ? 1.2 : 1
                )
        )
        .scaleEffect(isHovered ? 1.008 : 1)
        .offset(y: isVisible ? 0 : 20)
        .opacity(isVisible ? 1 : 0.001)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.16)) {
                isHovered = hovering
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.86).delay(Double(index) * 0.035)) {
                isVisible = true
            }
        }
    }
}

private struct FileAccessPanel: View {
    @EnvironmentObject private var viewModel: AppViewModel
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(localized("Folder access", "Maptoegang"))
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(AppPalette.textPrimary)

                    Text(viewModel.managedFileAccessSummary)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppPalette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 12)

                HStack(spacing: 10) {
                    Button(localized("Choose folders", "Mappen kiezen")) {
                        viewModel.chooseFileAccessFolders()
                    }
                    .buttonStyle(SecondaryGlassButtonStyle())

                    if viewModel.hasManagedFileAccess {
                        Button(localized("Clear", "Wissen")) {
                            viewModel.clearFileAccessFolders()
                        }
                        .buttonStyle(SecondaryGlassButtonStyle())
                    }
                }
            }

            if !viewModel.managedFileAccessFolders.isEmpty {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 10),
                    GridItem(.flexible(), spacing: 10),
                    GridItem(.flexible(), spacing: 10)
                ], spacing: 10) {
                    ForEach(viewModel.managedFileAccessFolders) { folder in
                        VStack(alignment: .leading, spacing: 3) {
                            Text(folder.displayName)
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(AppPalette.textPrimary)

                            Text(folder.displayPath)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(AppPalette.textTertiary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(tint.opacity(0.08))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(tint.opacity(0.14), lineWidth: 1)
                                )
                        )
                    }
                }
            }
        }
        .padding(20)
        .background(DarkPanelBackground(tint: tint, isElevated: false))
    }
}

private struct TaskScanSummary: View {
    let state: TaskScanState

    var body: some View {
        switch state {
        case .idle:
            summaryRow(text: localized("Not checked yet.", "Nog niet gecontroleerd."), tint: AppPalette.textTertiary)
        case .scanning:
            summaryRow(text: localized("Checking now.", "Nu aan het controleren."), tint: AppPalette.iceBlue)
        case let .ready(finding):
            summaryRow(text: finding.message, tint: AppPalette.success)
        case let .unavailable(message):
            summaryRow(text: message, tint: AppPalette.textSecondary)
        }
    }

    private func summaryRow(text: String, tint: Color) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                .fill(tint.opacity(0.9))
                .frame(width: 7, height: 7)
                .padding(.top, 5)

                Text(text.appLocalized)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(tint)
                    .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 2)
    }
}

private struct StatusBadge: View {
    let text: String
    let tint: Color

    var body: some View {
        Text(text.appLocalized)
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundStyle(AppPalette.textPrimary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(tint.opacity(0.16))
                    .overlay(
                        Capsule()
                            .stroke(tint.opacity(0.18), lineWidth: 1)
                    )
            )
    }
}

#if DEVELOPER_BUILD
private struct DeveloperPreviewWorkspace: View {
    @EnvironmentObject private var viewModel: AppViewModel
    let module: MaintenanceModule

    var body: some View {
        let tint = module.theme.accent

        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Preview Tools")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(AppPalette.textPrimary)

                    Text("Temporary debug controls for screenshots and videos. This panel is available in debug builds only.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppPalette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 12)

                Button("Close") {
                    viewModel.closeDeveloperPanel()
                }
                .buttonStyle(SecondaryGlassButtonStyle())
                .keyboardShortcut(.cancelAction)
            }
            .padding(28)

            Rectangle()
                .fill(Color.white.opacity(0.07))
                .frame(height: 1)

            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 18) {
                    previewCard(title: "Mode", tint: tint) {
                        Toggle(isOn: $viewModel.isPlaceboModeEnabled) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Placebo Mode")
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .foregroundStyle(AppPalette.textPrimary)
                                Text("Shows believable progress and results without changing the system.")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(AppPalette.textSecondary)
                            }
                        }
                        .toggleStyle(.switch)
                        .tint(AppPalette.blueGlow)
                    }

                    previewCard(title: "Language", tint: AppPalette.iceBlue) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Switch the interface language live for marketing captures.")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(AppPalette.textSecondary)

                            Picker("Interface Language", selection: $viewModel.debugLanguageOverride) {
                                ForEach(DebugLanguageOverride.allCases) { option in
                                    Text(option.title).tag(option)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                    }

                    previewCard(title: "Scene presets", tint: AppPalette.blueGlow) {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Jump straight to a polished app state for screenshots and videos.")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(AppPalette.textSecondary)

                            LazyVGrid(
                                columns: [
                                    GridItem(.flexible(), spacing: 12),
                                    GridItem(.flexible(), spacing: 12)
                                ],
                                spacing: 12
                            ) {
                                sceneButton(
                                    title: "Ready State",
                                    subtitle: "Load sample scan results for the current page.",
                                    tint: tint,
                                    action: viewModel.prepareDeveloperOverviewScene
                                )

                                sceneButton(
                                    title: "Update Card",
                                    subtitle: "Show a richer update available state in the sidebar.",
                                    tint: AppPalette.iceBlue,
                                    action: viewModel.prepareDeveloperUpdateScene
                                )

                                sceneButton(
                                    title: "Review Flow",
                                    subtitle: "Open a believable review screen with safe sample data.",
                                    tint: AppPalette.success,
                                    action: viewModel.prepareDeveloperReviewScene
                                )

                                sceneButton(
                                    title: "About Page",
                                    subtitle: "Open the branded About workspace instantly.",
                                    tint: AppPalette.pinkGlow,
                                    action: viewModel.prepareDeveloperAboutScene
                                )

                                sceneButton(
                                    title: "Progress Overlay",
                                    subtitle: "Freeze a full-page progress state for screenshots.",
                                    tint: module.theme.mist,
                                    action: viewModel.prepareDeveloperProgressScene
                                )

                                sceneButton(
                                    title: "Play Demo Run",
                                    subtitle: "Animate a harmless placebo run for video capture.",
                                    tint: AppPalette.violetGlow,
                                    action: viewModel.playDeveloperDemoRun
                                )
                            }
                        }
                    }

                    previewCard(title: "Quick reset", tint: AppPalette.pinkGlow) {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Reset preview state")
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .foregroundStyle(AppPalette.textPrimary)
                                Text("Clears fake activity, fake updates, and temporary preview results.")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(AppPalette.textSecondary)
                            }

                            Spacer(minLength: 12)

                            Button("Reset") {
                                viewModel.resetDeveloperPreview()
                            }
                            .buttonStyle(TaskActionButtonStyle(tint: tint))
                        }
                    }

                    previewCard(title: "Tip", tint: module.theme.mist) {
                        Text("Use the sidebar Preview Tools button if the hidden double-click gesture is inconvenient.")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(AppPalette.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(28)
            }
            .appScrollIndicators()
        }
        .frame(maxWidth: 760, maxHeight: 760, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            module.theme.top.opacity(0.96),
                            module.theme.bottom.opacity(0.94),
                            Color.black.opacity(0.78)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 34, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
        )
        .shadow(color: tint.opacity(0.22), radius: 36, y: 20)
        .onExitCommand {
            viewModel.closeDeveloperPanel()
        }
    }

    @ViewBuilder
    private func previewCard<Content: View>(title: String, tint: Color, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(AppPalette.textPrimary)
                .textCase(.uppercase)

            content()
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(tint.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(tint.opacity(0.16), lineWidth: 1)
                )
        )
    }

    private func sceneButton(title: String, subtitle: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(AppPalette.textPrimary)

                Text(subtitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppPalette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)

                HStack(spacing: 6) {
                    Text("Open")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                    Image(systemName: "arrow.up.right.circle.fill")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(tint)
            }
            .frame(maxWidth: .infinity, minHeight: 112, alignment: .leading)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(tint.opacity(0.18), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
#endif

private struct AboutWorkspace: View {
    @EnvironmentObject private var viewModel: AppViewModel
    let module: MaintenanceModule

    var body: some View {
        let tint = module.theme.accent

        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 18) {
                HStack(spacing: 16) {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 92, height: 92)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(Color.white.opacity(0.10), lineWidth: 1)
                        )
                        .overlay {
                            BrandMarkArtwork()
                                .padding(14)
                        }

                    VStack(alignment: .leading, spacing: 8) {
                    Text(localized("About CleanMac Assistant", "Over CleanMac Assistant"))
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(AppPalette.textPrimary)

                        Text(viewModel.appVersionLabel)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(module.theme.mist.opacity(0.92))

                        Text(localized("CleanMac Assistant is your free Mac maintenance helper.", "CleanMac Assistant is uw gratis Mac-onderhoudsassistent."))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(AppPalette.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer(minLength: 12)

                Button(localized("Close", "Sluiten")) {
                    viewModel.closeAbout()
                }
                .buttonStyle(SecondaryGlassButtonStyle())
            }
            .padding(28)

            Rectangle()
                .fill(Color.white.opacity(0.07))
                .frame(height: 1)

            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 18) {
                    aboutCard(
                        title: localized("Why this app exists", "Waarom deze app bestaat"),
                        body: localized(
                            "An initiative from EasyComp Zeeland, your trusted partner for practical and accessible IT solutions. Why pay for expensive maintenance software when a clear, honest helper can do the essential work without hidden costs?",
                            "Een initiatief van EasyComp Zeeland, uw vertrouwde partner in slimme en toegankelijke IT-oplossingen. Waarom betalen voor dure onderhoudssoftware als een duidelijke en eerlijke assistent het belangrijkste werk ook zonder verborgen kosten kan doen?"
                        )
                    )
                    aboutCard(
                        title: localized("What it can do", "Wat het kan doen"),
                        body: localized(
                            "CleanMac Assistant helps keep your Mac clean, fast, and safe with tools for temporary file cleanup, cache refreshes, process monitoring, storage review, and maintenance guidance in one transparent interface.",
                            "CleanMac Assistant helpt uw Mac schoon, snel en veilig te houden met hulpmiddelen voor het verwijderen van tijdelijke bestanden, het opschonen van caches, het volgen van processen, het bekijken van opslaggebruik en duidelijke onderhoudshulp in één transparante interface."
                        )
                    )
                    aboutCard(
                        title: localized("Built with care", "Met zorg gemaakt"),
                        body: localized(
                            "This tool is designed with attention to detail, ease of use, and reliability by the EasyComp Zeeland team. Special thanks go to Homebrew, ClamAV, and the open-source tools that help make CleanMac Assistant possible.",
                            "Deze tool is ontwikkeld met oog voor detail, gebruiksgemak en betrouwbaarheid door het team van EasyComp Zeeland. Speciale dank gaat uit naar Homebrew, ClamAV en alle open-source projecten die CleanMac Assistant mogelijk maken."
                        )
                    )
                    aboutCard(
                        title: localized("Changelog", "Changelog"),
                        body: localized(
                            "Version 1.0.10 adds a calmer folder-access flow to Files, so large-file, duplicate, and installer scans no longer trigger repeated macOS prompts for every location.",
                            "Versie 1.0.10 voegt een rustigere maptoegangsflow toe aan Bestanden, zodat scans op grote bestanden, duplicaten en installers niet meer voor elke locatie opnieuw macOS-meldingen oproepen."
                        )
                    )
                    aboutCard(
                        title: localized("Links and support", "Links en ondersteuning"),
                        body: localized(
                            "More info: https://easycompzeeland.nl\nRemote support via ECZQHOA: https://easycompzeeland.nl/en/services/hulp-op-afstand\nWebsite: https://cleanmac-assistant.easycompzeeland.nl\nCleanMac Assistant believes smart technology should stay accessible for everyone.",
                            "Meer info: https://easycompzeeland.nl\nOndersteuning via ECZQHOA: https://easycompzeeland.nl/en/services/hulp-op-afstand\nWebsite: https://cleanmac-assistant.easycompzeeland.nl\nCleanMac Assistant vindt dat slimme technologie voor iedereen toegankelijk hoort te blijven."
                        )
                    )
                }
                .padding(28)
            }
            .appScrollIndicators()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            module.theme.top.opacity(0.96),
                            module.theme.bottom.opacity(0.94),
                            Color.black.opacity(0.78)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 34, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
        )
        .shadow(color: tint.opacity(0.22), radius: 36, y: 20)
    }

    @ViewBuilder
    private func aboutCard(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.appLocalized)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(AppPalette.textPrimary)
                .textCase(.uppercase)

            Text(body.appLocalized)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppPalette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.07), lineWidth: 1)
                )
        )
    }
}

private struct TaskReviewWorkspace: View {
    @EnvironmentObject private var viewModel: AppViewModel
    let task: MaintenanceTaskDefinition
    let module: MaintenanceModule

    private var finding: TaskScanFinding? {
        viewModel.scanFinding(for: task.id)
    }

    private var components: [TaskScanComponent] {
        viewModel.reviewComponents(for: task.id)
    }

    var body: some View {
        let tint = module.theme.accent
        let confirmation = viewModel.activeReviewConfirmation

        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(localized("Review Workspace", "Controlewerkruimte"))
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .kerning(1.4)
                        .foregroundStyle(module.theme.mist.opacity(0.92))
                        .textCase(.uppercase)

                    Text(task.title.appLocalized)
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(AppPalette.textPrimary)

                    Text(localized("Review your selection before you start.", "Bekijk uw selectie voordat u start."))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppPalette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 12)

                VStack(alignment: .trailing, spacing: 8) {
                    StatusBadge(text: task.impact.title, tint: task.impact.tint)
                    StatusBadge(text: viewModel.selectedReviewSummary, tint: tint)

                    Button(localized("Close", "Sluiten")) {
                        viewModel.closeReview()
                    }
                    .buttonStyle(SecondaryGlassButtonStyle())
                }
            }
            .padding(28)

            Rectangle()
                .fill(Color.white.opacity(0.07))
                .frame(height: 1)

            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 20) {
                    reviewInfoCard(
                        title: task.subtitle,
                        message: task.detail,
                        tint: tint
                    )

                    if let finding {
                        reviewInfoCard(
                            title: localized("What the scan found", "Wat de scan heeft gevonden"),
                            message: finding.message,
                            tint: tint
                        )
                    }

                    if viewModel.usesInstalledApplicationPicker(for: task) {
                        InstalledApplicationPickerCard(task: task, tint: tint)
                    } else if let prompt = task.prompt {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(prompt.title.appLocalized)
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(AppPalette.textPrimary)

                            Text(prompt.message.appLocalized)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(AppPalette.textSecondary)

                            TextField(prompt.placeholder.appLocalized, text: $viewModel.reviewInputText)
                                .textFieldStyle(.plain)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(AppPalette.textPrimary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(Color.white.opacity(0.07))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                                        )
                                )
                        }
                    }

                    if !components.isEmpty {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(localized("Choose exactly what to clean", "Kies precies wat u wilt opschonen"))
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundStyle(AppPalette.textPrimary)

                                Text(localized("You can leave parts unchecked if you want to keep that data on your Mac.", "U kunt onderdelen uitgevinkt laten als u die gegevens op uw Mac wilt behouden."))
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(AppPalette.textSecondary)
                            }

                            Spacer(minLength: 12)

                            Button(localized("Safe pick", "Veilige keuze")) {
                                viewModel.useSuggestedReviewComponents()
                            }
                            .buttonStyle(SecondaryGlassButtonStyle())

                            Button(localized("Select all", "Alles selecteren")) {
                                viewModel.selectAllReviewComponents()
                            }
                            .buttonStyle(SecondaryGlassButtonStyle())
                        }

                        VStack(spacing: 12) {
                            ForEach(components) { component in
                                ReviewComponentRow(
                                    component: component,
                                    isSelected: viewModel.isReviewComponentSelected(component.id),
                                    tint: tint
                                ) { isSelected in
                                    viewModel.setReviewComponent(component.id, selected: isSelected)
                                }
                            }
                        }
                    }

                    if let confirmation {
                        reviewInfoCard(
                            title: confirmation.title,
                            message: confirmation.message,
                            tint: confirmation.style == .critical ? AppPalette.error : tint
                        )
                    }
                }
                .padding(28)
            }
            .appScrollIndicators()

            Rectangle()
                .fill(Color.white.opacity(0.07))
                .frame(height: 1)

            HStack(spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(localized("Run summary", "Samenvatting"))
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(AppPalette.textTertiary)
                        .textCase(.uppercase)

                    Text(viewModel.selectedReviewSummary)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppPalette.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 12)

                Button(localized("Keep For Later", "Bewaren voor later")) {
                    viewModel.closeReview()
                }
                .buttonStyle(SecondaryGlassButtonStyle())

                Button((confirmation?.confirmTitle ?? (components.isEmpty ? localized("Run Task", "Taak uitvoeren") : localized("Run Selected", "Selectie uitvoeren"))).appLocalized) {
                    viewModel.runReviewTask()
                }
                .buttonStyle(TaskActionButtonStyle(tint: tint))
                .disabled(!viewModel.canRunActiveReview)
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            module.theme.top.opacity(0.96),
                            module.theme.bottom.opacity(0.94),
                            Color.black.opacity(0.78)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 34, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
        )
        .shadow(color: tint.opacity(0.22), radius: 36, y: 20)
    }

    @ViewBuilder
    private func reviewInfoCard(title: String, message: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.appLocalized)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(AppPalette.textPrimary)
                .textCase(.uppercase)

            Text(message.appLocalized)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppPalette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(tint.opacity(0.10))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(tint.opacity(0.18), lineWidth: 1)
                )
        )
    }
}

private struct InstalledApplicationPickerCard: View {
    @EnvironmentObject private var viewModel: AppViewModel
    let task: MaintenanceTaskDefinition
    let tint: Color

    private var selectedApplication: InstalledApplicationRecord? {
        viewModel.activeSelectedInstalledApplication
    }

    private var pickerTitle: String {
        switch task.id {
        case .uninstall:
            return localized("Choose an app to remove", "Kies een app om te verwijderen")
        case .reset:
            return localized("Choose an app to reset", "Kies een app om te resetten")
        default:
            return localized("Choose an installed app", "Kies een geïnstalleerde app")
        }
    }

    private var pickerMessage: String {
        switch task.id {
        case .uninstall:
            return localized("Installed apps are listed here so you can remove the exact app without typing its name.", "Geïnstalleerde apps staan hier in een lijst, zodat u precies de juiste app kunt verwijderen zonder de naam te typen.")
        case .reset:
            return localized("Pick the app whose saved settings should be cleared. Apps without a bundle identifier cannot be reset this way.", "Kies de app waarvan de opgeslagen instellingen moeten worden gewist. Apps zonder bundle-identifier kunnen op deze manier niet worden gereset.")
        default:
            return localized("Pick an installed app from the list below.", "Kies een geïnstalleerde app uit de lijst hieronder.")
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(pickerTitle)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(AppPalette.textPrimary)

            Text(pickerMessage)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppPalette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            TextField(localized("Search installed apps", "Geïnstalleerde apps zoeken"), text: $viewModel.applicationPickerQuery)
                .textFieldStyle(.plain)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppPalette.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white.opacity(0.07))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                )

            if let selectedApplication {
                HStack(spacing: 10) {
                    Image(nsImage: selectedApplication.icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(selectedApplication.name)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(AppPalette.textPrimary)

                        Text(selectedApplication.bundleIdentifier ?? selectedApplication.displayLocation)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(AppPalette.textTertiary)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 0)

                    StatusBadge(text: localized("Selected", "Geselecteerd"), tint: tint)
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(tint.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(tint.opacity(0.16), lineWidth: 1)
                        )
                )
            }

            if viewModel.isLoadingInstalledApplications {
                HStack(spacing: 12) {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(tint)

                    Text(localized("Loading installed apps…", "Geïnstalleerde apps laden…"))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppPalette.textSecondary)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Color.white.opacity(0.07), lineWidth: 1)
                        )
                )
            } else if viewModel.filteredInstalledApplications.isEmpty {
                Text(localized("No installed apps matched this search.", "Geen geïnstalleerde apps gevonden voor deze zoekopdracht."))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppPalette.textSecondary)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color.white.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(Color.white.opacity(0.07), lineWidth: 1)
                            )
                    )
            } else {
                ScrollView(.vertical, showsIndicators: true) {
                    LazyVStack(spacing: 10) {
                        ForEach(viewModel.filteredInstalledApplications) { app in
                            InstalledApplicationPickerRow(
                                app: app,
                                taskID: task.id,
                                isSelected: selectedApplication?.id == app.id,
                                tint: tint
                            )
                        }
                    }
                }
                .appScrollIndicators()
                .frame(maxHeight: 340)
            }
        }
    }
}

private struct InstalledApplicationPickerRow: View {
    @EnvironmentObject private var viewModel: AppViewModel
    let app: InstalledApplicationRecord
    let taskID: MaintenanceTaskID
    let isSelected: Bool
    let tint: Color

    private var canSelect: Bool {
        switch taskID {
        case .reset:
            return app.bundleIdentifier?.isEmpty == false
        default:
            return true
        }
    }

    var body: some View {
        Button {
            guard canSelect else { return }
            viewModel.selectInstalledApplication(app, for: taskID)
        } label: {
            HStack(alignment: .center, spacing: 14) {
                Image(nsImage: app.icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .shadow(color: .black.opacity(0.18), radius: 4, y: 2)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(app.name)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(AppPalette.textPrimary)

                        if let version = app.version, !version.isEmpty {
                            Text("v\(version)")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(AppPalette.textTertiary)
                        }
                    }

                    Text(app.bundleIdentifier ?? localized("No bundle identifier available", "Geen bundle-identifier beschikbaar"))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(canSelect ? AppPalette.textSecondary : AppPalette.error.opacity(0.88))
                        .lineLimit(1)

                    Text(app.displayLocation)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(AppPalette.textTertiary)
                        .lineLimit(1)
                }

                Spacer(minLength: 10)

                if isSelected {
                    StatusBadge(text: localized("Selected", "Geselecteerd"), tint: tint)
                } else if !canSelect {
                    StatusBadge(text: localized("No bundle ID", "Geen bundle-ID"), tint: AppPalette.error)
                } else {
                    Text(localized("Choose", "Kiezen"))
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(tint)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(tint.opacity(0.12))
                                .overlay(
                                    Capsule()
                                        .stroke(tint.opacity(0.18), lineWidth: 1)
                                )
                        )
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(isSelected ? tint.opacity(0.10) : Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(isSelected ? tint.opacity(0.20) : Color.white.opacity(0.07), lineWidth: 1)
                    )
            )
            .opacity(canSelect ? 1 : 0.88)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(localized("Reveal in Finder", "Toon in Finder")) {
                viewModel.revealInstalledApplication(app)
            }
        }
    }
}

private struct ReviewComponentRow: View {
    let component: TaskScanComponent
    let isSelected: Bool
    let tint: Color
    let onToggle: (Bool) -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Button {
                onToggle(!isSelected)
            } label: {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(isSelected ? tint : AppPalette.textTertiary)
            }
            .buttonStyle(.plain)
            .padding(.top, 2)

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(component.title.appLocalized)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(AppPalette.textPrimary)

                        Text(component.detail.appLocalized)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(AppPalette.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 12)

                    VStack(alignment: .trailing, spacing: 4) {
                        if let sizeText = formattedSize(component.reclaimableBytes) {
                            Text(sizeText)
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(AppPalette.textPrimary)
                        }

                        if let itemText = componentItemText(component.itemCount) {
                            Text(itemText)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(AppPalette.textTertiary)
                        }
                    }
                }

                Text(componentActionText(component))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(isSelected ? tint.opacity(0.96) : AppPalette.textTertiary)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(isSelected ? 0.08 : 0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(isSelected ? tint.opacity(0.26) : Color.white.opacity(0.07), lineWidth: 1)
                )
        )
    }
}

private struct ActivityConsole: View {
    @EnvironmentObject private var viewModel: AppViewModel
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(localized("Recent activity", "Recente activiteit"))
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(AppPalette.textPrimary)

                Spacer()

                Text(localized("Recent first", "Nieuwste eerst"))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppPalette.textSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.06))
                    )
            }

            VStack(spacing: 10) {
                ForEach(viewModel.activityEntries.prefix(4)) { entry in
                    VStack(alignment: .leading, spacing: 7) {
                        HStack {
                            Circle()
                                .fill(entry.isError ? AppPalette.error : AppPalette.success)
                                .frame(width: 8, height: 8)

                            Text(entry.title.appLocalized)
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(AppPalette.textPrimary)

                            Spacer()

                            Text(entry.timestamp.formatted(date: .omitted, time: .standard))
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundStyle(AppPalette.textTertiary)
                        }

                        Text(entry.detail.appLocalized)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(entry.isError ? AppPalette.error.opacity(0.94) : AppPalette.textSecondary)
                            .lineLimit(3)
                            .lineSpacing(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color.white.opacity(0.04))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
                            )
                    )
                }
            }
        }
        .padding(22)
        .background(DarkPanelBackground(tint: tint, isElevated: false))
    }
}

private func formattedSize(_ byteCount: Int64?) -> String? {
    guard let byteCount, byteCount > 0 else { return nil }
    let formatter = ByteCountFormatter()
    formatter.allowedUnits = [.useKB, .useMB, .useGB, .useTB]
    formatter.countStyle = .file
    formatter.isAdaptive = true
    return formatter.string(fromByteCount: byteCount)
}

private func componentItemText(_ itemCount: Int?) -> String? {
    guard let itemCount, itemCount > 0 else { return nil }
    return itemCount == 1 ? localized("1 item", "1 item") : localized("\(itemCount) items", "\(itemCount) items")
}

private func componentActionText(_ component: TaskScanComponent) -> String {
    switch component.cleanupAction {
    case .none:
        return localized("This part is shown for review only, so nothing is deleted until you open it yourself.", "Dit onderdeel wordt alleen ter controle getoond, dus er wordt niets verwijderd totdat u het zelf opent.")
    case .removePath:
        return localized("Will remove this selected file or data set from your Mac.", "Verwijdert dit geselecteerde bestand of deze dataset van uw Mac.")
    case let .removePaths(paths, _):
        return localized("Will remove \(paths.count) selected file items from this part.", "Verwijdert \(paths.count) geselecteerde bestandsitems uit dit onderdeel.")
    case let .removeDirectoryContents(path, _):
        return localized("Will remove accessible items inside \(path) and skip protected ones safely.", "Verwijdert toegankelijke onderdelen in \(path) en slaat beschermde onderdelen veilig over.")
    case .shell:
        return localized("Will run the cleanup command only for this selected part.", "Voert het opschooncommando alleen uit voor dit geselecteerde onderdeel.")
    case .sqlite:
        return localized("Will erase the saved local history records for this part.", "Verwijdert de opgeslagen lokale geschiedenisgegevens voor dit onderdeel.")
    }
}

private struct DarkPanelBackground: View {
    let tint: Color
    let isElevated: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(isElevated ? 0.085 : 0.06),
                        Color.white.opacity(isElevated ? 0.055 : 0.04)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color.white.opacity(isElevated ? 0.1 : 0.06), lineWidth: 1)
            )
            .shadow(color: tint.opacity(isElevated ? 0.16 : 0.08), radius: isElevated ? 24 : 16, y: isElevated ? 14 : 8)
    }
}

private struct PrimaryAuraButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .bold, design: .rounded))
            .foregroundStyle(Color(red: 0.15, green: 0.22, blue: 0.33))
            .padding(.horizontal, 18)
            .padding(.vertical, 13)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                AppPalette.iceBlue.opacity(configuration.isPressed ? 0.88 : 1.0),
                                AppPalette.blueGlow.opacity(configuration.isPressed ? 0.76 : 0.9)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.32), lineWidth: 1)
                    )
            )
            .shadow(color: AppPalette.blueGlow.opacity(0.24), radius: 18, y: 10)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
    }
}

private struct SecondaryGlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .foregroundStyle(AppPalette.textPrimary)
            .padding(.horizontal, 18)
            .padding(.vertical, 13)
            .background(
                Capsule()
                    .fill(Color.white.opacity(configuration.isPressed ? 0.11 : 0.08))
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.14), lineWidth: 1)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
    }
}

private struct SidebarUtilityButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(configuration.isPressed ? 0.1 : 0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
    }
}

private struct TaskActionButtonStyle: ButtonStyle {
    let tint: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(AppPalette.textPrimary)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                tint.opacity(configuration.isPressed ? 0.6 : 0.74),
                                AppPalette.blueGlow.opacity(configuration.isPressed ? 0.5 : 0.66)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.16), lineWidth: 1)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
    }
}
