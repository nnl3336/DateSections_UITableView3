//
//  extension_TextView.swift
//  DateSections_UITableView3
//
//  Created by Yuki Sasaki on 2025/08/03.
//

import SwiftUI

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

// MARK: - toolbar

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

// MARK: - UITextViewDelegate

extension DetailViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        messageText = NSMutableAttributedString(attributedString: textView.attributedText)
    }
}
