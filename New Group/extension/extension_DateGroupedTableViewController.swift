//
//  extension_DateGroupedTableViewController.swift
//  DateSections_UITableView3
//
//  Created by Yuki Sasaki on 2025/08/03.
//

import SwiftUI

// MARK: - Selection Mode

extension DateGroupedTableViewController {
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
        guard let indexPath = tableView.indexPathForRow(at: point) else { return }

        if !isSelecting {
            isSelecting = true
            // 選択モード入りと allowsMultipleSelection の切り替えを
            // メインスレッドの次のループに遅らせる
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.tableView.allowsMultipleSelection = true
                self.navigationItem.rightBarButtonItem?.title = "完了"

                // 遅延して選択処理
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
}


// MARK: - Actions

extension DateGroupedTableViewController {
    @objc func addButtonTapped() {
        let detailVC = DetailViewController()
        detailVC.store = MessageStore()
        navigationController?.pushViewController(detailVC, animated: true)
    }
    
    @objc func transferTapped() {
        // Transfer ロジックここに
        print("Transfer tapped")
    }

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
        isSelecting = false
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

}


// MARK: - UITableView Delegate

extension DateGroupedTableViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let message = groupedMessages[indexPath.section].messages[indexPath.row]

        if isSelecting {
            selectedMessages.append(message)
        } else {
            let vc = DetailViewController()
            vc.message = message  // ← ここで渡す
            vc.store = store // 必要ならここで渡す
            navigationController?.pushViewController(vc, animated: true)
        }
    }


    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        guard isSelecting else { return }
        let message = groupedMessages[indexPath.section].messages[indexPath.row]
        selectedMessages.removeAll { $0.id == message.id }
    }
}

// MARK: - UITableView DataSource

extension DateGroupedTableViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        groupedMessages.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        groupedMessages[section].messages.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = groupedMessages[indexPath.section].messages[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "CustomCell", for: indexPath) as! CustomCell

        cell.titleLabel.text = message.text
        cell.subtitleLabel.text = "詳細テキストなど"
        cell.iconView.image = UIImage(systemName: "message")
        cell.updateLikeButton(isLiked: message.liked)

        return cell
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        dateFormatter.string(from: groupedMessages[section].date)
    }
}
