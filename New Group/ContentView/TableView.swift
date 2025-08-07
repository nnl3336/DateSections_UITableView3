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

//

struct DateGroupedTableView: UIViewControllerRepresentable {
    @StateObject var store = MessageStore()
    //@Binding var messages: [MessageEntity]
    @State private var isSelecting = false
    
    //@Binding var selectedMessages: [MessageEntity]  // ← 追加

    func makeCoordinator() -> Coordinator_DateGroupedTableView {
        Coordinator_DateGroupedTableView(self)  // 親のインスタンスを渡す
    }

    func makeUIViewController(context: Context) -> UINavigationController {
        let vc = DateGroupedTableViewController()
        vc.store = store  // ✅ ← ここで渡す
        vc.messages = store.messages
        vc.isSelectingBinding = $isSelecting
        vc.selectedMessages = store.selectedMessages
        let nav = UINavigationController(rootViewController: vc)
        nav.isToolbarHidden = true
        return nav
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
        if let vc = uiViewController.viewControllers.first as? DateGroupedTableViewController {
            vc.messages = store.messages
            vc.isSelectingBinding = $isSelecting
            vc.selectedMessages = store.selectedMessages
            vc.groupMessagesByDate()  // もしあるなら
            vc.tableView.reloadData()
        }
    }

    class Coordinator_DateGroupedTableView {
        var isSelecting: Binding<Bool>

        init(_ parent: DateGroupedTableView) {
            self.isSelecting = parent.$isSelecting  // ここがポイント
        }
    }
}

//

class DateGroupedTableViewController: UIViewController {

    var store: MessageStore!  // ← ここで定義しておく
    
    let tableView = UITableView()  // ← ここで宣言
    
    var messages: [MessageEntity] = []
    var groupedMessages: [(date: Date, messages: [MessageEntity])] = []
    
    var selectedMessages: [MessageEntity] = []
    
    var coordinator: DateGroupedTableView.Coordinator?
    var isSelectingBinding: Binding<Bool>? // 追加
    
    var isSelecting: Bool {
        get { isSelectingBinding?.wrappedValue ?? false }
        set {
            print("isSelecting will change to \(newValue)")
            isSelectingBinding?.wrappedValue = newValue
            updateToolbar()
            
            // 選択モードの切り替えに応じてtableViewの設定を変える
            tableView.allowsMultipleSelection = newValue
            
            if !newValue {
                // 選択解除を明示的に行う
                if let selectedIndexPaths = tableView.indexPathsForSelectedRows {
                    for indexPath in selectedIndexPaths {
                        tableView.deselectRow(at: indexPath, animated: true)
                    }
                }
                selectedMessages.removeAll()
                tableView.reloadData() // 状態が変わるなら再描画もあり
            }
        }
    }
    
    var slideMenuVC: SlideMenuViewController?
    var dimmingView: UIView?
    var isSlideMenuVisible = false
    
    /*
     var isSelecting: Bool {
         get { isSelectingBinding?.wrappedValue ?? false }
         set {
             print("isSelecting will change to \(newValue)")
             isSelectingBinding?.wrappedValue = newValue
             updateToolbar()
         }
     }
     */

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
        
        self.navigationItem.backButtonTitle = title

    }
}

//***
