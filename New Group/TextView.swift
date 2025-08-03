//
//  TextView.swift
//  DateSections_UITableView3
//
//  Created by Yuki Sasaki on 2025/08/02.
//

import SwiftUI
import UIKit

class DetailViewController: UIViewController, UITextViewDelegate {
    var store: MessageStore!  // SwiftUIのObservedObjectの代わりに参照を持つ
    var messageText: String = ""

    private let textView = UITextView()
    private let addButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        title = "新規メッセージ"

        setupTextView()
        setupButton()
        setupLayout()
    }

    private func setupTextView() {
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.delegate = self
        textView.text = messageText
        textView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(textView)
    } 

    private func setupButton() {
        addButton.setTitle("追加", for: .normal)
        addButton.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
        addButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(addButton)
    }

    private func setupLayout() {
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            textView.heightAnchor.constraint(equalToConstant: 200),

            addButton.topAnchor.constraint(equalTo: textView.bottomAnchor, constant: 20),
            addButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    @objc private func addButtonTapped() {
        store.addMessage(textView.text)
        dismiss(animated: true)
    }

    // UITextViewDelegate
    func textViewDidChange(_ textView: UITextView) {
        messageText = textView.text
    }
}

//SwiftUI

/*

struct DetailView: View {
    @ObservedObject var store: MessageStore
    @Environment(\.dismiss) var dismiss
    @State private var messageText = ""

    var body: some View {
        VStack {
            TextViewWrapper(text: $messageText)
                .frame(height: 200)
                .padding()

            Button("追加") {
                store.addMessage(messageText)
                dismiss()
            }
        }
        .navigationTitle("新規メッセージ")
    }
}

struct TextViewWrapper: UIViewRepresentable {
    @Binding var text: String

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.delegate = context.coordinator
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.text = text
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: TextViewWrapper

        init(_ parent: TextViewWrapper) {
            self.parent = parent
        }

        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
        }
    }
}
*/
