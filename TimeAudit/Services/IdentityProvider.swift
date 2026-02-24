import Foundation

// MARK: - Identity Provider

/// Central class for all mode-dependent strings and content.
/// Dynamically returns wording based on the active IdentityMode.
@Observable
final class IdentityProvider {

    /// Current identity mode
    var mode: IdentityMode = .standard

    // MARK: - Category Names

    /// Get the display name for a category in the current mode
    func categoryName(for category: ActivityCategory) -> String {
        switch mode {
        case .standard:
            return category.displayName
        case .faith:
            switch category {
            case .productive: return "Frucht bringen / Berufung"
            case .neutral: return "Verwalten"
            case .harmful: return "Verschwendung / Suende"
            }
        }
    }

    // MARK: - Score Names

    /// The name used for the focus/stewardship score
    var scoreName: String {
        switch mode {
        case .standard: return "Focus Score"
        case .faith: return "Stewardship Score"
        }
    }

    // MARK: - Intervention Texts

    /// Title for the intervention popup
    var interventionTitle: String {
        switch mode {
        case .standard: return "Fokus-Verlust erkannt"
        case .faith: return "Gaben-Verschwendung erkannt"
        }
    }

    /// Message for the intervention popup
    var interventionMessage: String {
        switch mode {
        case .standard:
            return "Willst du 1 Min. durchatmen, um den Loop zu brechen?"
        case .faith:
            return "Halte kurz inne fuer ein Stossgebet oder einen Moment der Umkehr."
        }
    }

    /// Button text for the intervention
    var interventionActionLabel: String {
        switch mode {
        case .standard: return "Durchatmen"
        case .faith: return "Stossgebet"
        }
    }

    // MARK: - Mission Bar

    /// Label for the mission bar
    func missionBarLabel(units: Int, goal: Int) -> String {
        switch mode {
        case .standard:
            return "\(units) / \(goal) Einheiten heute"
        case .faith:
            return "Treue im Kleinen: \(units) / \(goal) Einheiten heute"
        }
    }

    // MARK: - Daily Impulse

    /// Get a daily impulse (quote or verse) based on mode
    /// Changes daily using a date-based seed
    func dailyImpulse() -> (text: String, source: String) {
        let dayIndex = Calendar.current.ordinality(of: .day, in: .year, for: .now) ?? 0

        switch mode {
        case .standard:
            let index = dayIndex % productivityQuotes.count
            return productivityQuotes[index]
        case .faith:
            let index = dayIndex % bibleVerses.count
            return bibleVerses[index]
        }
    }

    // MARK: - Productivity Quotes

    private let productivityQuotes: [(text: String, source: String)] = [
        ("Die beste Zeit, einen Baum zu pflanzen, war vor 20 Jahren. Die zweitbeste Zeit ist jetzt.", "Chinesisches Sprichwort"),
        ("Fokus bedeutet Nein sagen zu den hundert anderen guten Ideen.", "Steve Jobs"),
        ("Der Weg zum Erfolg beginnt mit dem ersten Schritt.", "Lao Tzu"),
        ("Was du heute tust, entscheidet, wer du morgen bist.", "James Clear"),
        ("Disziplin ist die Bruecke zwischen Zielen und Erfolg.", "Jim Rohn"),
        ("Kleine Schritte jeden Tag fuehren zu grossen Veraenderungen.", "Unbekannt"),
        ("Produktivitaet ist nie ein Zufall. Sie ist das Ergebnis kluger Planung.", "Paul J. Meyer"),
        ("Nicht die Stunden zaehlen, sondern was du in den Stunden tust.", "Unbekannt"),
        ("Die Kraft der Konzentration kann einen Laserstrahl aus Sonnenlicht machen.", "Unbekannt"),
        ("Jede grosse Reise beginnt mit einem einzigen Schritt.", "Konfuzius"),
        ("Dein zukuenftiges Ich wird dir danken.", "Unbekannt"),
        ("Fortschritt, nicht Perfektion, ist das Ziel.", "Unbekannt"),
        ("Handle so, als waere es unmoeglich zu scheitern.", "Dorothea Brande"),
        ("Die beste Art, die Zukunft vorherzusagen, ist sie zu gestalten.", "Peter Drucker"),
        ("Erfolg ist die Summe kleiner Anstrengungen, Tag fuer Tag wiederholt.", "Robert Collier"),
        ("Wer immer tut, was er schon kann, bleibt immer das, was er schon ist.", "Henry Ford"),
        ("Motivation bringt dich in Gang. Gewohnheit haelt dich in Schwung.", "Jim Ryun"),
        ("Es ist nicht zu wenig Zeit. Wir verschwenden nur zu viel davon.", "Seneca"),
        ("Der einzige Weg, grossartige Arbeit zu leisten, ist zu lieben, was man tut.", "Steve Jobs"),
        ("Beginne dort, wo du bist. Nutze, was du hast. Tu, was du kannst.", "Arthur Ashe"),
    ]

    // MARK: - Bible Verses

    private let bibleVerses: [(text: String, source: String)] = [
        ("Was ihr auch tut, arbeitet von Herzen als fuer den Herrn.", "Kolosser 3:23"),
        ("Befiehl dem Herrn deine Werke, so werden deine Plaene gelingen.", "Sprueche 16:3"),
        ("Wer im Geringsten treu ist, der ist auch im Grossen treu.", "Lukas 16:10"),
        ("Ich vermag alles durch den, der mich maechtig macht.", "Philipper 4:13"),
        ("Lass dich nicht vom Boesen ueberwinden, sondern ueberwinde das Boese mit Gutem.", "Roemer 12:21"),
        ("Lehre uns bedenken, dass wir sterben muessen, auf dass wir klug werden.", "Psalm 90:12"),
        ("Es ist umsonst, dass ihr fruehmorgends aufsteht und spaeabends aufbleibt; denn er gibt es den Seinen im Schlaf.", "Psalm 127:2"),
        ("Seid stille und erkennet, dass ich Gott bin.", "Psalm 46:11"),
        ("Die auf den Herrn harren, kriegen neue Kraft.", "Jesaja 40:31"),
        ("Jede gute Gabe und jedes vollkommene Geschenk kommt von oben herab.", "Jakobus 1:17"),
        ("Denn wir sind sein Werk, geschaffen in Christus Jesus zu guten Werken.", "Epheser 2:10"),
        ("Kauft die Zeit aus, denn die Tage sind boese.", "Epheser 5:16"),
        ("Sorgt euch um nichts, sondern in allen Dingen lasst eure Bitten in Gebet und Flehen mit Danksagung vor Gott kundwerden.", "Philipper 4:6"),
        ("Der Herr ist mein Hirte, mir wird nichts mangeln.", "Psalm 23:1"),
        ("Seid froehlich in Hoffnung, geduldig in Truebsal, beharrlich im Gebet.", "Roemer 12:12"),
        ("Meine Gnade genuegt dir; denn meine Kraft ist in den Schwachen maechtig.", "2. Korinther 12:9"),
        ("Trachtet zuerst nach dem Reich Gottes und nach seiner Gerechtigkeit.", "Matthaeus 6:33"),
        ("Alles hat seine Zeit, und alles Vorhaben unter dem Himmel hat seine Stunde.", "Prediger 3:1"),
        ("Er hat alles schoen gemacht zu seiner Zeit.", "Prediger 3:11"),
        ("Ich bin der Weinstock, ihr seid die Reben. Wer in mir bleibt und ich in ihm, der bringt viel Frucht.", "Johannes 15:5"),
    ]
}
