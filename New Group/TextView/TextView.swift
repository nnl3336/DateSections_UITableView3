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
    var message: MessageEntity?

    private var hasFixedImageSizes = false
    
    var messageText: NSMutableAttributedString = NSMutableAttributedString(string: "")
    var messageDate: Date? // ← 追加
    
    let textView = RichTextView()
    let addButton = UIButton(type: .system)
    
    var coordinator: DetailViewCoordinator!
    
    let ep_accentColor = AccentColorManager.shared
    
    //var undoManager: UndoManager?
    /*var undoTimer: Timer?
     
     var isUndoGrouping = false*/
    
    // Undo/Redo ボタン
    var backButton: UIBarButtonItem!
    var redoButton: UIBarButtonItem!

    // その他のボタン
    var saveButton: UIBarButtonItem!
    var photoButton: UIBarButtonItem!
    var buttonLike: UIBarButtonItem!
    var buttonCheck: UIBarButtonItem!
    var buttonCopy: UIBarButtonItem!
    var newPostButton: UIBarButtonItem!
    
    let ep_textView = TextViewManager()
    
    var newButton: UIBarButtonItem!
    var pencilItem: UIBarButtonItem!
    
    //***
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("選択されたUIViewController: message.text = \((message?.attributedText as? NSAttributedString)?.string ?? "nil")")
        
        view.backgroundColor = .systemBackground
        title = "新規メッセージ"
        
        setupTextView()
        //setupButton()
        setupLayout()
        setupNavigationBar()
        setupToolbar()  // ← ここで追加
        
        coordinator = DetailViewCoordinator(viewController: self)
        
        // ここで toolbar 作成する時に coordinator を使う
        let keyboardToolbar = makeKeyboardToolbar1()
        // toolbar を textView.inputAccessoryView などに設定
        textView.inputAccessoryView = keyboardToolbar
        
        textView.delegate = self
        textView.becomeFirstResponder()
        
        //
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateUndoRedoButtons),
            name: .NSUndoManagerDidUndoChange,
            object: textView.undoManager
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateUndoRedoButtons),
            name: .NSUndoManagerDidRedoChange,
            object: textView.undoManager
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateUndoRedoButtons),
            name: .NSUndoManagerWillCloseUndoGroup,
            object: textView.undoManager
        )
        
        //updateUndoRedoButtons()
        
        // 通知を監視
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.updateMessage(_:withAttributedText:)),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }
    
    //***
}

//

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
        saveButton.isEnabled = (message != nil)
        
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
            target: self,
            action: #selector(self.newPost)
        )
        newPostButton.tintColor = acColor
        //newPostButton.isEnabled = ep_item.item != nil
        newPostButton.isEnabled = (message != nil)
        
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

///

// MARK: - NavigationBar

extension DetailViewController {
    
