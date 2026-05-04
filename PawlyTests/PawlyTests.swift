import XCTest
import SwiftData
@testable import Pawly

final class PawlyTests: XCTestCase {

    // MARK: - Recurrence codec round-trip

    func test_recurrence_rawString_roundTrip() {
        let cases: [Recurrence] = [
            .once,
            .daily,
            .everyNDays(3),
            .weekly(weekdays: [1, 3, 5]),
            .monthly(day: 15),
            .everyNMonths(3, day: 10)
        ]
        for c in cases {
            let raw = c.rawString
            let decoded = Recurrence(rawString: raw)
            XCTAssertEqual(decoded, c, "Round-trip failed for \(c) -> \(raw)")
        }
    }

    func test_recurrence_rejects_invalid_rawString() {
        XCTAssertNil(Recurrence(rawString: "everyNDays:0"))
        XCTAssertNil(Recurrence(rawString: "weekly:9"))
        XCTAssertNil(Recurrence(rawString: "monthly:31"))
        XCTAssertNil(Recurrence(rawString: "garbage"))
    }

    // MARK: - RecurrenceEngine

    private func makeDate(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 9, cal: Calendar = .current) -> Date {
        var comps = DateComponents()
        comps.year = y; comps.month = m; comps.day = d; comps.hour = h; comps.minute = 0
        return cal.date(from: comps)!
    }

    func test_engine_once() {
        let start = makeDate(2026, 5, 1)
        let end = makeDate(2026, 6, 1)
        let dates = RecurrenceEngine.occurrences(
            recurrence: .once,
            firstDueAt: makeDate(2026, 5, 10),
            in: start..<end
        )
        XCTAssertEqual(dates.count, 1)
    }

    func test_engine_daily_spans_range() {
        let start = makeDate(2026, 5, 1)
        let end = makeDate(2026, 5, 8)
        let dates = RecurrenceEngine.occurrences(
            recurrence: .daily,
            firstDueAt: makeDate(2026, 5, 1),
            in: start..<end
        )
        XCTAssertEqual(dates.count, 7)  // 1..7 inclusive, 8 excluded
    }

    func test_engine_everyNDays() {
        let start = makeDate(2026, 5, 1)
        let end = makeDate(2026, 5, 15)
        let dates = RecurrenceEngine.occurrences(
            recurrence: .everyNDays(3),
            firstDueAt: makeDate(2026, 5, 1),
            in: start..<end
        )
        // 1, 4, 7, 10, 13 — 5 occurrences before May 15
        XCTAssertEqual(dates.count, 5)
    }

    func test_engine_weekly_picks_matching_days() {
        // May 1 2026 is a Friday (weekday 6). Select Mon(2) and Wed(4) only.
        let start = makeDate(2026, 5, 1)
        let end = makeDate(2026, 5, 15)
        let dates = RecurrenceEngine.occurrences(
            recurrence: .weekly(weekdays: [2, 4]),
            firstDueAt: makeDate(2026, 5, 1),
            in: start..<end
        )
        let cal = Calendar.current
        for d in dates {
            let wd = cal.component(.weekday, from: d)
            XCTAssertTrue(wd == 2 || wd == 4, "Weekday should be Mon or Wed, got \(wd)")
        }
        XCTAssertFalse(dates.isEmpty)
    }

    func test_engine_monthly_honors_day_of_month() {
        let start = makeDate(2026, 5, 1)
        let end = makeDate(2026, 12, 1)
        let dates = RecurrenceEngine.occurrences(
            recurrence: .monthly(day: 15),
            firstDueAt: makeDate(2026, 5, 1),
            in: start..<end
        )
        let cal = Calendar.current
        for d in dates {
            XCTAssertEqual(cal.component(.day, from: d), 15)
        }
        XCTAssertEqual(dates.count, 7)  // May..Nov on the 15th
    }

    // MARK: - GroqService fallback (offline keyword heuristics)

    func test_aiDoctor_classifies_emergency() async {
        let r = await GroqService.respond(to: "My dog is coughing up blood!")
        XCTAssertEqual(r.urgency, .vetNow)
    }

    func test_aiDoctor_classifies_vomit_as_24h() async {
        let r = await GroqService.respond(to: "Vomited twice this morning")
        XCTAssertEqual(r.urgency, .vetWithin24h)
    }

    func test_aiDoctor_classifies_itch_as_watch_at_home() async {
        let r = await GroqService.respond(to: "He keeps scratching his ears")
        XCTAssertEqual(r.urgency, .watchAtHome)
    }

    func test_aiDoctor_default_is_low_confidence() async {
        let r = await GroqService.respond(to: "Something seems off")
        XCTAssertEqual(r.confidence, .low)
    }

    func test_aiDoctor_all_responses_have_four_parts() async {
        let prompts = ["blood", "vomit", "scratching", "lethargy", "something else"]
        for p in prompts {
            let r = await GroqService.respond(to: p)
            XCTAssertFalse(r.whatMightBeHappening.isEmpty)
            XCTAssertFalse(r.whatYouCanDoNow.isEmpty)
            XCTAssertFalse(r.whenToEscalate.isEmpty)
            XCTAssertFalse(r.userPrompt.isEmpty)
        }
    }

    // MARK: - Seed smoke test

    @MainActor
    func test_seed_inserts_pets_and_reminders() throws {
        let schema = Schema([Pet.self, Reminder.self, ReminderInstance.self, LogEntry.self, MoodEntry.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let ctx = container.mainContext
        SeedData.seed(into: ctx)
        try ctx.save()

        let pets = try ctx.fetch(FetchDescriptor<Pet>())
        XCTAssertEqual(pets.count, 2)

        let reminders = try ctx.fetch(FetchDescriptor<Reminder>())
        XCTAssertEqual(reminders.count, 3)

        let instances = try ctx.fetch(FetchDescriptor<ReminderInstance>())
        XCTAssertGreaterThan(instances.count, 0)
    }

    // MARK: - Pet computed accessors

    func test_pet_ageDescription_for_known_dob() {
        let twoYearsAgo = Calendar.current.date(byAdding: .year, value: -2, to: .now)
        let pet = Pet(name: "Rex", species: .dog, dateOfBirth: twoYearsAgo)
        XCTAssertTrue(pet.ageDescription.contains("2y"))
    }

    func test_pet_ageDescription_when_nil() {
        let pet = Pet(name: "Ghost", species: .cat)
        XCTAssertEqual(pet.ageDescription, "Unknown age")
    }
}
