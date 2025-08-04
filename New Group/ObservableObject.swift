//
//  ObservableObject.swift
//  DateSections_UITableView3
//
//  Created by Yuki Sasaki on 2025/08/02.
//

import SwiftUI
import CoreData

class MessageStore: ObservableObject {
    @Published var messages: [MessageEntity] = []
    @Published var selectedMessage: MessageEntity?  // 追加しておくと便利
    @Published var selectedMessages: [MessageEntity] = []  // 追加！

    private let context = CoreDataManager.shared.context
    
    private var fetchedResultsController: NSFetchedResultsController<MessageEntity>!


    init() {
        fetchMessages()
    }
    
    // 新たに追加：message を受け取るバージョン
    init(message: MessageEntity) {
        self.selectedMessage = message
        fetchMessages()
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
        fetchMessages()
    }

    func setupFetchedResultsController() {
        let fetchRequest: NSFetchRequest<MessageEntity> = MessageEntity.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]

        fetchedResultsController = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: CoreDataManager.shared.context,
            sectionNameKeyPath: nil,
            cacheName: nil)

        fetchedResultsController.delegate = self

        do {
            try fetchedResultsController.performFetch()
        } catch {
            print("Failed to fetch: \(error)")
        }
    }
    

    func fetchMessages() {
        let request = NSFetchRequest<MessageEntity>(entityName: "MessageEntity")
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        let fetched = (try? context.fetch(request)) ?? []

        DispatchQueue.main.async {
            self.messages = fetched
            //self.tableView.reloadData()  // これで画面が更新される
        }
        print("fetchMessages!")
    }


    func addMessage(_ attributedText: NSMutableAttributedString, selectedMessage: MessageEntity? = nil) {
        print("addMessage called. selectedMessage: \(String(describing: selectedMessage))")
        
        // NSAttributedString → Data に変換
        let data = try? attributedText.data(
            from: NSRange(location: 0, length: attributedText.length),
            documentAttributes: [.documentType: NSAttributedString.DocumentType.rtfd])
        
        if let messageToUpdate = selectedMessage {
            messageToUpdate.attributedText = data  // Data? 型として代入
        } else {
            let newMessage = MessageEntity(context: context)
            newMessage.attributedText = data       // Data? 型として代入
            newMessage.date = Date()
            newMessage.liked = true
            print("newMessage: \(newMessage)")
        }
        
        CoreDataManager.shared.saveContext()
        fetchMessages()
    }




}
