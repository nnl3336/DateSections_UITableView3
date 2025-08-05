//
//  extension_TextView.swift
//  DateSections_UITableView3
//
//  Created by Yuki Sasaki on 2025/08/03.
//

import SwiftUI

// MARK: - KeyboardBar

extension DetailViewController {
    
    func makeKeyboardToolbar1() -> UIToolbar {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        
        let acColor = AccentColorManager.shared.currentColor.uiColor
        
        backButton = UIBarButtonItem(
            image: UIImage(systemName: "arrow.uturn.backward"),
            style: .plain,
            target: self,
            action: #selector(self.performUndo)
        )
        backButton.tintColor = acColor
        
        redoButton = UIBarButtonItem(
            image: UIImage(systemName: "arrow.uturn.forward"),
            style: .plain,
            target: self,
            action: #selector(self.performRedo)
        )
        redoButton.tintColor = acColor
        
        //
        
        saveButton = UIBarButtonItem(
            image: UIImage(systemName: "tray.and.arrow.down"),
            style: .plain,
            target: self,
            action: #selector(self.saveText)
        )
        saveButton.tintColor = acColor
        
        //
        
        photoButton = UIBarButtonItem(
            image: UIImage(systemName: "photo"),
            style: .plain,
            target: coordinator,
            action: #selector(coordinator.showImagePicker)
        )
        photoButton.tintColor = acColor
        
        //
        
        buttonLike = UIBarButtonItem(
            image: UIImage(systemName: ep_textView.selectLiked ? "heart.fill" : "heart"),
            style: .plain,
            target: self,
            action: #selector(self.toggleLike)
        )
        buttonLike.tintColor = acColor
        
        buttonCheck = UIBarButtonItem(
            image: UIImage(systemName: ep_textView.selectCheck ? "checkmark.circle.fill" : "checkmark.circle"),
            style: .plain,
            target: self,
            action: #selector(self.toggleCheck)
        )
        buttonCheck.tintColor = acColor
        
        //
        
        buttonCopy = UIBarButtonItem(
            image: UIImage(systemName: "doc.on.doc"),
            style: .plain,
            target: self,
            action: #selector(self.copyText)
        )
        buttonCopy.tintColor = acColor
        
        newPostButton = UIBarButtonItem(
            image: UIImage(systemName: "square.and.pencil"),
            style: .plain,
            target: coordinator,
            action: #selector(self.newPost)
        )
        newPostButton.tintColor = acColor
        //newPostButton.isEnabled = ep_item.item != nil
        
        //coordinator.newPostButton = newPostButton
        
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let flexibleSpace2 = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        flexibleSpace2.width = 3
        
        toolbar.items = [
            backButton,
            redoButton,
            flexibleSpace2,
            saveButton,
            flexibleSpace2,
            buttonCheck,
            buttonLike,
            buttonCopy,
            photoButton,
            flexibleSpace2,
            newPostButton
        ]
        
        return toolbar
    }
}

// MARK: - Support

extension DetailViewController {
    func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter.string(from: Date())
    }

    func formattedDate2() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: Date())
    }

    @objc func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc func newButtonTapped() {
        print("📝 新規作成タップ")
    }
}

// MARK: - NavigationBar

extension DetailViewController {
    
    func setupNavigationBar() {
        // 左の戻るボタン（custom）
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backButtonTapped)
        )

        // 右のメニューと pencil ボタン
        let menu = UIMenu(title: "", children: [
            UIAction(title: "History", image: UIImage(systemName: "clock")) { _ in
                print("History tapped")
            },
            UIAction(title: "Search Text", image: UIImage(systemName: "magnifyingglass")) { _ in
                print("Search tapped")
            },
            UIAction(title: "Trash", image: UIImage(systemName: "trash"), attributes: .destructive) { _ in
                print("Trash tapped")
            }
        ])

        let menuButton = UIBarButtonItem(image: UIImage(systemName: "ellipsis"), menu: menu)

        let newButton = UIBarButtonItem(
            image: UIImage(systemName: "square.and.pencil"),
            style: .plain,
            target: self,
            action: #selector(newButtonTapped)
        )

        navigationItem.rightBarButtonItems = [newButton, menuButton]
    }

}

// MARK: - Toolbar

extension DetailViewController {
    
    func setupToolbar() {
        let toolbar = UIToolbar()
        toolbar.translatesAutoresizingMaskIntoConstraints = false

        let dateLabel = UILabel()
        dateLabel.numberOfLines = 2
        dateLabel.textAlignment = .center
        dateLabel.text = "Date: \(formattedDate())\n\(formattedDate2())"

        let labelItem = UIBarButtonItem(customView: dateLabel)
        let flexible = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)

        let pencilItem = UIBarButtonItem(
            image: UIImage(systemName: "square.and.pencil"),
            style: .plain,
            target: self,
            action: #selector(newButtonTapped)
        )

        toolbar.setItems([flexible, labelItem, flexible, pencilItem], animated: false)

        view.addSubview(toolbar)

