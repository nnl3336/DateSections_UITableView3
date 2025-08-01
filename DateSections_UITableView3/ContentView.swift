//
//  ContentView.swift
//  DateSections_UITableView3
//
//  Created by Yuki Sasaki on 2025/08/01.
//

import SwiftUI
import CoreData

import UIKit

class CoreDataManager {
    static let shared = CoreDataManager()

    let container: NSPersistentContainer

    private init() {
        container = NSPersistentContainer(name: "MessageEntity") // ← .xcdatamodeld の名前
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


struct TextViewWrapper: UIViewRepresentable {
    @Binding var text: String

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.delegate = context.coordinator
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.text = text
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: TextViewWrapper

        init(_ parent: TextViewWrapper) {
            self.parent = parent
        }

        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
        }
    }
}


struct DetailView: View {
    @ObservedObject var store: MessageStore
    @Environment(\.dismiss) var dismiss
    @State private var messageText = ""

    var body: some View {
        VStack {
            TextViewWrapper(text: $messageText)
                .frame(height: 200)
                .padding()

            Button("追加") {
                store.addMessage(messageText)
                dismiss()
            }
        }
        .navigationTitle("新規メッセージ")
    }
}


class MessageStore: ObservableObject {
    @Published var messages: [MessageEntity] = []

    private let context = CoreDataManager.shared.context

    init() {
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
        CoreDataManager.shared.saveContext()
        fetchMessages()
    }
}




struct ContentView: View {
    @StateObject var store = MessageStore()

    var body: some View {
        NavigationView {
            VStack {
                NavigationLink("新規追加") {
                    DetailView(store: store)
                }

                DateGroupedTableView(messages: $store.messages)
            }
            .navigationTitle("メッセージ一覧")
        }
    }
}


struct DateGroupedTableView: UIViewControllerRepresentable {
    @Binding var messages: [MessageEntity]

    func makeUIViewController(context: Context) -> DateGroupedTableViewController {
        let vc = DateGroupedTableViewController()
        vc.messages = messages
        vc.groupMessagesByDate()
        return vc
    }

    func updateUIViewController(_ uiViewController: DateGroupedTableViewController, context: Context) {
        uiViewController.messages = messages
        uiViewController.groupMessagesByDate()
        uiViewController.tableView.reloadData()
    }
}



class DateGroupedTableViewController: UITableViewController {

    var messages: [MessageEntity] = []
    var groupedMessages: [(date: Date, messages: [MessageEntity])] = []

    let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        return df
    }()

    func groupMessagesByDate() {
        let groupedDict = Dictionary(grouping: messages) { message in
            Calendar.current.startOfDay(for: message.date ?? Date())
        }
        groupedMessages = groupedDict
            .map { ($0.key, $0.value) }
            .sorted { $0.0 > $1.0 }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return groupedMessages.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return groupedMessages[section].messages.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return dateFormatter.string(from: groupedMessages[section].date)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = groupedMessages[indexPath.section].messages[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = message.text
        return cell
    }
}


struct Message {
    let text: String
    let date: Date
}
