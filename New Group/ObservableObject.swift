//
//  ObservableObject.swift
//  DateSections_UITableView3
//
//  Created by Yuki Sasaki on 2025/08/02.
//

import SwiftUI
import CoreData
import Foundation
import Combine

// MARK: - TextView

class TextViewManager: ObservableObject {
    @Published var selectLiked: Bool = false
    @Published var selectCheck: Bool = false
}


// MARK: - Color 

class AccentColorManager {
    static let shared = AccentColorManager()

    private let userDefaultsKey = "isAC"

    enum AccentColorEnum: String {
        case blue, red, green, yellow

        var uiColor: UIColor {
            switch self {
            case .blue: return .systemBlue
            case .red: return .systemRed
            case .green: return .systemGreen
            case .yellow: return .systemYellow
            }
        }
    }

    private(set) var currentColor: AccentColorEnum = .blue

    private init() {
        loadColor()
    }

    func loadColor() {
        if let rawValue = UserDefaults.standard.string(forKey: userDefaultsKey),
           let color = AccentColorEnum(rawValue: rawValue) {
            currentColor = color
        }
    }

    func saveColor(_ color: AccentColorEnum) {
        currentColor = color
        UserDefaults.standard.set(color.rawValue, forKey: userDefaultsKey)
    }
}

// MARK: - Message

class MessageStore: NSObject, ObservableObject, NSFetchedResultsControllerDelegate {
    @Published var messages: [MessageEntity] = []
    @Published var selectedMessage: MessageEntity?
    @Published var selectedMessages: [MessageEntity] = []

    private let context = CoreDataManager.shared.context
    private var fetchedResultsController: NSFetchedResultsController<MessageEntity>!

    override init() {
        super.init()
        setupFetchedResultsController()
    }

    init(message: MessageEntity) {
        super.init()
        self.selectedMessage = message
        setupFetchedResultsController()
    }

    func setupFetchedResultsController() {
        let fetchRequest: NSFetchRequest<MessageEntity> = MessageEntity.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]

        fetchedResultsController = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil)

        fetchedResultsController.delegate = self

        do {
            try fetchedResultsController.performFetch()
            messages = fetchedResultsController.fetchedObjects ?? []
        } catch {
            print("Failed to fetch: \(error)")
        }
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        messages = fetchedResultsController.fetchedObjects ?? []
    }
    
    // MARK: - save
    
    // CoreDataManager.swift
    func createMessage() -> MessageEntity {
        let message = MessageEntity(context: context)
        message.date = Date()  // 必要に応じて初期化
        return message
    }
    
    func updateMessage(_ message: MessageEntity, withAttributedText attributedText: NSMutableAttributedString) {
        print("🔷 updateMessage called.")

        // 🔸 空なら削除
        if attributedText.length == 0 {
            print("🗑 Empty content. Deleting message.")
            CoreDataManager.shared.context.delete(message)
            CoreDataManager.shared.saveContext()
            print("💾 Deleted empty message and saved context.")
            return
        }

        guard let data = try? attributedText.data(
            from: NSRange(location: 0, length: attributedText.length),
            documentAttributes: [.documentType: NSAttributedString.DocumentType.rtfd]
        ) else {
            print("❌ Failed to convert attributedText to data.")
            return
        }

        if message.attributedText != data {
            print("🆕 Content changed. Updating and saving.")
            message.attributedText = data
            CoreDataManager.shared.saveContext()
            print("💾 CoreDataManager.saveContext() called.")
        } else {
            print("⚪️ No changes detected. Skipping save.")
        }

        print("✅ Message update complete.")
        // fetchMessages() は不要。FRCが反応するので
    }




    func addMessage(_ attributedText: NSMutableAttributedString, selectedMessage: MessageEntity? = nil) {
        print("addMessage called. selectedMessage: \(String(describing: selectedMessage))")
        let data = try? attributedText.data(
            from: NSRange(location: 0, length: attributedText.length),
            documentAttributes: [.documentType: NSAttributedString.DocumentType.rtfd])

        if let messageToUpdate = selectedMessage {
            messageToUpdate.attributedText = data
        } else {
            let newMessage = MessageEntity(context: context)
            newMessage.attributedText = data
            newMessage.date = Date()
            newMessage.liked = true
            print("newMessage: \(newMessage)")
        }
        CoreDataManager.shared.saveContext()
        // fetchMessages() は不要
    }
}
