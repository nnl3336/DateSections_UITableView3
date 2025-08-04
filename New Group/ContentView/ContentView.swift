//
//  ContentView.swift
//  DateSections_UITableView3
//
//  Created by Yuki Sasaki on 2025/08/01.
//

import SwiftUI
import CoreData
import UIKit

struct ContentView: View {

    var body: some View {
        DateGroupedTableView(/*store: store,
                             messages: $store.messages,
                             isSelecting: $isSelecting,
                             selectedMessages: $store.selectedMessages*/)
    }
}

struct DateGroupedTableView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> DateGroupedTableViewController {
        return DateGroupedTableViewController()
    }
    func updateUIViewController(_ uiViewController: DateGroupedTableViewController, context: Context) {
        // 更新処理
    }
}

class DateGroupedTableViewController: UIViewController {

    let tableView = UITableView()
    var store: MessageStore!
    var messages: [MessageEntity] = []
    var groupedMessages: [(date: Date, messages: [MessageEntity])] = []

    var selectedMessages: [MessageEntity] = []

    var isSelecting: Bool = false {
        didSet {
            updateToolbar()
        }
    }

    let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        return df
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupNavigation()
        setupToolbar()
        setupGesture()
    }
}

//


