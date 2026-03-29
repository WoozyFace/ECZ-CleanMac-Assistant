import Foundation

enum AppLanguage {
    case english
    case dutch

    static var current: AppLanguage {
        #if DEVELOPER_BUILD
        if let override = DebugLanguageOverride.currentResolvedLanguage {
            return override
        }
        #endif

        let identifier = Locale.preferredLanguages.first?.lowercased() ?? "en"
        return identifier.hasPrefix("nl") ? .dutch : .english
    }
}

func localized(_ english: String, _ dutch: String) -> String {
    AppLanguage.current == .dutch ? dutch : english
}

extension String {
    var appLocalized: String {
        guard AppLanguage.current == .dutch else { return self }
        return AppTranslations.dutch[self] ?? self
    }
}

enum AppTranslations {
    static let dutch: [String: String] = [
        "Recommended first pass": "Aanbevolen eerste stap",
        "Smart Care": "Slimme Zorg",
        "A balanced starter lane that prepares your tooling, refreshes memory and network state, and gives the Mac a safe first tune-up.": "Een evenwichtige start die uw hulpmiddelen voorbereidt, geheugen en netwerk ververst en uw Mac een veilige eerste opfrisbeurt geeft.",
        "A calm first pass that prepares your tools, checks safe cleanup areas, and gives your Mac a low-friction tune-up before deeper maintenance.": "Een rustige eerste stap die uw hulpmiddelen voorbereidt, veilige opschoongebieden controleert en uw Mac een onderhoudsbeurt met weinig gedoe geeft voordat u dieper onderhoud uitvoert.",
        "Junk and leftovers": "Rommel en restbestanden",
        "Cleanup": "Opschonen",
        "Tidy up system junk, caches, browser leftovers, mail downloads, and old local clutter that quietly eats into storage.": "Ruim systeemrommel, caches, browserresten, Mail-downloads en oude lokale rommel op die ongemerkt opslagruimte innemen.",
        "Privacy and threats": "Privacy en dreigingen",
        "Protection": "Bescherming",
        "Cover malware, browser traces, chat leftovers, login-item exposure, and persistence points in one tighter security lane.": "Pak malware, browsersporen, chatresten, inlogonderdelen en opstartpunten samen aan in een veiligere controlepagina.",
        "Speed and stability": "Snelheid en stabiliteit",
        "Performance": "Prestaties",
        "Handle maintenance routines, cache flushing, relaunch core UI processes, check updates, and monitor the Mac live.": "Voer onderhoudsroutines uit, wis caches, herstart belangrijke interfaceprocessen, controleer updates en bekijk uw Mac live.",
        "App control": "App-beheer",
        "Applications": "Apps",
        "Remove apps, reset broken preferences, and jump straight into update surfaces without digging through the system by hand.": "Verwijder apps, herstel kapotte voorkeuren en ga direct naar update-schermen zonder handmatig door het systeem te zoeken.",
        "My clutter lane": "Mijn rommelpagina",
        "My Clutter": "Mijn Rommel",
        "Review large and old files, inspect duplicate candidates, and jump directly into the Downloads folder when it needs attention.": "Bekijk grote en oude bestanden, controleer mogelijke duplicaten en open direct de Downloads-map wanneer die aandacht nodig heeft.",
        "Storage overview": "Opslagoverzicht",
        "Space Lens": "Ruimte Lens",
        "Map disk usage interactively and audit synced cloud folders so storage-heavy areas are easier to spot before you clean them.": "Breng schijfgebruik interactief in kaart en controleer gesynchroniseerde cloudmappen zodat opslagvreters sneller zichtbaar worden.",
        "Prepare Tools": "Hulpmiddelen voorbereiden",
        "Verify Homebrew, ClamAV, ncdu, and jdupes.": "Controleer Homebrew, ClamAV, ncdu en jdupes.",
        "Makes sure the core tooling for malware scans, disk mapping, and duplicate scans is installed before deeper maintenance starts.": "Zorgt dat de basisgereedschappen voor malwarescans, schijfanalyse en duplicaatcontrole klaarstaan voordat uitgebreider onderhoud begint.",
        "Usually under 1 minute unless installs are needed": "Meestal minder dan 1 minuut tenzij er iets geïnstalleerd moet worden",
        "Empty Trash": "Prullenmand legen",
        "Permanently remove everything from the Trash.": "Verwijder alles definitief uit de prullenmand.",
        "A direct storage win, but it is irreversible once the command completes.": "Levert direct opslagruimte op, maar is niet ongedaan te maken zodra het commando klaar is.",
        "A few seconds": "Een paar seconden",
        "Clear Cache": "Cache legen",
        "Refresh temporary cache state.": "Ververs tijdelijke cachebestanden.",
        "Performs a lighter cache refresh without wiping broad user data collections.": "Voert een lichtere cache-opfrisbeurt uit zonder brede verzamelingen gebruikersdata te wissen.",
        "Clear Log Files": "Logbestanden verwijderen",
        "Remove local system log files.": "Verwijder lokale systeemlogbestanden.",
        "Useful for cleanup, but it also erases local troubleshooting history.": "Handig voor opschonen, maar verwijdert ook lokale geschiedenis voor probleemoplossing.",
        "Remove Language Files": "Taalbestanden verwijderen",
        "Delete non-English .lproj folders from Applications.": "Verwijder niet-Engelse .lproj-mappen uit Programma's.",
        "Aggressive space-saving option that can affect language support inside installed apps.": "Een stevige ruimtebesparende optie die taalondersteuning in geïnstalleerde apps kan beïnvloeden.",
        "A few seconds to a minute": "Een paar seconden tot een minuut",
        "Clear Chrome Cache": "Chrome-cache legen",
        "Delete cached Chrome data from your user Library.": "Verwijder gecachte Chrome-gegevens uit uw gebruikersbibliotheek.",
        "Useful when websites are serving stale assets or the browser cache has grown too large.": "Handig wanneer websites verouderde bestanden tonen of de browsercache te groot is geworden.",
        "Clear Firefox Cache": "Firefox-cache legen",
        "Delete cached Firefox profile data.": "Verwijder gecachte Firefox-profielgegevens.",
        "Clears local Firefox cache assets while leaving the browser installation itself intact.": "Verwijdert lokale Firefox-cachebestanden zonder de browserinstallatie zelf aan te tasten.",
        "Clear Mail Attachments": "Mail-bijlagen opschonen",
        "Remove Mail Downloads cache from Apple Mail.": "Verwijder de Mail Downloads-cache van Apple Mail.",
        "Targets attachment downloads cached by Apple Mail, which can quietly take a surprising amount of space.": "Richt zich op bijlagen die door Apple Mail zijn opgeslagen en verrassend veel ruimte kunnen innemen.",
        "Free Up RAM": "RAM vrijmaken",
        "Run purge to release inactive memory.": "Voer purge uit om inactief geheugen vrij te maken.",
        "A forceful memory refresh that can help before heavier workloads or after long uptime.": "Een stevige geheugenverversing die kan helpen voor zwaarder werk of na lange uptime.",
        "Check Maintenance Status": "Onderhoudsstatus bekijken",
        "Show how macOS background housekeeping is scheduled now.": "Toon hoe macOS-achtergrondonderhoud nu is ingepland.",
        "Recent macOS releases handle routine housekeeping with background launchd services instead of the old periodic command-line scripts.": "Recente macOS-versies regelen routineonderhoud via achtergrondservices van launchd in plaats van de oude periodic-scripts.",
        "Flush DNS Cache": "DNS-cache legen",
        "Clear resolver caches and restart mDNSResponder.": "Leeg resolver-caches en herstart mDNSResponder.",
        "Useful when websites resolve incorrectly or internal hostnames seem stale.": "Handig wanneer websites verkeerd resolven of interne hostnamen verouderd lijken.",
        "Restart Finder, Dock, and System UI": "Finder, Dock en systeeminterface herstarten",
        "Refresh core interface processes.": "Ververs belangrijke interfaceprocessen.",
        "A quick reset when Finder, Dock, or SystemUIServer feels glitchy or visually stuck.": "Een snelle reset wanneer Finder, Dock of SystemUIServer hapert of vast lijkt te zitten.",
        "Install macOS Updates": "macOS-updates installeren",
        "Run softwareupdate for available system updates.": "Voer softwareupdate uit voor beschikbare systeemupdates.",
        "Installs available macOS updates and may require restart behavior afterward.": "Installeert beschikbare macOS-updates en kan daarna een herstart vereisen.",
        "Potentially several minutes": "Mogelijk meerdere minuten",
        "Update Homebrew Packages": "Homebrew-pakketten bijwerken",
        "Run brew doctor, update, and upgrade.": "Voer brew doctor, update en upgrade uit.",
        "Refreshes Homebrew metadata and upgrades installed packages in one pass.": "Vernieuwt Homebrew-metadata en werkt geïnstalleerde pakketten in één keer bij.",
        "Usually a few minutes": "Meestal een paar minuten",
        "Open Activity Monitor": "Activiteitenweergave openen",
        "Jump straight into the native live process view.": "Ga direct naar de ingebouwde live procesweergave.",
        "A fast handoff into macOS' own live monitoring surface for CPU, memory, energy, and disk activity.": "Een snelle doorgang naar macOS zelf voor live monitoring van CPU, geheugen, energie en schijfactiviteit.",
        "Opens immediately": "Opent direct",
        "Review Login Items": "Login-items bekijken",
        "Open the Login Items settings page.": "Open de instellingenpagina voor login-items.",
        "Useful for spotting apps or background components that start automatically and affect privacy or performance.": "Handig om apps of achtergrondonderdelen te vinden die automatisch starten en invloed hebben op privacy of prestaties.",
        "Clear Safari History": "Safari-geschiedenis wissen",
        "Delete Safari history from the local history database.": "Verwijder Safari-geschiedenis uit de lokale geschiedenisdatabase.",
        "Removes recorded Safari browsing history from this Mac.": "Verwijdert opgeslagen Safari-browsergeschiedenis van deze Mac.",
        "Clear iMessage Logs": "iMessage-gegevens wissen",
        "Delete local Messages database files.": "Verwijder lokale Berichten-databasebestanden.",
        "Removes local Messages database files stored in your Library.": "Verwijdert lokale Berichten-databasebestanden uit uw bibliotheek.",
        "Clear Browser Cookies": "Browsercookies wissen",
        "Delete cookie files from your Library.": "Verwijder cookiebestanden uit uw bibliotheek.",
        "Reduces saved browser traces and can sign websites out of cookie-based sessions.": "Vermindert opgeslagen browsersporen en kan websites uit cookie-sessies uitloggen.",
        "Clear FaceTime Logs": "FaceTime-gegevens wissen",
        "Remove the FaceTime preferences bag file.": "Verwijder het voorkeurenbestand van FaceTime.",
        "A small, targeted cleanup of local FaceTime state stored in your preferences directory.": "Een kleine, gerichte opschoning van lokale FaceTime-gegevens in uw voorkeurenmap.",
        "Run Malware Scan": "Malwarescan uitvoeren",
        "Scan the system recursively with ClamAV.": "Scan het systeem recursief met ClamAV.",
        "A deeper security task that can take a long time, but it is useful when you want a real threat sweep.": "Een diepere beveiligingstaak die langer kan duren, maar nuttig is voor een echte dreigingscontrole.",
        "Can take quite a while": "Kan behoorlijk lang duren",
        "Remove Launch Agents": "Launch Agents verwijderen",
        "Delete LaunchAgents from your user Library.": "Verwijder LaunchAgents uit uw gebruikersbibliotheek.",
        "Powerful cleanup for persistence items. Only use this if you understand the side effects.": "Een krachtige opschoning voor opstartitems. Gebruik dit alleen als u de gevolgen begrijpt.",
        "Uninstall App": "App verwijderen",
        "Remove a named app bundle from /Applications.": "Verwijder een benoemde app-bundle uit /Applications.",
        "You provide the app name, then the assistant removes the matching .app bundle from /Applications after confirmation.": "U vult de appnaam in en daarna verwijdert de assistent de bijbehorende .app-bundle uit /Applications na bevestiging.",
        "Reset App Preferences": "App-voorkeuren resetten",
        "Delete saved defaults for a bundle identifier.": "Verwijder opgeslagen voorkeuren voor een bundle-identifier.",
        "Useful for stubborn apps with broken settings when you do not want to fully reinstall them yet.": "Handig voor koppige apps met kapotte instellingen wanneer u nog niet volledig opnieuw wilt installeren.",
        "Open App Store Updates": "App Store-updates openen",
        "Jump directly to the App Store updates page.": "Ga direct naar de updates-pagina van de App Store.",
        "A quick way to check native App Store updates without digging through the App Store manually.": "Een snelle manier om App Store-updates te bekijken zonder handmatig te zoeken.",
        "Analyze Disk Usage": "Schijfgebruik analyseren",
        "Open ncdu in a separate Terminal window.": "Open ncdu in een apart Terminal-venster.",
        "Launches an interactive storage walk-through. This one still opens outside the app because ncdu is fully interactive.": "Start een interactieve opslaganalyse. Deze opent nog buiten de app omdat ncdu volledig interactief is.",
        "Opens immediately, exploration is up to you": "Opent direct, verder verkennen doet u zelf",
        "Scan Large & Old Files": "Grote en oude bestanden scannen",
        "Show bulky and old files inside the app.": "Toon grote en oude bestanden in de app.",
        "Runs a read-only report for large files and older items across Desktop, Documents, and Downloads without opening Terminal.": "Voert een alleen-lezen rapport uit voor grote en oudere bestanden op Bureaublad, Documenten en Downloads zonder Terminal te openen.",
        "Scan Duplicate Files": "Dubbele bestanden scannen",
        "List duplicate candidates inside the app.": "Toon mogelijke duplicaten in de app.",
        "Runs a read-only duplicate scan for Desktop, Documents, and Downloads. It lists matches but does not delete them.": "Voert een alleen-lezen duplicaatscan uit voor Bureaublad, Documenten en Downloads. De matches worden getoond, maar niet verwijderd.",
        "Review Downloads Folder": "Downloads-map bekijken",
        "Open Downloads in Finder.": "Open Downloads in Finder.",
        "A quick manual review surface for installers, old archives, and forgotten downloads.": "Een snelle handmatige controleplek voor installers, oude archieven en vergeten downloads.",
        "Audit Cloud Storage": "Cloudopslag controleren",
        "Inspect local iCloud and CloudStorage usage inside the app.": "Bekijk lokaal iCloud- en CloudStorage-gebruik in de app.",
        "Lists local synced cloud folders by size so you can spot space-heavy accounts before cleaning them manually.": "Toont lokale gesynchroniseerde cloudmappen op grootte zodat u opslagvreters ziet voordat u handmatig opschoont.",
        "Trash": "Prullenmand",
        "Files and folders currently in the Trash.": "Bestanden en mappen die nu in de prullenmand staan.",
        "Chrome cache": "Chrome-cache",
        "Saved website files that Chrome can download again later.": "Opgeslagen websitebestanden die Chrome later opnieuw kan downloaden.",
        "Firefox cache": "Firefox-cache",
        "Saved website files from Firefox profiles.": "Opgeslagen websitebestanden uit Firefox-profielen.",
        "Mail attachments": "Mail-bijlagen",
        "Attachments Apple Mail has downloaded to your Mac.": "Bijlagen die Apple Mail naar uw Mac heeft gedownload.",
        "Browsing history": "Browsegeschiedenis",
        "The list of websites you visited in Safari.": "De lijst met websites die u in Safari hebt bezocht.",
        "Downloads history": "Downloadgeschiedenis",
        "The list of downloaded items shown by Safari.": "De lijst met gedownloade onderdelen die Safari toont.",
        "Last session data": "Gegevens van laatste sessie",
        "Recently closed tabs and last session information.": "Recent gesloten tabbladen en informatie van de vorige sessie.",
        "Website icons": "Websitepictogrammen",
        "Small website icons Safari keeps for faster loading.": "Kleine websitepictogrammen die Safari bewaart voor sneller laden.",
        "Safari cookies": "Safari-cookies",
        "Saved website logins and preferences used by Safari.": "Opgeslagen website-aanmeldingen en voorkeuren die Safari gebruikt.",
        "Chrome cookies": "Chrome-cookies",
        "Saved website logins and website settings used by Google Chrome.": "Opgeslagen website-aanmeldingen en instellingen die Google Chrome gebruikt.",
        "Firefox cookies": "Firefox-cookies",
        "Saved website logins and settings used by Firefox profiles.": "Opgeslagen website-aanmeldingen en instellingen die Firefox-profielen gebruiken.",
        "Messages database": "Berichten-database",
        "Local chat databases for the Messages app on this Mac.": "Lokale chatdatabases voor de Berichten-app op deze Mac.",
        "FaceTime local data": "Lokale FaceTime-gegevens",
        "A small FaceTime settings file stored on this Mac.": "Een klein FaceTime-instellingenbestand dat op deze Mac staat.",
        "General cache": "Algemene cache",
        "Temporary cache files kept by apps and macOS in your user account.": "Tijdelijke cachebestanden die door apps en macOS in uw gebruikersaccount worden bewaard.",
        "Downloads folder": "Downloads-map",
        "Files in your Downloads folder that may be safe to review and remove by hand.": "Bestanden in uw Downloads-map die u mogelijk veilig kunt controleren en handmatig verwijderen.",
        "iCloud Drive files": "iCloud Drive-bestanden",
        "Files that are stored locally from iCloud Drive.": "Bestanden die lokaal vanuit iCloud Drive zijn opgeslagen.",
        "Other cloud folders": "Andere cloudmappen",
        "Files stored locally by synced cloud apps such as Dropbox or OneDrive.": "Bestanden die lokaal zijn opgeslagen door gesynchroniseerde cloudapps zoals Dropbox of OneDrive.",
        "The Trash is already empty.": "De prullenmand is al leeg.",
        "Chrome cache is already small.": "De Chrome-cache is al klein.",
        "Firefox cache is already small.": "De Firefox-cache is al klein.",
        "No downloaded Mail attachments were found here.": "Er zijn hier geen gedownloade Mail-bijlagen gevonden.",
        "No Safari data was found that needs attention right now.": "Er zijn nu geen Safari-gegevens gevonden die aandacht nodig hebben.",
        "No browser cookie stores were found here.": "Er zijn hier geen browsercookie-opslagen gevonden.",
        "No local Messages database files were found.": "Er zijn geen lokale Berichten-databasebestanden gevonden.",
        "No FaceTime local data file was found.": "Er is geen lokaal FaceTime-gegevensbestand gevonden.",
        "No temporary files worth clearing were found.": "Er zijn geen tijdelijke bestanden gevonden die de moeite waard zijn om op te ruimen.",
        "Your Downloads folder looks small right now.": "Uw Downloads-map lijkt nu klein te zijn.",
        "No local cloud storage folders with visible files were found.": "Er zijn geen lokale cloudopslagmappen met zichtbare bestanden gevonden.",
        "This one needs deeper system access, so the app will clean it live when you run it.": "Dit onderdeel heeft diepere systeemtoegang nodig, dus de app voert het live uit wanneer u het start.",
        "This one checks inside apps themselves, so it is safer to confirm and run it live.": "Dit onderdeel kijkt in apps zelf, dus het is veiliger om het live te bevestigen en uit te voeren.",
        "This task speeds things up live and does not have separate cleanup parts.": "Deze taak versnelt dingen live en heeft geen losse onderdelen om apart op te schonen.",
        "macOS 26.x handles scheduled housekeeping in the background now. Open the report to see the current launchd status.": "macOS 26.x regelt gepland onderhoud nu op de achtergrond. Open het rapport om de huidige launchd-status te zien.",
        "This task opens or updates something, so there is nothing to remove beforehand.": "Deze taak opent of werkt iets bij, dus er is vooraf niets om te verwijderen.",
        "This task does a full safety scan first when you run it.": "Deze taak voert eerst een volledige veiligheidscontrole uit wanneer u haar start.",
        "This task depends on the app or settings you choose, so there is no fixed preview yet.": "Deze taak hangt af van de app of instellingen die u kiest, dus er is nog geen vaste preview.",
        "This opens a storage map first. Nothing is deleted until you decide what to remove.": "Dit opent eerst een opslagkaart. Er wordt niets verwijderd totdat u zelf kiest wat weg mag.",
        "This shows a read-only report of large and older files in Desktop, Documents, and Downloads.": "Dit toont een alleen-lezen rapport van grote en oudere bestanden in Bureaublad, Documenten en Downloads.",
        "This lists duplicate file candidates first and does not remove anything by itself.": "Dit toont eerst mogelijke dubbele bestanden en verwijdert zelf niets.",
        "This checks whether the helper tools the app needs are already installed.": "Dit controleert of de hulpmiddelen die de app nodig heeft al zijn geïnstalleerd."
        ,
        "Empty Trash?": "Prullenmand legen?",
        "Everything currently in the Trash will be deleted permanently.": "Alles wat nu in de prullenmand staat wordt definitief verwijderd.",
        "Delete system logs?": "Systeemlogboeken verwijderen?",
        "This removes local log files from /private/var/log and can make troubleshooting harder afterward.": "Dit verwijdert lokale logbestanden uit /private/var/log en kan probleemoplossing achteraf moeilijker maken.",
        "Remove language files?": "Taalbestanden verwijderen?",
        "This strips non-English localization folders from apps in /Applications.": "Dit verwijdert niet-Engelse lokalisatiemappen uit apps in /Applications.",
        "Remove Mail Downloads?": "Mail Downloads verwijderen?",
        "Downloaded Mail attachments stored in the local Mail Downloads folder will be removed.": "Gedownloade Mail-bijlagen die zijn opgeslagen in de lokale map Mail Downloads worden verwijderd.",
        "Install macOS updates?": "macOS-updates installeren?",
        "This can take a while and may affect system restart behavior afterward.": "Dit kan even duren en kan invloed hebben op het herstartgedrag van het systeem.",
        "Clear Safari history?": "Safari-geschiedenis wissen?",
        "This removes browsing history records from Safari on this Mac.": "Dit verwijdert browsegeschiedenis van Safari op deze Mac.",
        "Delete local iMessage data?": "Lokale iMessage-gegevens verwijderen?",
        "This removes local Messages database files from your account.": "Dit verwijdert lokale Berichten-databasebestanden uit uw account.",
        "Remove cookies?": "Cookies verwijderen?",
        "Websites may sign you out after cookie files are removed.": "Websites kunnen u uitloggen nadat cookiebestanden zijn verwijderd.",
        "Remove LaunchAgents?": "LaunchAgents verwijderen?",
        "This deletes every LaunchAgent in your user Library and can change startup behavior for apps.": "Dit verwijdert elke LaunchAgent in uw gebruikersbibliotheek en kan het opstartgedrag van apps veranderen.",
        "Enter the exact app name you want to remove from /Applications.": "Voer de exacte naam in van de app die u uit /Applications wilt verwijderen.",
        "Example: Safari": "Voorbeeld: Safari",
        "Remove app?": "App verwijderen?",
        "The selected app bundle will be deleted from /Applications.": "De geselecteerde app-bundle wordt verwijderd uit /Applications.",
        "Enter the bundle identifier to reset.": "Voer de bundle-identifier in die u wilt resetten.",
        "Example: com.vendor.app": "Voorbeeld: com.vendor.app",
        "Reset preferences?": "Voorkeuren resetten?",
        "The saved defaults for the selected bundle identifier will be deleted.": "De opgeslagen voorkeuren voor de geselecteerde bundle-identifier worden verwijderd.",
        "Continue": "Doorgaan",
        "Delete Logs": "Logbestanden verwijderen",
        "Remove Files": "Bestanden verwijderen",
        "Clear Attachments": "Bijlagen opschonen",
        "Install Updates": "Updates installeren",
        "Clear History": "Geschiedenis wissen",
        "Delete Data": "Gegevens verwijderen",
        "Remove Cookies": "Cookies verwijderen",
        "Remove Agents": "Agents verwijderen",
        "Remove App": "App verwijderen",
        "Reset Preferences": "Voorkeuren resetten",
        "Firefox cookie files can be reviewed and removed profile by profile.": "Firefox-cookiebestanden kunnen profiel voor profiel worden bekeken en verwijderd.",
        "No LaunchAgents were found in your user Library.": "Er zijn geen LaunchAgents gevonden in uw gebruikersbibliotheek."
    ]
}

#if DEVELOPER_BUILD
private let debugLanguageOverrideKey = "CleanMacAssistant.DebugLanguageOverride"

enum DebugLanguageOverride: String, CaseIterable, Identifiable {
    case system
    case english
    case dutch

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system:
            return "System"
        case .english:
            return "English"
        case .dutch:
            return "Nederlands"
        }
    }

    static func load() -> DebugLanguageOverride {
        guard let stored = UserDefaults.standard.string(forKey: debugLanguageOverrideKey),
              let value = DebugLanguageOverride(rawValue: stored)
        else {
            return .system
        }
        return value
    }

    func persist() {
        if self == .system {
            UserDefaults.standard.removeObject(forKey: debugLanguageOverrideKey)
        } else {
            UserDefaults.standard.set(rawValue, forKey: debugLanguageOverrideKey)
        }
    }

    static var currentResolvedLanguage: AppLanguage? {
        switch load() {
        case .system:
            return nil
        case .english:
            return .english
        case .dutch:
            return .dutch
        }
    }
}
#endif
