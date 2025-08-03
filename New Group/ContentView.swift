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
                DateGroupedTableView(messages: $store.messages, isSelecting: $isSelecting, selectedMessages: $store.selectedMessages)
            }
            .navigationTitle("メッセージ一覧")
            /*.toolbar {
                if isSelecting {
                    ToolbarItemGroup(placement: .bottomBar) {
                        Button("Transfer") {
                            // Transfer処理
                        }
                        Button("Like") {
                            let context = CoreDataManager.shared.context
                            for message in store.selectedMessages {
                                message.liked.toggle()
                            }
                            CoreDataManager.shared.saveContext()
                            store.fetchMessages()  // メッセージ一覧を最新化
                            
                            store.selectedMessages.removeAll()  // 選択解除
                            isSelecting = false                 // 選択モードオフ
                        }
                        Button("Cancel") {
                            isSelecting = false
                            // キャンセル処理
                        }
                    }
                }
            }*/
        }
    }
}

struct DateGroupedTableView: UIViewControllerRepresentable {
    @Binding var messages: [MessageEntity]
    @Binding var isSelecting: Bool
    @Binding var selectedMessages: [MessageEntity]  // ← 追加

    func makeCoordinator() -> Coordinator_DateGroupedTableView {
        Coordinator_DateGroupedTableView(self)  // 親のインスタンスを渡す
    }

    func makeUIViewController(context: Context) -> UINavigationController {
        let vc = DateGroupedTableViewController()
        vc.messages = messages
        vc.isSelectingBinding = $isSelecting
        vc.selectedMessages = selectedMessages
        let nav = UINavigationController(rootViewController: vc)
        nav.isToolbarHidden = true
        return nav
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
        if let vc = uiViewController.viewControllers.first as? DateGroupedTableViewController {
            vc.messages = messages
            vc.isSelectingBinding = $isSelecting
            vc.selectedMessages = selectedMessages
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


class DateGroupedTableViewController: UITableViewController {
    var messages: [MessageEntity] = []
    var groupedMessages: [(date: Date, messages: [MessageEntity])] = []
    var selectedMessages: [MessageEntity] = []

    var isSelectingBinding: Binding<Bool>? // SwiftUIの状態とバインド

    let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        return df
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(CustomCell.self, forCellReuseIdentifier: "CustomCell")
        tableView.allowsMultipleSelection = false  // 最初はオフ
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "選択",
                                                            style: .plain,
                                                            target: self,
                                                            action: #selector(toggleSelectionMode))
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        tableView.addGestureRecognizer(longPressRecognizer)

        navigationController?.isToolbarHidden = true // 最初は隠す
    }

    @objc func toggleSelectionMode() {
        guard let isSelectingBinding = isSelectingBinding else { return }
        let newValue = !isSelectingBinding.wrappedValue
        isSelectingBinding.wrappedValue = newValue
        updateToolbar()

        tableView.allowsMultipleSelection = newValue
        navigationItem.rightBarButtonItem?.title = newValue ? "完了" : "選択"

        if !newValue {
            selectedMessages.removeAll()
            for indexPath in tableView.indexPathsForSelectedRows ?? [] {
                tableView.deselectRow(at: indexPath, animated: true)
            }
        }
    }
    
    @objc func transferTapped() {
        // Transfer ロジックここに
        print("Transfer tapped")
    }

    func updateToolbar() {
        let isSelecting = isSelectingBinding?.wrappedValue ?? false
        print("updateToolbar called, isSelecting = \(isSelecting)")
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
    
    @objc func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        guard gestureRecognizer.state == .began else { return }

        let point = gestureRecognizer.location(in: tableView)
        guard let indexPath = tableView.indexPathForRow(at: point) else { return }

        if isSelectingBinding?.wrappedValue != true {
            isSelectingBinding?.wrappedValue = true
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.tableView.allowsMultipleSelection = true
                self.navigationItem.rightBarButtonItem?.title = "完了"

                self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
                let message = self.groupedMessages[indexPath.section].messages[indexPath.row]
                if !self.selectedMessages.contains(where: { $0.id == message.id }) {
                    self.selectedMessages.append(message)
                }
            }
        } else {
            // すでに選択モードなら即選択
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
            let message = groupedMessages[indexPath.section].messages[indexPath.row]
            if !selectedMessages.contains(where: { $0.id == message.id }) {
                selectedMessages.append(message)
            }
        }
    }


    // --- 他のメソッドは省略（likeTapped, cancelTappedなどは元のまま） ---

    @objc func likeTapped() {
        guard !selectedMessages.isEmpty else { return }

        let context = CoreDataManager.shared.context
        let undoManager = context.undoManager ?? UndoManager()
        context.undoManager = undoManager

        var indexPathsToReload: [IndexPath] = []

        for (sectionIndex, group) in groupedMessages.enumerated() {
            for (rowIndex, message) in group.messages.enumerated() {
                if selectedMessages.contains(where: { $0.id == message.id }) {
                    undoManager.registerUndo(withTarget: message) { target in
                        target.liked.toggle()
                        CoreDataManager.shared.saveContext()
                    }
                    message.liked.toggle()
                    indexPathsToReload.append(IndexPath(row: rowIndex, section: sectionIndex))
                }
            }
        }

        CoreDataManager.shared.saveContext()
        tableView.reloadRows(at: indexPathsToReload, with: .none)

        showToast(message: "Liked 状態を変更しました")

        selectedMessages.removeAll()

        // 選択モードオフ＆ツールバー非表示
        if let isSelectingBinding = isSelectingBinding {
            isSelectingBinding.wrappedValue = false
        }
        updateToolbar()
    }

    @objc func cancelTapped() {
        selectedMessages.removeAll()
        if let isSelectingBinding = isSelectingBinding {
            isSelectingBinding.wrappedValue = false
        }
        updateToolbar()
        tableView.reloadData()
    }

    // ... handleLongPressやtableViewのdelegateメソッドも同様に変更不要 ...

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = groupedMessages[indexPath.section].messages[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "CustomCell", for: indexPath) as! CustomCell

        cell.titleLabel.text = message.text
        cell.subtitleLabel.text = "詳細テキストなど"
        cell.iconView.image = UIImage(systemName: "message")

        cell.updateLikeButton(isLiked: message.liked)

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
    let likeButton = UIButton(type: .system)  // 追加

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

        // like ボタンの設定
        likeButton.translatesAutoresizingMaskIntoConstraints = false
        likeButton.tintColor = .gray
        contentView.addSubview(likeButton)

        // Auto Layout
        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            iconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 40),
            iconView.heightAnchor.constraint(equalToConstant: 40),

            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: likeButton.leadingAnchor, constant: -8),

            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            subtitleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),

            likeButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            likeButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            likeButton.widthAnchor.constraint(equalToConstant: 24),
            likeButton.heightAnchor.constraint(equalToConstant: 24)
        ])
    }

    func updateLikeButton(isLiked: Bool) {
        let imageName = isLiked ? "heart.fill" : "heart"
        likeButton.setImage(UIImage(systemName: imageName), for: .normal)
        likeButton.tintColor = isLiked ? .systemRed : .gray
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        contentView.backgroundColor = selected ? UIColor.systemBlue.withAlphaComponent(0.2) : .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
