//
//  extension_DateGroupedTableViewController.swift
//  DateSections_UITableView3
//
//  Created by Yuki Sasaki on 2025/08/03.
//

import SwiftUI

// MARK: - Setup

extension DateGroupedTableViewController {
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
    
    func setupTableView() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        tableView.register(CustomCell.self, forCellReuseIdentifier: "CustomCell")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.allowsMultipleSelection = false
    }
    func setupNavigation() {
        navigationController?.navigationBar.prefersLargeTitles = true
        title = "メッセージ一覧"

        // 左側（リーディング）にメニューボタンを追加
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "line.horizontal.3"),
            style: .plain,
            target: self,
            action: #selector(addSlideMenu) // ここでスライドメニューを開く
        )

        // 右側（トレーリング）に既存のボタンを設定
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(image: UIImage(systemName: "folder"), style: .plain, target: self, action: #selector(addFolderTapped)),
            UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addButtonTapped)),
            UIBarButtonItem(title: "選択", style: .plain, target: self, action: #selector(toggleSelectionMode))
        ]
    }


    func setupToolbar() {
        navigationController?.setToolbarHidden(true, animated: false)
    }

    func setupGesture() {
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        tableView.addGestureRecognizer(longPressRecognizer)
    }
}

// MARK: - UITableViewDataSource

extension DateGroupedTableViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        groupedMessages.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        groupedMessages[section].messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let message = groupedMessages[indexPath.section].messages[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "CustomCell", for: indexPath) as! CustomCell

        // Data → NSAttributedString → string
        if let data = message.attributedText,
           let attrText = try? NSAttributedString(
               data: data,
               options: [.documentType: NSAttributedString.DocumentType.rtfd],
               documentAttributes: nil) {
            cell.titleLabel.text = attrText.string
        } else {
            cell.titleLabel.text = ""
        }

        cell.subtitleLabel.text = "詳細テキストなど"
        cell.iconView.image = UIImage(systemName: "message")
        cell.updateLikeButton(isLiked: message.liked)
        return cell
    }
    

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        dateFormatter.string(from: groupedMessages[section].date)
    }
}

// MARK: - UITableViewDelegate

extension DateGroupedTableViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let message = groupedMessages[indexPath.section].messages[indexPath.row]

        if isSelecting {
            selectedMessages.append(message)
        } else {
            let vc = DetailViewController()
            vc.message = message
            vc.store = store
            vc.messageDate = message.date
            
            if let data = message.attributedText,
               let attrString = try? NSAttributedString(
                   data: data,
                   options: [.documentType: NSAttributedString.DocumentType.rtfd],
                   documentAttributes: nil) {
                vc.messageText = NSMutableAttributedString(attributedString: attrString)
            } else {
                vc.messageText = NSMutableAttributedString(string: "")
            }
            
            print("DetailViewController に message.text を渡します: \(vc.messageText.string)")
            navigationController?.pushViewController(vc, animated: true)
        }
    }


    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        guard isSelecting else { return }
        let message = groupedMessages[indexPath.section].messages[indexPath.row]
        selectedMessages.removeAll { $0.id == message.id }
    }
}

// MARK: - Actions

extension DateGroupedTableViewController {
    
    // MARK: - SlideMenu 表示
        
        @objc func hideSlideMenu() {
            guard let menuVC = slideMenuVC else { return }

            UIView.animate(withDuration: 0.3, animations: {
                menuVC.view.frame.origin.x = -menuVC.view.frame.width
                self.dimmingView?.alpha = 0
            }) { _ in
                menuVC.willMove(toParent: nil)
                menuVC.view.removeFromSuperview()
                menuVC.removeFromParent()
                self.dimmingView?.removeFromSuperview()

                self.slideMenuVC = nil
                self.dimmingView = nil
                self.isSlideMenuVisible = false
            }
        }