    func setupNavigationBar() {
        // 左の戻るボタン（custom）
        /*navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backButtonTapped)
        )*/

        // 右のメニューと pencil ボタン
        let trashAction = UIAction(
            title: "Trash",
            image: UIImage(systemName: "trash")
            //attributes: message == nil ? [.destructive, .disabled] : [.destructive]
        ) { _ in
            self.confirmDeleteMessage()
        }

        let menu = UIMenu(title: "", children: [
            UIAction(title: "History", image: UIImage(systemName: "clock")) { _ in
                print("History tapped")
            },
            UIAction(title: "Search Text", image: UIImage(systemName: "magnifyingglass")) { _ in
                print("Search tapped")
            },
            trashAction
        ])

        let menuButton = UIBarButtonItem(image: UIImage(systemName: "ellipsis"), menu: menu)


        newButton = UIBarButtonItem(
            image: UIImage(systemName: "square.and.pencil"),
            style: .plain,
            target: self,
            action: #selector(self.newPost)
        )
        newButton.isEnabled = (message != nil)

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

        pencilItem = UIBarButtonItem(
            image: UIImage(systemName: "square.and.pencil"),
            style: .plain,
            target: self,
            action: #selector(self.newPost)
        )
        pencilItem.isEnabled = (message != nil)

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

// MARK: - Func

extension DetailViewController {
    
    // MARK: - Func Navigation
    
    func confirmDeleteMessage() {
        let alert = UIAlertController(title: "削除の確認",
                                      message: "このメッセージを本当に削除してもよろしいですか？",
                                      preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "キャンセル", style: .cancel))

        alert.addAction(UIAlertAction(title: "削除", style: .destructive) { _ in
            self.deleteMessageAndClose()
        })

        self.present(alert, animated: true)
    }

    
    // MARK: - Func save
    
    func deleteMessageAndClose() {
        guard let message = self.message else { return }
        CoreDataManager.shared.context.delete(message)
        CoreDataManager.shared.saveContext()
        print("✅ Message deleted")
        self.navigationController?.popViewController(animated: true)
    }

    // MARK: - Func UI
    
    func updatenewPostButtonState() {
        newPostButton.isEnabled = (message != nil)
    }
    
    func updatePencilItemState() {
        pencilItem.isEnabled = (message != nil)
    }
    
    func updateNewButtonState() {
        newButton.isEnabled = (message != nil)
    }
    
    func updateSaveButtonState() {
        saveButton.isEnabled = (message != nil)
    }

    
    // MARK: - Func Resize
    
    // 画像のサイズをtextView幅に合わせて補正する関数例
    func fixAttachmentSizes(in attributedString: NSMutableAttributedString, maxWidth: CGFloat) {
        print("📏 fixAttachmentSizes: maxWidth = \(maxWidth)")
        
        attributedString.enumerateAttribute(.attachment, in: NSRange(location: 0, length: attributedString.length)) { value, range, _ in
            guard let attachment = value as? NSTextAttachment else {
                print("🚫 attachment is nil")
                return
            }

            var image: UIImage?

            if let img = attachment.image {
                image = img
                print("🖼️ attachment.image: \(img.size)")
            } else if let data = attachment.contents,
                      let img = UIImage(data: data) {
                image = img
                print("📦 attachment.contents loaded image: \(img.size)")
            } else {
                print("❗ image not found in attachment")
            }

            if let image = image {
                let scale = min(1, maxWidth / image.size.width)
                let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
                print("🔧 resizing to: \(newSize)")
                attachment.bounds = CGRect(origin: .zero, size: newSize)
            }
        }
    }
    
    // MARK: - Func Photo
    
    func handleSelectedImages(_ images: [UIImage]) {
        print("画像が選択されました: \(images.count) 枚")
        for image in images {
            addImageToTextView(image)
        }
    }

    private func addImageToTextView(_ image: UIImage) {
        let attachment = NSTextAttachment()
        attachment.image = image

        // サイズ調整（必要であれば）
        /*let maxWidth = /*textView.frame.width - 20*/ 200*/ let maxWidth = CGFloat(200)  // または CGFloat(textView.frame.width - 20)

        if image.size.width > 0 {
            let scale = maxWidth / image.size.width
            attachment.bounds = CGRect(x: 0, y: 0, width: image.size.width * scale, height: image.size.height * scale)
        }

        let attributedImage = NSAttributedString(attachment: attachment)

        // カーソル位置を取得して挿入
        let cursorPosition = textView.selectedRange.location

        // 現在の状態を保存してUndoに登録
        let previousText = messageText.mutableCopy() as! NSMutableAttributedString
        let previousSelectedRange = textView.selectedRange

        textView.undoManager?.registerUndo(withTarget: self) { target in
            target.messageText = previousText
            target.textView.attributedText = previousText
            target.textView.selectedRange = previousSelectedRange
        }
        textView.undoManager?.setActionName("画像追加")

        // 画像挿入処理
        messageText.insert(attributedImage, at: cursorPosition)

        // textView に反映
        textView.attributedText = messageText

        // カーソル位置を画像の後ろに移動
        let newCursorPosition = cursorPosition + 1
        textView.selectedRange = NSRange(location: newCursorPosition, length: 0)
    }
    
    
    // MARK: - Func Keyboard
    
    private func showCopyToast() {
        let toastLabel = UILabel()
        toastLabel.text = "コピーしました"
        toastLabel.font = UIFont.systemFont(ofSize: 14)
        toastLabel.textColor = .white
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        toastLabel.textAlignment = .center
        toastLabel.layer.cornerRadius = 10
        toastLabel.clipsToBounds = true
        
        let width: CGFloat = 120
        let height: CGFloat = 35
        let x = (self.view.frame.size.width - width) / 2
        let y = self.view.frame.size.height - 120 // フッター上あたり
        
        toastLabel.frame = CGRect(x: x, y: y, width: width, height: height)
        self.view.addSubview(toastLabel)
        
        UIView.animate(withDuration: 0.3, delay: 1.0, options: .curveEaseOut, animations: {
            toastLabel.alpha = 0.0
        }, completion: { _ in
            toastLabel.removeFromSuperview()
        })
    }
    
}

// MARK: - Actions

extension DetailViewController {
    
    // MARK: - Actions paste 手動貼り付け
    
    /*@objc func pasteText() {
            let pasteboard = UIPasteboard.general

            if let rtfData = pasteboard.data(forPasteboardType: "public.rtf") {
                do {
                    let attributedString = try NSAttributedString(
                        data: rtfData,
                        options: [.documentType: NSAttributedString.DocumentType.rtf],
                        documentAttributes: nil
                    )
                    textView.attributedText = attributedString
                    print("✅ RTFを貼り付けました")
                } catch {
                    print("❌ RTFの読み込み失敗: \(error)")
                }
            } else {
                print("❌ PasteboardにRTFがありません")
            }
        }*/
    
    // MARK: - Actions

    @objc func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }

    // MARK: - Actions save
    
