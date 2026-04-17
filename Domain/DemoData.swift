import Foundation

enum DemoData {
    static func sampleProject(language: AppLanguage) -> DubProject {
        let actorNames = demoActorNames(language: language)
        let anna = Actor(displayName: actorNames.anna)
        let peter = Actor(displayName: actorNames.peter)
        let clara = Actor(displayName: actorNames.clara)

        let neal = Character(name: "NEAL", rawSourceSamples: ["61NEAL"], assignedActorID: anna.id)
        let erik = Character(name: "ERIK", rawSourceSamples: ["62ERIK"], assignedActorID: peter.id)
        let miss = Character(name: "MISS", rawSourceSamples: ["63MISS"], assignedActorID: anna.id)
        let margory = Character(name: "MARGORY", rawSourceSamples: ["64MARGORY"], assignedActorID: clara.id)
        let peterCharacter = Character(name: "PETER", rawSourceSamples: ["65PETER"], assignedActorID: peter.id)

        let characterIDsBySource = [
            "61NEAL": neal.id,
            "62ERIK": erik.id,
            "63MISS": miss.id,
            "64MARGORY": margory.id,
            "65PETER": peterCharacter.id,
        ]

        let cues = cueBlueprints(language: language).enumerated().map { index, blueprint in
            makeCue(
                index: index + 1,
                rawSource: blueprint.rawSource,
                characterID: characterIDsBySource[blueprint.rawSource] ?? neal.id,
                dialogue: blueprint.dialogue
            )
        }

        return DubProject(
            name: AppStrings.text("demo.project_name", language: language),
            sourceFileName: "demo.xlsx",
            selectedCueID: cues.first?.id,
            displayContextCount: 2,
            actors: [anna, peter, clara],
            characters: [neal, erik, miss, margory, peterCharacter],
            cues: cues
        )
    }

    private static func demoActorNames(language: AppLanguage) -> (anna: String, peter: String, clara: String) {
        switch language {
        case .english:
            return ("Anna", "Peter", "Clara")
        case .czech:
            return ("Anna", "Petr", "Klára")
        }
    }

    private static func cueBlueprints(language: AppLanguage) -> [(rawSource: String, dialogue: String)] {
        switch language {
        case .english:
            return englishCueBlueprints
        case .czech:
            return czechCueBlueprints
        }
    }

    private static let englishCueBlueprints: [(rawSource: String, dialogue: String)] = [
        ("61NEAL", "You can ask in person."),
        ("62ERIK", "This place is getting suspiciously quiet."),
        ("64MARGORY", "Do not turn around. Just listen to my voice."),
        ("65PETER", "I told you this would be a bad idea."),
        ("63MISS", "Everyone in this room will die."),
        ("61NEAL", "Just sit still. We will get you a ride."),
        ("62ERIK", "Why does my head hurt this much?"),
        ("64MARGORY", ""),
        ("65PETER", "I need five minutes and a strong coffee."),
        ("63MISS", "No one is leaving this place clean."),
        ("61NEAL", "You have no idea what you woke up."),
        ("62ERIK", "All right. Who is up first today?"),
        ("64MARGORY", "Camera is top left. Do not lose it."),
        ("65PETER", "When it breaks, do not say I did not warn you."),
        ("63MISS", "Your grace period is over."),
        ("61NEAL", "Let me finish and then play the hero."),
        ("62ERIK", "I do not play hero. I just clean up."),
        ("64MARGORY", "Three guards behind that door and no plan."),
        ("65PETER", "The plan is simple. Stay alive until lunch."),
        ("63MISS", "I can hear your fear across the hall."),
        ("61NEAL", "One more step and you trigger the whole alarm."),
        ("62ERIK", "Then let us try without that step."),
        ("64MARGORY", "Erik, down. Right now."),
        ("65PETER", ""),
        ("63MISS", "Too late. You are already inside."),
        ("61NEAL", "Good. Go. I will hold them here."),
        ("62ERIK", "This never works out smoothly, does it?"),
        ("64MARGORY", "Smooth is not in the budget."),
        ("65PETER", "My car is in a tow zone, so move."),
        ("63MISS", "Your escape was already part of the calculation."),
        ("61NEAL", "Who said anything about escaping?"),
        ("62ERIK", "I am aiming for a stylish exit."),
        ("64MARGORY", "Save the style for later. Load up and cover."),
        ("65PETER", "I hear gunfire. I am taking that as a yes."),
        ("63MISS", "Every shot leads you closer to me."),
        ("61NEAL", "That sounded arrogant even for a psychopath."),
        ("62ERIK", "I kind of like it."),
        ("64MARGORY", "Erik, focus."),
        ("65PETER", "If you could avoid wrecking a third car, I would appreciate it."),
        ("63MISS", ""),
        ("61NEAL", "I see a service corridor. This way."),
        ("62ERIK", "Perfect. Tight space and bad lighting."),
        ("64MARGORY", "Stop commenting and move."),
        ("65PETER", "You have company from the left on my monitor."),
        ("63MISS", "I do not need to see you. Your breathing is enough."),
        ("61NEAL", "Then help yourself to the last breath."),
        ("62ERIK", "Still better than another briefing."),
        ("64MARGORY", "Target is in front of you. Open it."),
        ("65PETER", "If there is another door behind that one, I quit."),
        ("63MISS", "Welcome exactly where I wanted you."),
    ]

