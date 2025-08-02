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
    @StateObject var store = MessageStore()
    @State private var isSelecting = false

    var body: some View {
        NavigationView {
            VStack {
                NavigationLink("新規追加") {
                    DetailView(store: store)
                }
                DateGroupedTableView(messages: $store.messages, isSelecting: $isSelecting)
            }
            .navigationTitle("メッセージ一覧")
            .toolbar {
                if isSelecting {
                    ToolbarItemGroup(placement: .bottomBar) {
                        Button("Transfer") {
                            // Transfer処理
                        }
                        Button("Like") {
                            // Like処理
                        }
                        Button("Cancel") {
                            isSelecting = false
                            // キャンセル処理
                        }
                    }
                }
            }
        }
    }
}

struct DateGroupedTableView: UIViewControllerRepresentable {
    @Binding var messages: [MessageEntity]
    @Binding var isSelecting: Bool

    func makeCoordinator() -> Coordinator_DateGroupedTableView {
        Coordinator_DateGroupedTableView(self)  // 親のインスタンスを渡す
    }

    func makeUIViewController(context: Context) -> DateGroupedTableViewController {
        let vc = DateGroupedTableViewController()
        vc.messages = messages
        vc.isSelectingBinding = context.coordinator.isSelecting  // Binding<Bool>
        vc.coordinator = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: DateGroupedTableViewController, context: Context) {
        uiViewController.messages = messages
        uiViewController.groupMessagesByDate()
        uiViewController.tableView.reloadData()
    }

    class Coordinator_DateGroupedTableView {
        var isSelecting: Binding<Bool>

        init(_ parent: DateGroupedTableView) {
            self.isSelecting = parent.$isSelecting  // ここがポイント
        }
    }
}


class DateGroupedTableViewController: UITableViewController {
    var messages: [MessageEntity] = []
    var groupedMessages: [(date: Date, messages: [MessageEntity])] = []
    var selectedMessages: [MessageEntity] = []

    var coordinator: DateGroupedTableView.Coordinator?
    var isSelectingBinding: Binding<Bool>? // 追加

    var isSelecting: Bool {
        get { isSelectingBinding?.wrappedValue ?? false }
        set {
            isSelectingBinding?.wrappedValue = newValue
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
        tableView.register(CustomCell.self, forCellReuseIdentifier: "CustomCell")
        tableView.allowsMultipleSelection = true  // ← ここ
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "選択",
                                                            style: .plain,
                                                            target: self,
                                                            action: #selector(toggleSelectionMode))
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        tableView.addGestureRecognizer(longPressRecognizer)
        navigationController?.isToolbarHidden = true
        
    }
    
    @objc func transferTapped() {
        print("Transfer tapped")
    }

    @objc func likeTapped() {
        guard !selectedMessages.isEmpty else { return }

        let context = CoreDataManager.shared.context
        let undoManager = context.undoManager ?? UndoManager()
        context.undoManager = undoManager

        for message in selectedMessages {
            undoManager.registerUndo(withTarget: message) { targetMessage in
                targetMessage.liked.toggle()
                CoreDataManager.shared.saveContext()
            }
            message.liked.toggle()
        }

        CoreDataManager.shared.saveContext()
        showToast(message: "Liked 状態を変更しました")
    }

    @objc func cancelTapped() {
        isSelecting = false
        selectedMessages.removeAll()
        tableView.reloadData()
    }
    
    @objc func undoTapped() {
        CoreDataManager.shared.context.undoManager?.undo()
        CoreDataManager.shared.saveContext()
    }

    @objc func redoTapped() {
        CoreDataManager.shared.context.undoManager?.redo()
        CoreDataManager.shared.saveContext()
    }

    
    func updateToolbar() {
            if isSelecting {
                let transfer = UIBarButtonItem(title: "Transfer", style: .plain, target: self, action: #selector(transferTapped))
                let like = UIBarButtonItem(title: "Like", style: .plain, target: self, action: #selector(likeTapped))
                let cancel = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelTapped))
                let flexible = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
                
                setToolbarItems([transfer, flexible, like, flexible, cancel], animated: true)
                navigationController?.setToolbarHidden(false, animated: true)
            } else {
                navigationController?.setToolbarHidden(true, animated: true)
            }
        }
    
    @objc func toggleSelectionMode() {
        isSelecting.toggle()
        tableView.allowsMultipleSelection = isSelecting
        navigationItem.rightBarButtonItem?.title = isSelecting ? "完了" : "選択"
        if !isSelecting {
            selectedMessages.removeAll()
            for indexPath in tableView.indexPathsForSelectedRows ?? [] {
                tableView.deselectRow(at: indexPath, animated: true)
            }
        }
    }
    
    @objc func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        guard gestureRecognizer.state == .began else { return }

        let point = gestureRecognizer.location(in: tableView)
        if let indexPath = tableView.indexPathForRow(at: point) {
            if !isSelecting {
                // 選択モードに入る
                isSelecting = true
                tableView.allowsMultipleSelection = true
                navigationItem.rightBarButtonItem?.title = "完了"
            }

            // 該当セルを選択状態にする
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
            let message = groupedMessages[indexPath.section].messages[indexPath.row]
            selectedMessages.append(message)
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let message = groupedMessages[indexPath.section].messages[indexPath.row]

        if isSelecting {
            selectedMessages.append(message)
        } else {
            // SwiftUIのDetailViewをUIHostingControllerでラップして表示
            let detailView = DetailView(store: MessageStore(message: message)) // 例：messageを渡す
            let hostingController = UIHostingController(rootView: detailView)
            navigationController?.pushViewController(hostingController, animated: true)
        }
    }

    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        guard isSelecting else { return }
        let message = groupedMessages[indexPath.section].messages[indexPath.row]
        selectedMessages.removeAll { $0.id == message.id }
    }


    /*@objc func toggleSelectionMode() {
        isSelecting.toggle()
        tableView.allowsMultipleSelection = isSelecting
        tableView.reloadData() // 見た目も切り替える場合
    }*/
    
    /*#@objc func transferSelectedMessages() {
        guard !selectedMessages.isEmpty else { return }

        // 例: どこかのフォルダに移動するなど
        for message in selectedMessages {
            message.folder = "新しいフォルダ名"
        }

        selectedMessages.removeAll()
        tableView.reloadData()
    }*/
    
    


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = groupedMessages[indexPath.section].messages[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "CustomCell", for: indexPath) as! CustomCell
        cell.titleLabel.text = message.text
        cell.subtitleLabel.text = "詳細テキストなど必要に応じて" // ここは適宜変更
        cell.iconView.image = UIImage(systemName: "message") // アイコンもお好みで
        return cell
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
    
    
}

//


class CustomCell: UITableViewCell {
    let titleLabel = UILabel()
    let subtitleLabel = UILabel()
    let iconView = UIImageView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        // アイコン
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.contentMode = .scaleAspectFit
        iconView.layer.cornerRadius = 20
        iconView.clipsToBounds = true
        contentView.addSubview(iconView)

        // タイトルラベル
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        contentView.addSubview(titleLabel)

        // サブタイトルラベル
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        subtitleLabel.textColor = .gray
        subtitleLabel.numberOfLines = 0
        contentView.addSubview(subtitleLabel)

        // Auto Layout
        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            iconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 40),
            iconView.heightAnchor.constraint(equalToConstant: 40),

            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            subtitleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }
    
    // CustomCell.swift などで
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        contentView.backgroundColor = selected ? UIColor.systemBlue.withAlphaComponent(0.2) : .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