    @objc func updateMessage(_ message: MessageEntity, withAttributedText attributedText: NSMutableAttributedString) {
        print("🔷 updateMessage called.")

        guard let data = try? attributedText.data(
            from: NSRange(location: 0, length: attributedText.length),
            documentAttributes: [.documentType: NSAttributedString.DocumentType.rtfd]
        ) else {
            print("❌ Failed to convert attributedText to data.")
            return
        }

        if message.attributedText != data {
            print("🆕 Content changed. Updating and saving.")
            message.attributedText = data
            
            // 🔽 非同期保存（バックグラウンドキュー）
            DispatchQueue.global(qos: .background).async {
                CoreDataManager.shared.saveContext()
                print("💾 CoreDataManager.saveContext() called (async).")
            }
        } else {
            print("⚪️ No changes detected. Skipping save.")
        }

        print("✅ Message update complete.")
        
        // fetchMessages() は不要。FRCが反応するので

    }

    
    /*@objc func newButtonTapped() {
        print("📝 新規作成タップ")
    }*/
    
    @objc func newPost() {
        print("newPost")

        if let message = message {
            print("Updating existing message: \(message)")
            store.updateMessage(message, withAttributedText: messageText)
        } else {
            print("Adding new message")
            store.addMessage(messageText)
        }

        // 設定の初期化（例）
        message = nil
        messageText = NSMutableAttributedString(string: "")
        
        textView.attributedText = messageText

    }
    
    @objc func saveText() {
        print("Save text action")
        if let message = message {
            print("Updating existing message: \(message)")
            store.updateMessage(message, withAttributedText: messageText)
        } else {
            print("Adding new message")
            store.addMessage(messageText)
        }
        if let navigationController = self.navigationController {
            navigationController.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
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
        let attrText = textView.attributedText ?? NSAttributedString(string: "")
        
        do {
            let data = try attrText.data(
                from: NSRange(location: 0, length: attrText.length),
                documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf] // ✅ここを変更
            )
            UIPasteboard.general.items = [
                ["public.rtf": data,
                 "public.utf8-plain-text": attrText.string]
            ]
            print("✅ リッチテキスト（RTF）をコピーしました")
            print("📋 Pasteboard types: \(UIPasteboard.general.types)")
            showCopyToast()
        } catch {
            print("❌ RTFのコピー失敗: \(error)")
        }
    }



    /*@objc func createNewPost() {
        print("Create new post")
    }*/
    
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
        //dismiss(animated: true)
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

    /*func setupButton() {
        addButton.setTitle("追加", for: .normal)
        addButton.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
        addButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(addButton)
    }*/

    func setupLayout() {
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
            textView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 0)
        ])
    }

}

///

// MARK: - Utility Support

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
}

///

// MARK: - UITextViewDelegate

extension DetailViewController: UITextViewDelegate {
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        print("🟡 viewWillDisappear called.")

        if let message = message {
            let attributed = messageText
            print("🟢 Message is not nil. Preparing to update in background.")
            DispatchQueue.global(qos: .background).async {
                print("🔵 Updating message in background thread.")
                self.store.updateMessage(message, withAttributedText: attributed)
                //print("✅ Message update complete.")
            }
        } else {
            print("🔴 Message is nil. Skipping update.")
        }
    }

    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        guard !hasFixedImageSizes, let data = message?.attributedText else { return }

        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.rtfd
        ]
        if let attrText = try? NSMutableAttributedString(data: data, options: options, documentAttributes: nil) {
            fixAttachmentSizes(in: attrText, maxWidth: textView.frame.width - 20)
            messageText = attrText
            textView.attributedText = messageText
            hasFixedImageSizes = true
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        if message == nil {
            message = /*CoreDataManager.shared.createMessage()*/ store.createMessage()
        }
        
        // 編集内容を反映
        messageText = NSMutableAttributedString(attributedString: textView.attributedText)
        
        if let message = message {
            messageText = NSMutableAttributedString(attributedString: textView.attributedText)
        }
        
        updateSaveButtonState()
        updateNewButtonState()
        updatePencilItemState()
        updatenewPostButtonState()
        
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

// MARK: - Custom

class RichTextView: UITextView {
    override func paste(_ sender: Any?) {
        let pasteboard = UIPasteboard.general

        // RTFがある場合はリッチテキストとして貼り付け
        if let rtfData = pasteboard.data(forPasteboardType: "public.rtf") {
            do {
                let attributedString = try NSAttributedString(
                    data: rtfData,
                    options: [.documentType: NSAttributedString.DocumentType.rtf],
                    documentAttributes: nil
                )
                self.textStorage.replaceCharacters(in: self.selectedRange, with: attributedString)
                print("✅ リッチテキストをペーストしました")
            } catch {
                print("❌ RTF読み込み失敗: \(error)")
            }
        } else {
            // 通常のプレーンテキスト貼り付け
            super.paste(sender)
        }
    }
}
