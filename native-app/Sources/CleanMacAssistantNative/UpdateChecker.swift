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
