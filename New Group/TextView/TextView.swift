//
//  TextView.swift
//  DateSections_UITableView3
//
//  Created by Yuki Sasaki on 2025/08/02.
//

import SwiftUI
import UIKit

class DetailViewController: UIViewController {
    var store: MessageStore!
    var message: MessageEntity? {
        didSet {
            print("message set: \(message?.text ?? "nil")")
            messageText = message?.text ?? ""
            messageDate = message?.date // ← ここでdateも保持
        }
    }

    var messageText: String = ""
    var messageDate: Date? // ← 追加

    let textView = UITextView()
    let addButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("選択されたUIViewController: message.text = \(message?.text ?? "nil")")

        view.backgroundColor = .systemBackground
        title = "新規メッセージ"

        setupTextView()
        setupButton()
        setupLayout()
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
