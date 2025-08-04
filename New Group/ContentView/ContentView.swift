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

class DateGroupedTableViewController: UIViewController {

    var store: MessageStore!  // ← ここで定義しておく
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


//***

/*struct DateGroupedTableView: UIViewControllerRepresentable {
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

//***

class DateGroupedTableViewController: UITableViewController {
    var store: MessageStore!  // ← ここで定義しておく
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
        }
    }
    
    let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        return df
    }()
    
    //***
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // テーブルビュー初期設定
        tableView.register(CustomCell.self, forCellReuseIdentifier: "CustomCell")
        tableView.allowsMultipleSelection = false

        // ナビゲーションバーの設定
        navigationController?.navigationBar.prefersLargeTitles = true
        title = "メッセージ一覧"
        
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addButtonTapped)),
            UIBarButtonItem(title: "選択", style: .plain, target: self, action: #selector(toggleSelectionMode))
        ]


        // 最初はツールバーを非表示（isSelecting によって切り替え）
        navigationController?.setToolbarHidden(!isSelecting, animated: false)

        // 長押しジェスチャー追加
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        tableView.addGestureRecognizer(longPressRecognizer)
    }

}*/

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
