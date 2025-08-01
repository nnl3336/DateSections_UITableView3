//
//  CoreDataManager.swift
//  DateSections_UITableView3
//
//  Created by Yuki Sasaki on 2025/08/01.
//

import SwiftUI
import CoreData


class CoreDataManager {
    static let shared = CoreDataManager()

    let container: NSPersistentContainer

    private init() {
        container = NSPersistentContainer(name: "DateSections_UITableView3") // ← .xcdatamodeld の名前
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Core Data load error: \(error)")
            }
        }
    }

    var context: NSManagedObjectContext {
        container.viewContext
    }

    func saveContext() {
        let context = container.viewContext
        if context.hasChanges {
            try? context.save()
        }
    }
}