    func showSlideMenu() {
        guard slideMenuVC == nil else { return }

        let menuVC = SlideMenuViewController()
        menuVC.context = CoreDataManager.shared.context // ← Core Data の context を渡す
        menuVC.didSelectFolder = { [weak self] folder in
            print("Selected folder: \(folder.folderName ?? "")")
            self?.hideSlideMenu()
        }

        addChild(menuVC)
        view.addSubview(menuVC.view)
        menuVC.didMove(toParent: self)

        let width: CGFloat = 250
        menuVC.view.frame = CGRect(x: -width, y: 0, width: width, height: view.frame.height)

        // Dimming view
        let dimming = UIView(frame: view.bounds)
        dimming.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        dimming.alpha = 0
        dimming.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(hideSlideMenu)))
        view.insertSubview(dimming, belowSubview: menuVC.view)

        slideMenuVC = menuVC
        dimmingView = dimming
        isSlideMenuVisible = true

        UIView.animate(withDuration: 0.3) {
            menuVC.view.frame.origin.x = 0
            dimming.alpha = 1
        }
    }
    
    // MARK: - Actions Folder
    
    private func createFolder(named name: String) {
        let context = CoreDataManager.shared.context

        let folder = Folder(context: context)
        folder.folderName = name

        CoreDataManager.shared.saveContext()

        print("フォルダ作成: \(name)")

        // 必要ならフォルダリストを更新
        // self.fetchFolders()
    }
    
    @objc private func addFolderTapped() {
        let alert = UIAlertController(title: "新しいフォルダ", message: "フォルダ名を入力してください", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "フォルダ名"
        }
        
        let createAction = UIAlertAction(title: "作成", style: .default) { [weak self] _ in
            guard let self = self else { return }
            guard let folderName = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !folderName.isEmpty else { return }
            
            self.createFolder(named: folderName)
        }
        
        alert.addAction(createAction)
        alert.addAction(UIAlertAction(title: "キャンセル", style: .cancel))
        
        present(alert, animated: true)
    }
    
}

// MARK: - Actions

extension DateGroupedTableViewController {
    
    @objc func addSlideMenu() {
        if isSlideMenuVisible {
            hideSlideMenu()
        } else {
            showSlideMenu()
        }
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

        showToast(
            message: "Liked 状態を変更しました",
            undoAction: { [weak self] in
                self?.undoTapped()
            },
            redoAction: { [weak self] in
                self?.redoTapped()
            }
        )

        selectedMessages.removeAll()
        isSelecting = false
    }
    
    @objc func cancelTapped() {
        isSelecting = false
        selectedMessages.removeAll()
        tableView.reloadData()
    }

    @objc func addButtonTapped() {
        let detailVC = DetailViewController()
        detailVC.store = MessageStore()
        navigationController?.pushViewController(detailVC, animated: true)
    }

    @objc func toggleSelectionMode() {
        isSelecting.toggle()
        tableView.allowsMultipleSelection = isSelecting
        navigationItem.rightBarButtonItems?.last?.title = isSelecting ? "完了" : "選択"

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
    

    @objc func undoTapped() {
        if let undoManager = CoreDataManager.shared.context.undoManager, undoManager.canUndo {
            undoManager.undo()
            CoreDataManager.shared.saveContext()
            tableView.reloadData()
            showToast(
                message: "Undoを実行しました",
                undoAction: { [weak self] in self?.undoTapped() },
                redoAction: { [weak self] in self?.redoTapped() }
            )
        } else {
            print("Undoできる操作がありません")
        }
    }

    @objc func redoTapped() {
        if let undoManager = CoreDataManager.shared.context.undoManager, undoManager.canRedo {
            undoManager.redo()
            CoreDataManager.shared.saveContext()
            tableView.reloadData()
            showToast(
                message: "Redoを実行しました",
                undoAction: { [weak self] in self?.undoTapped() },
                redoAction: { [weak self] in self?.redoTapped() }
            )
        } else {
            print("Redoできる操作がありません")
        }
    }
}

// MARK: - undo redo

extension DateGroupedTableViewController {
    
    func showToast(message: String, undoAction: @escaping () -> Void, redoAction: @escaping () -> Void) {
        let toastView = UIView()
        toastView.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        toastView.layer.cornerRadius = 10
        toastView.clipsToBounds = true
        toastView.translatesAutoresizingMaskIntoConstraints = false
        
        let label = UILabel()
        label.text = message
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 14)
        
        let undoButton = UIButton(type: .system)
        undoButton.setTitle("Undo", for: .normal)
        undoButton.setTitleColor(.white, for: .normal)
        undoButton.addAction(UIAction { _ in undoAction() }, for: .touchUpInside)
        
        let redoButton = UIButton(type: .system)
        redoButton.setTitle("Redo", for: .normal)
        redoButton.setTitleColor(.white, for: .normal)
        redoButton.addAction(UIAction { _ in redoAction() }, for: .touchUpInside)
        
        let stack = UIStackView(arrangedSubviews: [label, undoButton, redoButton])
        stack.axis = .horizontal
        stack.spacing = 12
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        toastView.addSubview(stack)
        
        view.addSubview(toastView)
        
        NSLayoutConstraint.activate([
            toastView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            toastView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            toastView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -32),
            
            stack.topAnchor.constraint(equalTo: toastView.topAnchor, constant: 12),
            stack.bottomAnchor.constraint(equalTo: toastView.bottomAnchor, constant: -12),
            stack.leadingAnchor.constraint(equalTo: toastView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: toastView.trailingAnchor, constant: -16)
        ])
        
