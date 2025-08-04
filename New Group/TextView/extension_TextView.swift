//
//  extension_TextView.swift
//  DateSections_UITableView3
//
//  Created by Yuki Sasaki on 2025/08/03.
//

import SwiftUI

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