    private static let czechCueBlueprints: [(rawSource: String, dialogue: String)] = [
        ("61NEAL", "Můžeš se zeptat osobně."),
        ("62ERIK", "Tohle místo mi přijde až podezřele tiché."),
        ("64MARGORY", "Neotáčej se, jen poslouchej můj hlas."),
        ("65PETER", "Říkal jsem ti, že to bude špatný nápad."),
        ("63MISS", "Všichni přítomní zemřete."),
        ("61NEAL", "Jen seď. Zavoláme ti odvoz."),
        ("62ERIK", "Proč mě tak hrozně bolí hlava?"),
        ("64MARGORY", ""),
        ("65PETER", "Potřebuju pět minut a silnou kávu."),
        ("63MISS", "Nikdo odsud neodejde čistý."),
        ("61NEAL", "Nemáš vůbec ponětí, co jsi probudil."),
        ("62ERIK", "Tak jo. Kdo je dneska první na řadě?"),
        ("64MARGORY", "Vlevo nahoře je kamera, neztrať ji."),
        ("65PETER", "Když se to rozbije, neříkej, že jsem nevaroval."),
        ("63MISS", "Čas milosti právě skončil."),
        ("61NEAL", "Nech mě domluvit a pak dělej hrdinu."),
        ("62ERIK", "Já hrdinu nedělám, já to jen uklízím."),
        ("64MARGORY", "Za dveřmi máš tři stráže a žádný plán."),
        ("65PETER", "Plán je jednoduchý. Přežít do oběda."),
        ("63MISS", "Slyším tvůj strach na druhém konci haly."),
        ("61NEAL", "Ještě krok a spustíš celý alarm."),
        ("62ERIK", "Tak to zkusme bez toho kroku."),
        ("64MARGORY", "Eriku, teď hned dolů."),
        ("65PETER", ""),
        ("63MISS", "Pozdě. Už jsi uvnitř."),
        ("61NEAL", "Dobře. Teď běž, já je zdržím."),
        ("62ERIK", "Tohle nikdy nefunguje tak hladce, co?"),
        ("64MARGORY", "Na hladký průběh nemáme rozpočet."),
        ("65PETER", "Mám auto v zákazu, tak si pospěšte."),
        ("63MISS", "Váš útěk byl započítán do výpočtu."),
        ("61NEAL", "Kdo vůbec mluví o útěku?"),
        ("62ERIK", "Já mluvím spíš o stylovém odchodu."),
        ("64MARGORY", "Styl nech na potom. Nabij a kryj."),
        ("65PETER", "Slyším střelbu. To beru jako ano."),
        ("63MISS", "Každá rána vás vede blíž ke mně."),
        ("61NEAL", "To znělo dost namyšleně i na psychopata."),
        ("62ERIK", "Mně se to docela líbí."),
        ("64MARGORY", "Eriku, soustřeď se."),
        ("65PETER", "Kdybyste mohli nezničit i třetí auto, ocením to."),
        ("63MISS", ""),
        ("61NEAL", "Vidím servisní chodbu. Tudy."),
        ("62ERIK", "Výborně. Úzký prostor a špatné světlo."),
        ("64MARGORY", "Přestaň komentovat a hýbej se."),
        ("65PETER", "Na monitoru máte společnost zleva."),
        ("63MISS", "Nemusím vás vidět. Stačí mi váš dech."),
        ("61NEAL", "Tak si posluž posledním."),
        ("62ERIK", "Pořád lepší než další briefing."),
        ("64MARGORY", "Cíl je před tebou. Otevři to."),
        ("65PETER", "Jestli za tím jsou další dveře, končím."),
        ("63MISS", "Vítejte přesně tam, kde jsem vás chtěl mít."),
    ]

    private static func makeCue(
        index: Int,
        rawSource: String,
        characterID: UUID,
        dialogue: String
    ) -> Cue {
        Cue(
            index: index,
            rawSource: rawSource,
            characterID: characterID,
            inTimecode: timecode(for: index),
            dialogue: dialogue,
            wordCount: wordCount(for: dialogue)
        )
    }

    private static func timecode(for index: Int) -> String {
        let totalSeconds = 44 + ((index - 1) * 19) + (((index - 1) % 4) * 3)
        let frames = [0, 8, 12, 16, 20][(index - 1) % 5]
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d:%02d:%02d", hours, minutes, seconds, frames)
    }

    private static func wordCount(for dialogue: String) -> Int {
        dialogue.split(whereSeparator: \.isWhitespace).count
    }
}
