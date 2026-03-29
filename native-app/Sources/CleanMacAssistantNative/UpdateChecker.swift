import Foundation

enum UpdateCheckState: Equatable {
    case idle
    case checking
    case upToDate(currentVersion: String, latestVersion: String)
    case updateAvailable(version: String, notes: String, downloadURL: URL?)
    case failed(String)
}

private struct UpdateManifest: Decodable {
    let version: String
    let notes: String
    let downloadURL: URL?

    enum CodingKeys: String, CodingKey {
        case version
        case latestVersion = "latest_version"
        case notes
        case releaseNotes = "release_notes"
        case downloadURL = "download_url"
        case url
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        version = try container.decodeIfPresent(String.self, forKey: .version)
            ?? container.decodeIfPresent(String.self, forKey: .latestVersion)
            ?? "0.0.0"
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
            ?? container.decodeIfPresent(String.self, forKey: .releaseNotes)
            ?? localized("A new version is available.", "Er is een nieuwe versie beschikbaar.")
        downloadURL = try container.decodeIfPresent(URL.self, forKey: .downloadURL)
            ?? container.decodeIfPresent(URL.self, forKey: .url)
    }
}

struct UpdateChecker {
    private let repositoryURLs = [
        URL(string: "https://repo.easycomp.cloud/public_access/ECZ-CleanMac-Assistent/APP%20version/")!,
        URL(string: "https://repo.easycomp.cloud/public_access/?dir=ECZ-CleanMac-Assistent%2FAPP+version")!
    ]
    private let downloadableExtensions = ["dmg", "zip", "pkg"]

    func check(currentVersion: String) async -> UpdateCheckState {
        do {
            let source = try await resolveUpdateSource()

            switch source {
            case let .manifest(manifest):
                if isVersion(manifest.version, newerThan: currentVersion) {
                    return .updateAvailable(version: manifest.version, notes: manifest.notes, downloadURL: manifest.downloadURL)
                }

                return .upToDate(
                    currentVersion: normalizedVersion(currentVersion),
                    latestVersion: normalizedVersion(manifest.version)
                )

            case let .artifact(version, downloadURL):
                if isVersion(version, newerThan: currentVersion) {
                    return .updateAvailable(
                        version: version,
                        notes: releaseNotes(for: version),
                        downloadURL: downloadURL
                    )
                }

                return .upToDate(
                    currentVersion: normalizedVersion(currentVersion),
                    latestVersion: normalizedVersion(version)
                )
            }
        } catch UpdateCheckError.noManifestOrArtifact {
            return .failed(
                localized(
                    "No update file was found in the download folder yet.",
                    "Er is nog geen updatebestand gevonden in de downloadmap."
                )
            )
        } catch {
            return .failed(localized("Update check failed. Please check the download folder link or try again later.", "Updatecontrole is mislukt. Controleer de link naar de downloadmap of probeer het later opnieuw."))
        }
    }

    private func resolveUpdateSource() async throws -> UpdateSource {
        var lastError: Error?

        for repositoryURL in repositoryURLs {
            do {
                return try await resolveUpdateSource(from: repositoryURL)
            } catch {
                lastError = error
            }
        }

        throw lastError ?? UpdateCheckError.noManifestOrArtifact
    }

    private func resolveUpdateSource(from repositoryURL: URL) async throws -> UpdateSource {
        let (data, response) = try await URLSession.shared.data(from: repositoryURL)

        if let httpResponse = response as? HTTPURLResponse,
           let mimeType = httpResponse.value(forHTTPHeaderField: "Content-Type"),
           mimeType.localizedCaseInsensitiveContains("application/json") {
            let manifest = try JSONDecoder().decode(UpdateManifest.self, from: data)
            return .manifest(manifest)
        }

        let html = String(decoding: data, as: UTF8.self)

        if let manifestURL = extractManifestURL(from: html),
           let resolvedManifestURL = resolvedURL(from: manifestURL, relativeTo: repositoryURL) {
            let (manifestData, _) = try await URLSession.shared.data(from: resolvedManifestURL)
            let manifest = try JSONDecoder().decode(UpdateManifest.self, from: manifestData)
            return .manifest(manifest)
        }

        if let artifact = extractLatestArtifact(from: html, repositoryURL: repositoryURL) {
            return .artifact(version: artifact.version, downloadURL: artifact.url)
        }

        throw UpdateCheckError.noManifestOrArtifact
    }

    private func extractManifestURL(from html: String) -> String? {
        let matches = extractLinks(from: html)

        if let href = matches.first(where: { _, href in
            href.localizedCaseInsensitiveContains("update.json")
        })?.href {
            return href
        }

        return nil
    }