        NSLayoutConstraint.activate([
            toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

}

///

// MARK: - Setup UI

extension DetailViewController {
    func setupTextView() {
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.delegate = self
        textView.attributedText = messageText
        textView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(textView)
    }

    func setupButton() {
        addButton.setTitle("追加", for: .normal)
        addButton.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
        addButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(addButton)
    }

    func setupLayout() {
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            textView.heightAnchor.constraint(equalToConstant: 200),

            addButton.topAnchor.constraint(equalTo: textView.bottomAnchor, constant: 20),
            addButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
}

// MARK: - Actions

extension DetailViewController {
    
    // MARK: - 
    
    func handleSelectedImages(_ images: [UIImage]) {
        print("画像が選択されました: \(images.count) 枚")
        for image in images {
            addImageToTextView(image)
        }
    }

    private func addImageToTextView(_ image: UIImage) {
        let attachment = NSTextAttachment()
        attachment.image = image

        // オプション：サイズ調整（例：幅をtextViewの幅に合わせる）
        let maxWidth = textView.frame.width - 20
        if let img = attachment.image, img.size.width > 0 {
            let scale = maxWidth / img.size.width
            attachment.bounds = CGRect(x: 0, y: 0, width: img.size.width * scale, height: img.size.height * scale)
        }

        let attributedImage = NSAttributedString(attachment: attachment)

        // 現在のカーソル位置に挿入
        if let selectedRange = textView.selectedTextRange {
            let cursorPosition = textView.offset(from: textView.beginningOfDocument, to: selectedRange.start)
            let mutableAttrText = NSMutableAttributedString(attributedString: textView.attributedText)
            mutableAttrText.insert(attributedImage, at: cursorPosition)
            textView.attributedText = mutableAttrText

            // カーソル位置を画像の後ろに移動
            if let newPosition = textView.position(from: selectedRange.start, offset: 1) {
                textView.selectedTextRange = textView.textRange(from: newPosition, to: newPosition)
            }
        } else {
            // 範囲がない場合、末尾に追加
            textView.textStorage.append(attributedImage)
        }
    }

    // MARK: - 
    
    @objc func newPost() {
        print("newPost")
    }
    
    @objc func saveText() {
        print("Save text action")
    }

    @objc func showImagePicker() {
        print("Show image picker")
    }

    @objc func toggleLike() {
        print("Toggle like ViewController")
        ep_textView.selectLiked.toggle()
        buttonLike.image = UIImage(
            systemName: ep_textView.selectLiked ? "heart.fill" : "heart"
        )
    }

    @objc func toggleCheck() {
        print("Toggle check ViewController")
        ep_textView.selectCheck.toggle()
        buttonCheck.image = UIImage(
            systemName: ep_textView.selectCheck ? "checkmark.circle.fill" : "checkmark.circle"
        )
    }

    @objc func copyText() {
        print("Copy text")
    }

    @objc func createNewPost() {
        print("Create new post")
    }
    
    //undo
    
    @objc func updateUndoRedoButtons() {
        backButton.isEnabled = textView.undoManager?.canUndo ?? false
        redoButton.isEnabled = textView.undoManager?.canRedo ?? false
    }
    
    @objc func performUndo() {
        print("Undo performed")
        
        if let undoManager = textView.undoManager, undoManager.canUndo {
            undoManager.undo()
        }
    }

    @objc func performRedo() {
        print("Redo performed")

        if let undoManager = textView.undoManager, undoManager.canRedo {
            undoManager.redo()
        }
    }
    
    //add

    @objc private func addButtonTapped() {
        if let message = message {
            print("Updating existing message: \(message)")
            store.updateMessage(message, withAttributedText: messageText)
        } else {
            print("Adding new message")
            store.addMessage(messageText)
        }
        dismiss(animated: true)
    }
    
    // String
    /*@objc private func addButtonTapped() {
        //print("addButtonTapped: message.text = \(message?.text ?? "nil")")
        if let message = message {
            print("Updating existing message: \(message)")
            store.updateMessage(message, withText: textView.text)
        } else {
            print("Adding new message")
            store.addMessage(textView.text)
        }
        //store.fetchMessages()  // 最新データを取得し @Published messages を更新

        dismiss(animated: true)
    }*/

}

// MARK: - Undo

/*extension DetailViewController {
}*/

// MARK: - UITextViewDelegate

extension DetailViewController: UITextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
        messageText = NSMutableAttributedString(attributedString: textView.attributedText)
    }

    /*func textViewDidBeginEditing(_ textView: UITextView) {
        undoManager?.beginUndoGrouping()
    }

    func textViewDidChange(_ textView: UITextView) {
        if !isUndoGrouping {
            textView.undoManager?.beginUndoGrouping()
            isUndoGrouping = true
        }

        undoTimer?.invalidate()
        undoTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            if self.isUndoGrouping {
                textView.undoManager?.endUndoGrouping()
                self.isUndoGrouping = false
            }
        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        undoTimer?.invalidate()
        // 入力終了時にグループが開いているなら閉じる
        if let undoManager = undoManager, undoManager.isUndoRegistrationEnabled {
            undoManager.endUndoGrouping()
        }
    }*/
}

