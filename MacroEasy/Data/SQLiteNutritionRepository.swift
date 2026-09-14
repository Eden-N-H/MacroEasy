//
//  SQLiteNutritionRepository.swift
//  MacroEasy
//
//  Created by Eden Hallett on 14/9/2026.
//

import Foundation
import SQLite3

final class SQLiteNutritionRepository: NutritionRepository {
    var db: OpaquePointer?
    let dbName = "MacroEasy.sqlite"
    let dateFormatter: DateFormatter

    init() {
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        openDatabase()
        createTables()
    }

    deinit {
        sqlite3_close(db)
    }

    func openDatabase() {
        let fileURL = try! FileManager.default
            .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appendingPathComponent(dbName)

        if sqlite3_open(fileURL.path, &db) != SQLITE_OK {
            print("Error opening database")
        }
    }

    func createTables() {
        let createMealEntriesTable = """
        CREATE TABLE IF NOT EXISTS meal_entries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            dishName TEXT NOT NULL,
            mealType TEXT NOT NULL,
            loggedAt TEXT NOT NULL,
            proteinGrams REAL NOT NULL,
            carbGrams REAL NOT NULL,
            fatGrams REAL NOT NULL,
            calories REAL NOT NULL
        );
        """

        let createSavedMealsTable = """
        CREATE TABLE IF NOT EXISTS saved_meals (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            dishName TEXT NOT NULL,
            proteinGrams REAL NOT NULL,
            carbGrams REAL NOT NULL,
            fatGrams REAL NOT NULL,
            calories REAL NOT NULL
        );
        """

        let createTargetsTable = """
        CREATE TABLE IF NOT EXISTS nutrition_targets (
            id INTEGER PRIMARY KEY CHECK (id = 1),
            goal TEXT NOT NULL,
            proteinGrams REAL NOT NULL,
            carbGrams REAL NOT NULL,
            fatGrams REAL NOT NULL,
            calories REAL NOT NULL
        );
        """

        for (label, sql) in [("meal_entries", createMealEntriesTable),
                              ("saved_meals", createSavedMealsTable),
                              ("nutrition_targets", createTargetsTable)] {
            var createTableStatement: OpaquePointer? = nil

            if sqlite3_prepare_v2(db, sql, -1, &createTableStatement, nil) == SQLITE_OK {
                if sqlite3_step(createTableStatement) == SQLITE_DONE {
                    print("Table \(label) created.")
                } else {
                    print("Table \(label) could not be created.")
                }
            } else {
                print("CREATE TABLE statement for \(label) could not be prepared.")
            }

            sqlite3_finalize(createTableStatement)
        }
    }

    // MARK: - Meal Entries

    @discardableResult
    func insertMealEntry(_ entry: MealEntry) throws -> MealEntry {
        let insertStatementString = """
        INSERT INTO meal_entries (dishName, mealType, loggedAt, proteinGrams, carbGrams, fatGrams, calories)
        VALUES (?, ?, ?, ?, ?, ?, ?);
        """
        var insertStatement: OpaquePointer? = nil

        guard sqlite3_prepare_v2(db, insertStatementString, -1, &insertStatement, nil) == SQLITE_OK else {
            print("INSERT statement for meal_entries could not be prepared.")
            sqlite3_finalize(insertStatement)
            throw RepositoryError.operationFailed("Could not prepare meal entry insert.")
        }

        let dateString = dateFormatter.string(from: entry.loggedAt)

        sqlite3_bind_text(insertStatement, 1, entry.dishName, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(insertStatement, 2, entry.mealType.rawValue, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(insertStatement, 3, dateString, -1, SQLITE_TRANSIENT)
        sqlite3_bind_double(insertStatement, 4, entry.proteinGrams)
        sqlite3_bind_double(insertStatement, 5, entry.carbGrams)
        sqlite3_bind_double(insertStatement, 6, entry.fatGrams)
        sqlite3_bind_double(insertStatement, 7, entry.calories)

        guard sqlite3_step(insertStatement) == SQLITE_DONE else {
            print("Could not insert meal entry.")
            sqlite3_finalize(insertStatement)
            throw RepositoryError.operationFailed("Could not insert meal entry.")
        }

        print("Successfully inserted meal entry.")
        let newID = sqlite3_last_insert_rowid(db)
        sqlite3_finalize(insertStatement)

        return MealEntry(
            id: newID,
            dishName: entry.dishName,
            mealType: entry.mealType,
            loggedAt: entry.loggedAt,
            proteinGrams: entry.proteinGrams,
            carbGrams: entry.carbGrams,
            fatGrams: entry.fatGrams,
            calories: entry.calories
        )
    }

    func fetchMealEntries(on date: Date) throws -> [MealEntry] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            throw RepositoryError.operationFailed("Could not compute day boundary.")
        }
        return try fetchMealEntries(from: startOfDay, to: endOfDay)
    }

