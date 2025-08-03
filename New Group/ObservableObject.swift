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
    
    func updateMessage(_ message: MessageEntity, withText text: String) {
        message.text = text
        message.date = Date()  // もし日時も更新するなら
        CoreDataManager.shared.saveContext()
        fetchMessages()
    }

    func fetchMessages() {
        let request = NSFetchRequest<MessageEntity>(entityName: "MessageEntity")
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        let fetched = (try? context.fetch(request)) ?? []

        DispatchQueue.main.async {
            self.messages = fetched
        }
        print("fetchMessages!")
    }

    func addMessage(_ text: String, selectedMessage: MessageEntity? = nil) {
        if let messageToUpdate = selectedMessage {
            // 既存のメッセージを上書き
            messageToUpdate.text = text
            messageToUpdate.date = Date()
            // liked は変更しないか必要ならここで設定
        } else {
            // 新規作成
            let newMessage = MessageEntity(context: context)
            newMessage.text = text
            newMessage.date = Date()
            newMessage.liked = true  // 初期値セット
        }
        CoreDataManager.shared.saveContext()
        fetchMessages()
    }

}