        toastView.alpha = 0
        UIView.animate(withDuration: 0.3) {
            toastView.alpha = 1
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            UIView.animate(withDuration: 0.3, animations: {
                toastView.alpha = 0
            }, completion: { _ in
                toastView.removeFromSuperview()
            })
        }
        
        //
        
        undoButton.addAction(UIAction { _ in
            print("Undoボタンが押されました")
            undoAction()
        }, for: .touchUpInside)
        
        redoButton.addAction(UIAction { _ in
            print("Redoボタンが押されました")
            redoAction()
        }, for: .touchUpInside)
        
    }
    
    @objc func transferTapped() {
        // Transfer ロジックここに
        print("Transfer tapped")
    }
}

/*

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

        showToast(
            message: "Liked 状態を変更しました",
            undoAction: { [weak self] in
                self?.undoTapped()
            },
            redoAction: { [weak self] in
                self?.redoTapped()
            }
        )

        selectedMessages.removeAll()
        isSelecting = false
    }
    
    @objc func cancelTapped() {
        isSelecting = false
        selectedMessages.removeAll()
        tableView.reloadData()
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
        
        //print("タップされたmessage.text: \(message.text ?? "nil")")
        
        if (message.text ?? "").isEmpty {
            //print("⚠️ テキストが空のメッセージです")
        }
        
        if isSelecting {
            selectedMessages.append(message)
        } else {
            let vc = DetailViewController()
            vc.message = message  // ここで渡す
            vc.store = store
            vc.messageDate = message.date
            print("DetailViewController に message.text を渡します: \(vc.message?.text ?? "nil")")
            navigationController?.pushViewController(vc, animated: true)
        }
        
        /*for group in groupedMessages {
            for msg in group.messages {
                print("grouped message.text: \(msg.text ?? "nil")")
            }
        }*/

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

// MARK: - undo redo

extension UIViewController {
    func showToast(message: String, undoAction: @escaping () -> Void, redoAction: @escaping () -> Void) {
        let toastView = UIView()
        toastView.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        toastView.layer.cornerRadius = 10
        toastView.clipsToBounds = true
        toastView.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = message
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 14)
        
        let undoButton = UIButton(type: .system)
        undoButton.setTitle("Undo", for: .normal)
        undoButton.setTitleColor(.white, for: .normal)
        undoButton.addAction(UIAction { _ in undoAction() }, for: .touchUpInside)

        let redoButton = UIButton(type: .system)
        redoButton.setTitle("Redo", for: .normal)
        redoButton.setTitleColor(.white, for: .normal)
        redoButton.addAction(UIAction { _ in redoAction() }, for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [label, undoButton, redoButton])
        stack.axis = .horizontal
        stack.spacing = 12
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        toastView.addSubview(stack)

        view.addSubview(toastView)

        NSLayoutConstraint.activate([
            toastView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            toastView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            toastView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -32),

            stack.topAnchor.constraint(equalTo: toastView.topAnchor, constant: 12),
            stack.bottomAnchor.constraint(equalTo: toastView.bottomAnchor, constant: -12),
            stack.leadingAnchor.constraint(equalTo: toastView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: toastView.trailingAnchor, constant: -16)
        ])

        toastView.alpha = 0
        UIView.animate(withDuration: 0.3) {
            toastView.alpha = 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            UIView.animate(withDuration: 0.3, animations: {
                toastView.alpha = 0
            }, completion: { _ in
                toastView.removeFromSuperview()
            })
        }
        
        //
        
        undoButton.addAction(UIAction { _ in
            print("Undoボタンが押されました")
            undoAction()
        }, for: .touchUpInside)

        redoButton.addAction(UIAction { _ in
            print("Redoボタンが押されました")
            redoAction()
        }, for: .touchUpInside)

    }
    
    @objc func undoTapped() {
        if let undoManager = CoreDataManager.shared.context.undoManager, undoManager.canUndo {
            undoManager.undo()
            CoreDataManager.shared.saveContext()
            tableView.reloadData()

            showToast(
                message: "Undoを実行しました",
                undoAction: { [weak self] in self?.undoTapped() },
                redoAction: { [weak self] in self?.redoTapped() }
            )
        } else {
            print("Undoできる操作がありません")
        }
    }


    @objc func redoTapped() {
        if let undoManager = CoreDataManager.shared.context.undoManager, undoManager.canRedo {
            undoManager.redo()
            CoreDataManager.shared.saveContext()
            tableView.reloadData()

            showToast(
                message: "Redoを実行しました",
                undoAction: { [weak self] in self?.undoTapped() },
                redoAction: { [weak self] in self?.redoTapped() }
            )
        } else {
            print("Redoできる操作がありません")
        }
    }

}
*/
