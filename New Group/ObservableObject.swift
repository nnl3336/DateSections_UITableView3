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

    init() {
        fetchMessages()
    }
    
    // 新たに追加：message を受け取るバージョン
    init(message: MessageEntity) {
        self.selectedMessage = message
        fetchMessages()
    }

    func fetchMessages() {
        let request = NSFetchRequest<MessageEntity>(entityName: "MessageEntity")
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        messages = (try? context.fetch(request)) ?? []
    }

    func addMessage(_ text: String) {
        let newMessage = MessageEntity(context: context)
        newMessage.text = text
        newMessage.date = Date()
        newMessage.liked = true  // ← ここで初期値をセット
        CoreDataManager.shared.saveContext()
        fetchMessages()
    }
}
