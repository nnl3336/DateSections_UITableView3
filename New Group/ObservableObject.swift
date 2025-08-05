//
//  ObservableObject.swift
//  DateSections_UITableView3
//
//  Created by Yuki Sasaki on 2025/08/02.
//

import SwiftUI
import CoreData

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

    func updateMessage(_ message: MessageEntity, withAttributedText attributedText: NSMutableAttributedString) {
        print("updateMessage called.")
        if let data = try? attributedText.data(
            from: NSRange(location: 0, length: attributedText.length),
            documentAttributes: [.documentType: NSAttributedString.DocumentType.rtfd]) {
            message.attributedText = data
        }
        message.date = Date()
        CoreDataManager.shared.saveContext()
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