    private func extractLatestArtifact(from html: String, repositoryURL: URL) -> (version: String, url: URL)? {
        let matches = extractLinks(from: html)
        var bestMatch: (version: String, url: URL)?

        for (label, href) in matches {
            let searchableText = href + " " + label

            guard downloadableExtensions.contains(where: { searchableText.lowercased().contains(".\($0)") }),
                  let version = extractVersion(from: searchableText),
                  let url = resolvedURL(from: href, relativeTo: repositoryURL)
            else {
                continue
            }

            if let currentBest = bestMatch {
                if isVersion(version, newerThan: currentBest.version) {
                    bestMatch = (version, url)
                }
            } else {
                bestMatch = (version, url)
            }
        }

        return bestMatch
    }

    private func resolvedURL(from href: String, relativeTo baseURL: URL) -> URL? {
        let sanitizedHref = href
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "%20")

        if let directURL = URL(string: sanitizedHref), directURL.scheme != nil {
            return directURL
        }

        return URL(string: sanitizedHref, relativeTo: baseURL)?.absoluteURL
    }

    private func extractLinks(from html: String) -> [(label: String, href: String)] {
        let pattern = #"(?i)<a[^>]*href=["']([^"']+)["'][^>]*>(.*?)</a>"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(html.startIndex..<html.endIndex, in: html)

        return regex.matches(in: html, range: range).compactMap { match in
            guard match.numberOfRanges == 3,
                  let hrefRange = Range(match.range(at: 1), in: html),
                  let labelRange = Range(match.range(at: 2), in: html)
            else {
                return nil
            }

            let href = String(html[hrefRange])
            let label = html[labelRange]
                .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)

            return (label: label, href: href)
        }
    }

    private func extractVersion(from text: String) -> String? {
        let pattern = #"\b\d+(?:\.\d+){1,3}\b"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)

        guard let match = regex.firstMatch(in: text, range: range),
              let versionRange = Range(match.range(at: 0), in: text)
        else {
            return nil
        }

        return String(text[versionRange])
    }

    private func releaseNotes(for version: String) -> String {
        switch normalizedVersion(version) {
        case "1.0.10":
            return localized(
                "What's new\n• Files now asks you to choose scan folders once instead of tripping repeated Desktop, Documents, and Downloads permission prompts\n• Large-file, duplicate, and installer reviews now stay inside the folders you explicitly connected\n• The Files page includes a clearer folder-access panel so the scan scope stays understandable\n• The release metadata was refreshed for the calmer file-access flow",
                "Wat is er nieuw\n• Bestanden laat u nu één keer scanmappen kiezen in plaats van herhaalde toestemmingsmeldingen voor Bureaublad, Documenten en Downloads op te roepen\n• Controles op grote bestanden, duplicaten en installers blijven nu binnen de mappen die u expliciet hebt gekoppeld\n• De Bestanden-pagina heeft nu een duidelijkere maptoegangspagina zodat de scanscope begrijpelijk blijft\n• De release-metadata is vernieuwd voor deze rustigere bestands-toegangsflow"
            )
        case "1.0.9":
            return localized(
                "What's new\n• Applications now includes an installed-app picker for uninstall and preference reset tasks\n• You can choose real apps from the Mac instead of typing names or bundle identifiers manually\n• App removal is more reliable for items in both /Applications and ~/Applications\n• The applications flow now feels closer to a dedicated app manager while keeping the EasyComp updater and cleanup tools",
                "Wat is er nieuw\n• Apps bevat nu een geïnstalleerde-appkiezer voor verwijderen en voorkeuren resetten\n• U kunt echte apps van de Mac kiezen in plaats van handmatig namen of bundle-identifiers te typen\n• App-verwijdering werkt nu betrouwbaarder voor onderdelen in zowel /Applications als ~/Applications\n• De apps-flow voelt nu meer als een echte appmanager, terwijl de EasyComp-updater en opschoonhulpmiddelen behouden blijven"
            )
        case "1.0.8":
            return localized(
                "What's new\n• Reworked app shell with a cleaner Home dashboard and quicker stats\n• Sidebar navigation now feels calmer and closer to a polished Mac cleaner layout\n• File, application, and maintenance routes are more focused while keeping the custom updater and EasyComp-specific tools\n• The About page and preview scenes now reflect the rebrand pass",
                "Wat is er nieuw\n• Vernieuwde app-shell met een rustiger Home-dashboard en snellere statuskaarten\n• De navigatie links voelt nu kalmer en meer als een verzorgde Mac-cleaner-indeling\n• Bestands-, app- en onderhoudsroutes zijn gerichter geworden, terwijl de maatwerk-updater en EasyComp-tools behouden blijven\n• De Over-pagina en voorbeeldscenes tonen nu ook deze rebrand-pass"
            )
        case "1.0.7":
            return localized(
                "What's new\n• New calmer dashboard layout inspired by modern Mac cleaner apps\n• Applications now include an orphaned files review for leftover app data without a matching installed app\n• Task cards and module pages are less cluttered and easier to scan\n• The About page and developer preview scenes were refreshed for the new dashboard pass",
                "Wat is er nieuw\n• Nieuwe rustigere dashboard-indeling, geinspireerd op moderne Mac-cleaners\n• Apps bevat nu een controle voor verweesde bestanden met appresten zonder bijbehorende geïnstalleerde app\n• Taakkaarten en paginaworkflows zijn minder druk en sneller te overzien\n• De Over-pagina en ontwikkelvoorbeelden zijn vernieuwd voor deze dashboard-pass"
            )
        case "1.0.6":
            return localized(
                "What's new\n• New installer cleanup review for DMG, PKG, and XIP files\n• Uninstall now removes common user-library leftovers after the app bundle is removed\n• Files review is better aligned with safer cleanup workflows inspired by modern open-source Mac cleaners\n• The About page and preview changelog now reflect the new cleanup tools",
                "Wat is er nieuw\n• Nieuwe installer-opruimcontrole voor DMG-, PKG- en XIP-bestanden\n• Verwijderen van apps ruimt nu ook gebruikelijke restbestanden in de gebruikersbibliotheek op\n• Bestandscontrole sluit nu beter aan op veiligere opschoonflows uit moderne open-source Mac-cleaners\n• De Over-pagina en preview-changelog tonen nu ook deze nieuwe opschoonhulpmiddelen"
            )
        case "1.0.5":
            return localized(
                "What's new\n• Large and stale files can now be reviewed and removed inside the app\n• Duplicate scans now keep one suggested original and let you remove the extra copies\n• File review scenes are clearer for manual cleanup work\n• Developer preview data now mirrors the new file cleanup flow",
                "Wat is er nieuw\n• Grote en verouderde bestanden kunnen nu in de app worden bekeken en verwijderd\n• Duplicaatscans bewaren nu één voorgesteld origineel en laten u de extra kopieën verwijderen\n• Bestandscontrole is duidelijker gemaakt voor handmatige opschoning\n• Voorbeelddata voor ontwikkelaars volgt nu de nieuwe bestandsopschoonflow"
            )
        case "1.0.4":
            return localized(
                "What's new\n• New in-app update popup when a newer version is found\n• Downloads and installs DMG releases automatically\n• Relaunches into the new version after the install helper finishes\n• Keeps the manual download option as a fallback",
                "Wat is er nieuw\n• Nieuwe in-app updatepopup zodra er een nieuwere versie is\n• Downloadt en installeert DMG-releases automatisch\n• Start opnieuw op in de nieuwe versie zodra de updatehulp klaar is\n• Behoudt de handmatige downloadoptie als fallback"
            )
        case "1.0.3":
            return localized(
                "What's new\n• Fixed update checks for the EasyComp download folder\n• Calmer progress flow with a persistent results screen\n• Visible scroll bars and lighter card copy\n• Subtle completion sounds for steps and finished runs",
                "Wat is er nieuw\n• Updatecontrole hersteld voor de EasyComp-downloadmap\n• Rustigere voortgangsflow met een blijvend resultaatscherm\n• Zichtbare scrollbalken en compactere teksten\n• Subtiele afrondgeluiden per stap en per run"
            )
        case "1.0.2":
            return localized(
                "What's new\n• Full-page progress workspace\n• Cleaner review flow\n• New About page\n• Live preview language switching\n• Repository-based update checks",
                "Wat is er nieuw\n• Volledige voortgangswerkruimte\n• Rustigere reviewflow\n• Nieuwe Over-pagina\n• Live taalwissel in preview\n• Updatecontrole via de repository"
            )
        default:
            return localized(
                "A newer app build was found in the EasyComp download folder.",
                "Er is een nieuwere appversie gevonden in de EasyComp-downloadmap."
            )
        }
    }

    private func normalizedVersion(_ version: String) -> String {
        extractVersion(from: version) ?? version
    }

    private func isVersion(_ lhs: String, newerThan rhs: String) -> Bool {
        let leftParts = normalizedVersion(lhs).split(separator: ".").map { Int($0) ?? 0 }
        let rightParts = normalizedVersion(rhs).split(separator: ".").map { Int($0) ?? 0 }
        let count = max(leftParts.count, rightParts.count)

        for index in 0..<count {
            let left = index < leftParts.count ? leftParts[index] : 0
            let right = index < rightParts.count ? rightParts[index] : 0
            if left != right {
                return left > right
            }
        }

        return false
    }
}

private enum UpdateSource {
    case manifest(UpdateManifest)
    case artifact(version: String, downloadURL: URL)
}

private enum UpdateCheckError: Error {
    case noManifestOrArtifact
}