    func fetchMealEntries(from startDate: Date, to endDate: Date) throws -> [MealEntry] {
        let fetchStatementString = """
        SELECT id, dishName, mealType, loggedAt, proteinGrams, carbGrams, fatGrams, calories
        FROM meal_entries
        WHERE loggedAt >= ? AND loggedAt < ?
        ORDER BY loggedAt ASC;
        """
        var fetchStatement: OpaquePointer? = nil
        var entries = [MealEntry]()

        guard sqlite3_prepare_v2(db, fetchStatementString, -1, &fetchStatement, nil) == SQLITE_OK else {
            print("SELECT statement for meal_entries could not be prepared.")
            sqlite3_finalize(fetchStatement)
            throw RepositoryError.operationFailed("Could not prepare meal entry fetch.")
        }

        sqlite3_bind_text(fetchStatement, 1, dateFormatter.string(from: startDate), -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(fetchStatement, 2, dateFormatter.string(from: endDate), -1, SQLITE_TRANSIENT)

        while sqlite3_step(fetchStatement) == SQLITE_ROW {
            let id = sqlite3_column_int64(fetchStatement, 0)
            let dishName = String(cString: sqlite3_column_text(fetchStatement, 1))
            let mealTypeString = String(cString: sqlite3_column_text(fetchStatement, 2))
            let dateString = String(cString: sqlite3_column_text(fetchStatement, 3))

            guard let mealType = MealType(rawValue: mealTypeString),
                  let loggedAt = dateFormatter.date(from: dateString) else {
                continue
            }

            let entry = MealEntry(
                id: id,
                dishName: dishName,
                mealType: mealType,
                loggedAt: loggedAt,
                proteinGrams: sqlite3_column_double(fetchStatement, 4),
                carbGrams: sqlite3_column_double(fetchStatement, 5),
                fatGrams: sqlite3_column_double(fetchStatement, 6),
                calories: sqlite3_column_double(fetchStatement, 7)
            )
            entries.append(entry)
        }

        print("Fetched \(entries.count) meal entries.")
        sqlite3_finalize(fetchStatement)
        return entries
    }

    func deleteMealEntry(id: Int64) throws {
        let deleteStatementString = "DELETE FROM meal_entries WHERE id = ?;"
        var deleteStatement: OpaquePointer? = nil

        guard sqlite3_prepare_v2(db, deleteStatementString, -1, &deleteStatement, nil) == SQLITE_OK else {
            print("DELETE statement for meal_entries could not be prepared.")
            sqlite3_finalize(deleteStatement)
            throw RepositoryError.operationFailed("Could not prepare meal entry delete.")
        }

        sqlite3_bind_int64(deleteStatement, 1, id)
        guard sqlite3_step(deleteStatement) == SQLITE_DONE else {
            print("Could not delete meal entry.")
            sqlite3_finalize(deleteStatement)
            throw RepositoryError.operationFailed("Could not delete meal entry.")
        }

        print("Successfully deleted meal entry.")
        sqlite3_finalize(deleteStatement)
    }

    // MARK: - Saved Meals

    @discardableResult
    func saveMealTemplate(_ meal: SavedMeal) throws -> SavedMeal {
        let insertStatementString = """
        INSERT INTO saved_meals (dishName, proteinGrams, carbGrams, fatGrams, calories)
        VALUES (?, ?, ?, ?, ?);
        """
        var insertStatement: OpaquePointer? = nil

        guard sqlite3_prepare_v2(db, insertStatementString, -1, &insertStatement, nil) == SQLITE_OK else {
            print("INSERT statement for saved_meals could not be prepared.")
            sqlite3_finalize(insertStatement)
            throw RepositoryError.operationFailed("Could not prepare saved meal insert.")
        }

        sqlite3_bind_text(insertStatement, 1, meal.dishName, -1, SQLITE_TRANSIENT)
        sqlite3_bind_double(insertStatement, 2, meal.proteinGrams)
        sqlite3_bind_double(insertStatement, 3, meal.carbGrams)
        sqlite3_bind_double(insertStatement, 4, meal.fatGrams)
        sqlite3_bind_double(insertStatement, 5, meal.calories)

        guard sqlite3_step(insertStatement) == SQLITE_DONE else {
            print("Could not save meal template.")
            sqlite3_finalize(insertStatement)
            throw RepositoryError.operationFailed("Could not save meal template.")
        }

        print("Successfully saved meal template.")
        let newID = sqlite3_last_insert_rowid(db)
        sqlite3_finalize(insertStatement)

        return SavedMeal(
            id: newID,
            dishName: meal.dishName,
            proteinGrams: meal.proteinGrams,
            carbGrams: meal.carbGrams,
            fatGrams: meal.fatGrams,
            calories: meal.calories
        )
    }

    func fetchSavedMeals() throws -> [SavedMeal] {
        let fetchStatementString = """
        SELECT id, dishName, proteinGrams, carbGrams, fatGrams, calories
        FROM saved_meals
        ORDER BY dishName ASC;
        """
        var fetchStatement: OpaquePointer? = nil
        var meals = [SavedMeal]()

        guard sqlite3_prepare_v2(db, fetchStatementString, -1, &fetchStatement, nil) == SQLITE_OK else {
            print("SELECT statement for saved_meals could not be prepared.")
            sqlite3_finalize(fetchStatement)
            throw RepositoryError.operationFailed("Could not prepare saved meal fetch.")
        }

        while sqlite3_step(fetchStatement) == SQLITE_ROW {
            let id = sqlite3_column_int64(fetchStatement, 0)
            let dishName = String(cString: sqlite3_column_text(fetchStatement, 1))

            let meal = SavedMeal(
                id: id,
                dishName: dishName,
                proteinGrams: sqlite3_column_double(fetchStatement, 2),
                carbGrams: sqlite3_column_double(fetchStatement, 3),
                fatGrams: sqlite3_column_double(fetchStatement, 4),
                calories: sqlite3_column_double(fetchStatement, 5)
            )
            meals.append(meal)
        }

        print("Fetched \(meals.count) saved meals.")
        sqlite3_finalize(fetchStatement)
        return meals
    }

    func deleteSavedMeal(id: Int64) throws {
        let deleteStatementString = "DELETE FROM saved_meals WHERE id = ?;"
        var deleteStatement: OpaquePointer? = nil

        guard sqlite3_prepare_v2(db, deleteStatementString, -1, &deleteStatement, nil) == SQLITE_OK else {
            print("DELETE statement for saved_meals could not be prepared.")
            sqlite3_finalize(deleteStatement)
            throw RepositoryError.operationFailed("Could not prepare saved meal delete.")
        }

        sqlite3_bind_int64(deleteStatement, 1, id)
        guard sqlite3_step(deleteStatement) == SQLITE_DONE else {
            print("Could not delete saved meal.")
            sqlite3_finalize(deleteStatement)
            throw RepositoryError.operationFailed("Could not delete saved meal.")
        }

        print("Successfully deleted saved meal.")
        sqlite3_finalize(deleteStatement)
    }

    // MARK: - Nutrition Targets

    func fetchNutritionTargets() throws -> NutritionTargets? {
        let fetchStatementString = """
        SELECT goal, proteinGrams, carbGrams, fatGrams, calories
        FROM nutrition_targets
        WHERE id = 1;
        """
        var fetchStatement: OpaquePointer? = nil

        guard sqlite3_prepare_v2(db, fetchStatementString, -1, &fetchStatement, nil) == SQLITE_OK else {
            print("SELECT statement for nutrition_targets could not be prepared.")
            sqlite3_finalize(fetchStatement)
            throw RepositoryError.operationFailed("Could not prepare targets fetch.")
        }

        guard sqlite3_step(fetchStatement) == SQLITE_ROW else {
            print("No nutrition targets set yet.")
            sqlite3_finalize(fetchStatement)
            return nil
        }

        let goalString = String(cString: sqlite3_column_text(fetchStatement, 0))
        guard let goal = NutritionGoal(rawValue: goalString) else {
            sqlite3_finalize(fetchStatement)
            throw RepositoryError.operationFailed("Stored goal value was invalid.")
        }

        let targets = NutritionTargets(
            goal: goal,
            proteinGrams: sqlite3_column_double(fetchStatement, 1),
            carbGrams: sqlite3_column_double(fetchStatement, 2),
            fatGrams: sqlite3_column_double(fetchStatement, 3),
            calories: sqlite3_column_double(fetchStatement, 4)
        )

        print("Successfully fetched nutrition targets.")
        sqlite3_finalize(fetchStatement)
        return targets
    }

    func saveNutritionTargets(_ targets: NutritionTargets) throws {
        let upsertStatementString = """
        INSERT INTO nutrition_targets (id, goal, proteinGrams, carbGrams, fatGrams, calories)
        VALUES (1, ?, ?, ?, ?, ?)
        ON CONFLICT(id) DO UPDATE SET
            goal = excluded.goal,
            proteinGrams = excluded.proteinGrams,
            carbGrams = excluded.carbGrams,
            fatGrams = excluded.fatGrams,
            calories = excluded.calories;
        """
        var upsertStatement: OpaquePointer? = nil

        guard sqlite3_prepare_v2(db, upsertStatementString, -1, &upsertStatement, nil) == SQLITE_OK else {
            print("UPSERT statement for nutrition_targets could not be prepared.")
            sqlite3_finalize(upsertStatement)
            throw RepositoryError.operationFailed("Could not prepare targets save.")
        }

        sqlite3_bind_text(upsertStatement, 1, targets.goal.rawValue, -1, SQLITE_TRANSIENT)
        sqlite3_bind_double(upsertStatement, 2, targets.proteinGrams)
        sqlite3_bind_double(upsertStatement, 3, targets.carbGrams)
        sqlite3_bind_double(upsertStatement, 4, targets.fatGrams)
        sqlite3_bind_double(upsertStatement, 5, targets.calories)

        guard sqlite3_step(upsertStatement) == SQLITE_DONE else {
            print("Could not save nutrition targets.")
            sqlite3_finalize(upsertStatement)
            throw RepositoryError.operationFailed("Could not save nutrition targets.")
        }

        print("Successfully saved nutrition targets.")
        sqlite3_finalize(upsertStatement)
    }
}

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
