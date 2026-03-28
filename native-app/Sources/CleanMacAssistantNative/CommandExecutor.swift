import Foundation

struct TaskExecutionRequest {
    let input: String?
    let selectedComponents: [TaskScanComponent]
}

struct CommandExecutionResult {
    let success: Bool
    let summary: String
    let output: String
}

private struct ProcessOutput {
    let exitCode: Int32
    let stdout: String
    let stderr: String

    var combined: String {
        [stdout.trimmingCharacters(in: .whitespacesAndNewlines), stderr.trimmingCharacters(in: .whitespacesAndNewlines)]
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
    }

    var isSuccess: Bool {
        exitCode == 0
    }
}

actor MaintenanceCommandExecutor {
    private let shellBootstrap = "PATH=/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin; export PATH; "
    private let byteFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB, .useTB]
        formatter.countStyle = .file
        formatter.isAdaptive = true
        return formatter
    }()

    func run(task: MaintenanceTaskDefinition, request: TaskExecutionRequest) async -> CommandExecutionResult {
        if !request.selectedComponents.isEmpty {
            return await runSelectedComponents(request.selectedComponents, task: task)
        }

        switch task.command {
        case .dependencyCheck:
            return await runDependencyCheck()

        case let .shell(command, requiresAdmin):
            return await runMappedShellCommand(command, task: task, requiresAdmin: requiresAdmin)

        case let .inlineReport(command):
            return await runInlineReport(command, task: task)

        case let .openTerminal(command):
            return await runTerminalCommand(command, task: task)

        case .uninstallApplication:
            guard let input = request.input, !input.isEmpty else {
                return CommandExecutionResult(success: false, summary: localized("No app name was entered.", "Er is geen appnaam ingevuld."), output: "")
            }
            let appPath = "/Applications/\(input).app"
            let exists = await runShell("test -d \(shellQuote(appPath))", requiresAdmin: false)
            guard exists.isSuccess else {
                return CommandExecutionResult(success: false, summary: localized("\(input).app was not found in /Applications.", "\(input).app is niet gevonden in /Applications."), output: exists.combined)
            }
            let result = await runShell("rm -rf \(shellQuote(appPath))", requiresAdmin: true)
            return translate(result, success: localized("\(input).app was removed.", "\(input).app is verwijderd."), failure: localized("Failed to remove \(input).app.", "Het verwijderen van \(input).app is mislukt."))

        case .resetPreferences:
            guard let input = request.input, !input.isEmpty else {
                return CommandExecutionResult(success: false, summary: localized("No bundle identifier was entered.", "Er is geen bundle-identifier ingevuld."), output: "")
            }
            let result = await runShell("defaults delete \(shellQuote(input))", requiresAdmin: false)
            return translate(result, success: localized("Preferences for \(input) were reset.", "De voorkeuren voor \(input) zijn gereset."), failure: localized("Failed to reset preferences for \(input).", "Het resetten van de voorkeuren voor \(input) is mislukt."))
        }
    }

    private func runSelectedComponents(_ components: [TaskScanComponent], task: MaintenanceTaskDefinition) async -> CommandExecutionResult {
        var outputs: [String] = []
        var failures = 0

        for component in components {
            guard let action = component.cleanupAction else { continue }

            let result: ProcessOutput
            switch action {
            case let .removePath(path, requiresAdmin):
                result = await runShell("rm -rf \(shellQuote(path))", requiresAdmin: requiresAdmin)
            case let .removePaths(paths, requiresAdmin):
                let joined = paths.map(shellQuote).joined(separator: " ")
                result = await runShell("rm -rf \(joined)", requiresAdmin: requiresAdmin)
            case let .shell(command, requiresAdmin):
                result = await runShell(command, requiresAdmin: requiresAdmin)
            case let .sqlite(databasePath, statement):
                let command = "sqlite3 \(shellQuote(databasePath)) \(shellQuote(statement))"
                result = await runShell(command, requiresAdmin: false)
            }

            if result.isSuccess {
                outputs.append("\(component.title.appLocalized): \(localized("cleaned", "opgeschoond")) \(cleanupScope(for: component)).")
            } else {
                failures += 1
                outputs.append("\(component.title.appLocalized): \(localized("failed", "mislukt")).\n\(result.combined)")
            }
        }

        if failures == 0 {
            return CommandExecutionResult(
                success: true,
                summary: localized("\(task.title.appLocalized) finished for the selected parts.", "\(task.title.appLocalized) is afgerond voor de geselecteerde onderdelen."),
                output: outputs.joined(separator: "\n\n")
            )
        }

        return CommandExecutionResult(
            success: false,
            summary: localized("\(task.title.appLocalized) finished with issues in one or more selected parts.", "\(task.title.appLocalized) is afgerond met problemen in een of meer geselecteerde onderdelen."),
            output: outputs.joined(separator: "\n\n")
        )
    }

    private func runDependencyCheck() async -> CommandExecutionResult {
        guard let brewPath = await resolveCommandPath("brew") else {
            return CommandExecutionResult(
                success: false,
                summary: localized("Homebrew is not installed.", "Homebrew is niet geïnstalleerd."),
                output: localized("Install Homebrew from brew.sh before running dependency setup.", "Installeer eerst Homebrew via brew.sh voordat u de afhankelijkheden controleert.")
            )
        }

        var notes: [String] = [localized("Using Homebrew at \(brewPath).", "Homebrew wordt gebruikt vanaf \(brewPath).")]

        let clamResult = await ensureCommand(toolName: "clamscan", formulaName: "clamav", brewPath: brewPath, friendlyName: "ClamAV")
        notes.append(claimer(for: "ClamAV", result: clamResult))
        if !clamResult.success {
            return CommandExecutionResult(success: false, summary: localized("Dependency setup did not finish cleanly.", "De voorbereiding van afhankelijkheden is niet netjes afgerond."), output: notes.joined(separator: "\n\n") + "\n\n" + clamResult.output)
        }

        let ncduResult = await ensureCommand(toolName: "ncdu", formulaName: "ncdu", brewPath: brewPath, friendlyName: "ncdu")
        notes.append(claimer(for: "ncdu", result: ncduResult))
        if !ncduResult.success {
            return CommandExecutionResult(success: false, summary: localized("Dependency setup did not finish cleanly.", "De voorbereiding van afhankelijkheden is niet netjes afgerond."), output: notes.joined(separator: "\n\n") + "\n\n" + ncduResult.output)
        }

        let jdupesResult = await ensureCommand(toolName: "jdupes", formulaName: "jdupes", brewPath: brewPath, friendlyName: "jdupes")
        notes.append(claimer(for: "jdupes", result: jdupesResult))
        if !jdupesResult.success {
            return CommandExecutionResult(success: false, summary: localized("Dependency setup did not finish cleanly.", "De voorbereiding van afhankelijkheden is niet netjes afgerond."), output: notes.joined(separator: "\n\n") + "\n\n" + jdupesResult.output)
        }

        return CommandExecutionResult(success: true, summary: localized("Homebrew, ClamAV, ncdu, and jdupes are ready.", "Homebrew, ClamAV, ncdu en jdupes zijn klaar."), output: notes.joined(separator: "\n"))
    }

    private func runMappedShellCommand(_ command: String, task: MaintenanceTaskDefinition, requiresAdmin: Bool) async -> CommandExecutionResult {
        switch command {
        case "__BREW_UPDATE__":
            guard let brewPath = await resolveCommandPath("brew") else {
                return CommandExecutionResult(success: false, summary: localized("Homebrew is not installed.", "Homebrew is niet geïnstalleerd."), output: localized("Install Homebrew first, then try again.", "Installeer eerst Homebrew en probeer het daarna opnieuw."))
            }
            let brewQuoted = shellQuote(brewPath)
            let doctor = await runShell("\(brewQuoted) doctor", requiresAdmin: false)
            if !doctor.isSuccess {
                return translate(doctor, success: localized("Homebrew doctor completed.", "Homebrew doctor is voltooid."), failure: localized("brew doctor reported issues.", "brew doctor meldde problemen."))
            }

            let update = await runShell("\(brewQuoted) update --verbose && \(brewQuoted) upgrade --verbose", requiresAdmin: false)
            return translate(update, success: localized("Homebrew packages were updated.", "Homebrew-pakketten zijn bijgewerkt."), failure: localized("Homebrew update did not finish cleanly.", "De Homebrew-update is niet netjes afgerond."))

        case "__CLAM_SCAN__":
            let dependencyResult = await ensureDependencyOnly(toolName: "clamscan", formulaName: "clamav", friendlyName: "ClamAV")
            guard dependencyResult.success else {
                return dependencyResult
            }
            guard let clamscanPath = await resolveCommandPath("clamscan") else {
                return CommandExecutionResult(success: false, summary: localized("ClamAV is still unavailable.", "ClamAV is nog steeds niet beschikbaar."), output: "")
            }
            let result = await runShell("\(shellQuote(clamscanPath)) -r / --verbose", requiresAdmin: true)
            return translate(result, success: localized("Malware scan finished.", "Malwarescan is afgerond."), failure: localized("Malware scan failed.", "Malwarescan is mislukt."))

        default:
            let result = await runShell(command, requiresAdmin: requiresAdmin)
            return translate(result, success: localized("\(task.title.appLocalized) completed.", "\(task.title.appLocalized) is voltooid."), failure: localized("\(task.title.appLocalized) failed.", "\(task.title.appLocalized) is mislukt."))
        }
    }

    private func runInlineReport(_ command: String, task: MaintenanceTaskDefinition) async -> CommandExecutionResult {
        let resolvedCommand: String

        switch command {
        case "__DUPLICATE_SCAN__":
            let dependencyResult = await ensureDependencyOnly(toolName: "jdupes", formulaName: "jdupes", friendlyName: "jdupes")
            guard dependencyResult.success else {
                return dependencyResult
            }
            guard let jdupesPath = await resolveCommandPath("jdupes") else {
                return CommandExecutionResult(success: false, summary: localized("jdupes is not available.", "jdupes is niet beschikbaar."), output: "")
            }
            resolvedCommand = """
            echo '\(localized("Duplicate file candidates in Desktop, Documents, and Downloads", "Mogelijke dubbele bestanden in Bureaublad, Documenten en Downloads"))'
            echo '-------------------------------------------------------------'
            \(shellQuote(jdupesPath)) -r ~/Desktop ~/Documents ~/Downloads 2>/dev/null
            """

        case "__LARGE_OLD_FILES__":
            resolvedCommand = """
            echo '\(localized("Large files over 500 MB in Desktop, Documents, and Downloads", "Grote bestanden boven 500 MB in Bureaublad, Documenten en Downloads"))'
            echo '-----------------------------------------------------------'
            find ~/Desktop ~/Documents ~/Downloads -type f -size +500M 2>/dev/null | head -200
            echo ''
            echo '\(localized("Files older than 180 days in Desktop, Documents, and Downloads", "Bestanden ouder dan 180 dagen in Bureaublad, Documenten en Downloads"))'
            echo '---------------------------------------------------------------'
            find ~/Desktop ~/Documents ~/Downloads -type f -mtime +180 2>/dev/null | head -200
            """

        case "__CLOUD_AUDIT__":
            resolvedCommand = """
            echo '\(localized("Cloud storage overview", "Overzicht van cloudopslag"))'
            echo '----------------------'
            du -sh ~/Library/CloudStorage/* 2>/dev/null | sort -h
            echo ''
            du -sh ~/Library/Mobile\\ Documents/* 2>/dev/null | sort -h
            echo ''
            echo '\(localized("Large synced files over 250 MB", "Grote gesynchroniseerde bestanden boven 250 MB"))'
            echo '------------------------------'
            find ~/Library/CloudStorage ~/Library/Mobile\\ Documents -type f -size +250M 2>/dev/null | head -120
            """

        case "__SYSTEM_MAINTENANCE_STATUS__":
            resolvedCommand = """
            echo '\(localized("macOS background maintenance status", "Status van macOS-achtergrondonderhoud"))'
            echo '----------------------------------'
            launchctl print system/com.apple.systemstats.daily 2>/dev/null | sed -n '1,40p'
            echo ''
            echo '\(localized("Periodic CLI status", "Status van de oude periodic-CLI"))'
            echo '-------------------'
            if command -v periodic >/dev/null 2>&1; then
              command -v periodic
            else
              echo '\(localized("The legacy periodic command is not present on this macOS version.", "Het oude periodic-commando is op deze macOS-versie niet aanwezig."))'
            fi
            """

        default:
            resolvedCommand = command
        }

        let result = await runShell(resolvedCommand, requiresAdmin: false)
        let output = result.combined.trimmingCharacters(in: .whitespacesAndNewlines)
        return CommandExecutionResult(
            success: result.isSuccess,
            summary: result.isSuccess ? localized("\(task.title.appLocalized) report is ready.", "Het rapport voor \(task.title.appLocalized) is klaar.") : localized("\(task.title.appLocalized) report failed.", "Het rapport voor \(task.title.appLocalized) is mislukt."),
            output: output
        )
    }

    private func runTerminalCommand(_ command: String, task: MaintenanceTaskDefinition) async -> CommandExecutionResult {
        let resolvedCommand: String
        if command == "__NCDU_COMMAND__" {
            let dependencyResult = await ensureDependencyOnly(toolName: "ncdu", formulaName: "ncdu", friendlyName: "ncdu")
            guard dependencyResult.success else {
                return dependencyResult
            }
            guard let ncduPath = await resolveCommandPath("ncdu") else {
                return CommandExecutionResult(success: false, summary: localized("ncdu is not available.", "ncdu is niet beschikbaar."), output: "")
            }
            resolvedCommand = "\(shellQuote(ncduPath)) /"
        } else if command == "__DUPLICATE_SCAN__" {
            let dependencyResult = await ensureDependencyOnly(toolName: "jdupes", formulaName: "jdupes", friendlyName: "jdupes")
            guard dependencyResult.success else {
                return dependencyResult
            }
            guard let jdupesPath = await resolveCommandPath("jdupes") else {
                return CommandExecutionResult(success: false, summary: localized("jdupes is not available.", "jdupes is niet beschikbaar."), output: "")
            }
            resolvedCommand = """
            clear
            echo 'Scanning Desktop, Documents, and Downloads for duplicate files...'
            echo ''
            \(shellQuote(jdupesPath)) -r ~/Desktop ~/Documents ~/Downloads 2>/dev/null
            echo ''
            echo 'Read-only scan complete.'
            """
        } else if command == "__LARGE_OLD_FILES__" {
            resolvedCommand = """
            clear
            echo 'Large files over 500 MB in Desktop, Documents, and Downloads'
            echo '-----------------------------------------------------------'
            find ~/Desktop ~/Documents ~/Downloads -type f -size +500M 2>/dev/null | head -200
            echo ''
            echo 'Files older than 180 days in Desktop, Documents, and Downloads'
            echo '---------------------------------------------------------------'
            find ~/Desktop ~/Documents ~/Downloads -type f -mtime +180 2>/dev/null | head -200
            echo ''
            echo 'Read-only scan complete.'
            """
        } else if command == "__CLOUD_AUDIT__" {
            resolvedCommand = """
            clear
            echo 'Cloud storage overview'
            echo '----------------------'
            du -sh ~/Library/CloudStorage/* 2>/dev/null | sort -h
            echo ''
            du -sh ~/Library/Mobile\\ Documents/* 2>/dev/null | sort -h
            echo ''
            echo 'Large synced files over 250 MB'
            echo '------------------------------'
            find ~/Library/CloudStorage ~/Library/Mobile\\ Documents -type f -size +250M 2>/dev/null | head -120
            """
        } else {
            resolvedCommand = command
        }

        let script = """
        tell application "Terminal"
            activate
            do script "\(appleScriptEscape(shellBootstrap + resolvedCommand))"
        end tell
        """
        let result = await runAppleScript(script)
        return translate(result, success: localized("\(task.title.appLocalized) opened in Terminal.", "\(task.title.appLocalized) is geopend in Terminal."), failure: localized("Failed to open Terminal for \(task.title.appLocalized).", "Het openen van Terminal voor \(task.title.appLocalized) is mislukt."))
    }

    private func ensureDependencyOnly(toolName: String, formulaName: String, friendlyName: String) async -> CommandExecutionResult {
        guard let brewPath = await resolveCommandPath("brew") else {
            return CommandExecutionResult(success: false, summary: localized("Homebrew is not installed.", "Homebrew is niet geïnstalleerd."), output: localized("Install Homebrew from brew.sh before running dependency setup.", "Installeer eerst Homebrew via brew.sh voordat u de afhankelijkheden controleert."))
        }
        return await ensureCommand(toolName: toolName, formulaName: formulaName, brewPath: brewPath, friendlyName: friendlyName)
    }

    private func ensureCommand(toolName: String, formulaName: String, brewPath: String, friendlyName: String) async -> CommandExecutionResult {
        if let existing = await resolveCommandPath(toolName), !existing.isEmpty {
            return CommandExecutionResult(success: true, summary: localized("\(friendlyName) is already available.", "\(friendlyName) is al beschikbaar."), output: existing)
        }

        let install = await runShell("\(shellQuote(brewPath)) install \(shellQuote(formulaName))", requiresAdmin: false)
        return translate(install, success: localized("\(friendlyName) was installed.", "\(friendlyName) is geïnstalleerd."), failure: localized("Failed to install \(friendlyName).", "Het installeren van \(friendlyName) is mislukt."))
    }

    private func resolveCommandPath(_ toolName: String) async -> String? {
        let result = await runShell("command -v \(toolName)", requiresAdmin: false)
        guard result.isSuccess else { return nil }
        let path = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
        return path.isEmpty ? nil : path
    }

    private func runShell(_ command: String, requiresAdmin: Bool) async -> ProcessOutput {
        let prepared = shellBootstrap + command

        if requiresAdmin {
            let source = "do shell script \"\(appleScriptEscape(prepared))\" with administrator privileges"
            return await runProcess(executable: "/usr/bin/osascript", arguments: ["-e", source])
        } else {
            return await runProcess(executable: "/bin/zsh", arguments: ["-lc", prepared])
        }
    }

    private func runAppleScript(_ script: String) async -> ProcessOutput {
        await runProcess(executable: "/usr/bin/osascript", arguments: ["-e", script])
    }

    private func runProcess(executable: String, arguments: [String]) async -> ProcessOutput {
        await withCheckedContinuation { continuation in
            let process = Process()
            let stdoutPipe = Pipe()
            let stderrPipe = Pipe()

            process.executableURL = URL(fileURLWithPath: executable)
            process.arguments = arguments
            process.standardOutput = stdoutPipe
            process.standardError = stderrPipe

            process.terminationHandler = { process in
                let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
                let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()

                let stdout = String(data: stdoutData, encoding: .utf8) ?? ""
                let stderr = String(data: stderrData, encoding: .utf8) ?? ""

                continuation.resume(returning: ProcessOutput(exitCode: process.terminationStatus, stdout: stdout, stderr: stderr))
            }

            do {
                try process.run()
            } catch {
                continuation.resume(returning: ProcessOutput(exitCode: 1, stdout: "", stderr: error.localizedDescription))
            }
        }
    }

    private func translate(_ result: ProcessOutput, success: String, failure: String) -> CommandExecutionResult {
        CommandExecutionResult(
            success: result.isSuccess,
            summary: result.isSuccess ? success : failure,
            output: result.combined
        )
    }

    private func claimer(for friendlyName: String, result: CommandExecutionResult) -> String {
        if result.success {
            return "\(friendlyName): \(result.summary)"
        } else {
            return "\(friendlyName): \(result.summary)\n\(result.output)"
        }
    }

    private func cleanupScope(for component: TaskScanComponent) -> String {
        var details: [String] = []

        if let reclaimableBytes = component.reclaimableBytes, reclaimableBytes > 0 {
            details.append(localized("about \(byteFormatter.string(fromByteCount: reclaimableBytes))", "ongeveer \(byteFormatter.string(fromByteCount: reclaimableBytes))"))
        }

        if let itemCount = component.itemCount, itemCount > 0 {
            let itemLabel = itemCount == 1 ? localized("1 item", "1 item") : localized("\(itemCount) items", "\(itemCount) items")
            details.append(itemLabel)
        }

        guard !details.isEmpty else {
            return localized("for the selected part", "voor het geselecteerde onderdeel")
        }

        return localized("for ", "voor ") + details.joined(separator: localized(" across ", " verdeeld over "))
    }

    private func shellQuote(_ raw: String) -> String {
        "'" + raw.replacingOccurrences(of: "'", with: "'\"'\"'") + "'"
    }

    private func appleScriptEscape(_ raw: String) -> String {
        raw
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }
}
