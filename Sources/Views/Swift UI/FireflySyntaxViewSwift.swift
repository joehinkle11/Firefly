//
//  FireflySyntaxViewSwift.swift
//  Firefly
//
//  Created by Zachary lineman on 12/30/20.
//

import SwiftUI

// TODO
/*
- Languages, themes and fontnames do not update automatically
*/

public struct FireflySyntaxEditor: UIViewRepresentable {
    
    @Binding var text: String
    
    let cursorPosition: Binding<CGRect?>?
    let implementUIKeyCommands: (keyCommands: (Selector) -> [UIKeyCommand]?, receiver: (UIKeyCommand) -> Void)?
    let getMoveCursorFunction: ((@escaping ((Int, Int, Int, Bool, Bool)) -> Void) -> Void)?
    let selectedTextRange: Binding<UITextRange?>?
    
    let returnKeyType: UIReturnKeyType?
    let handleReturnKey: (() -> Bool)?
    
    var language: String
    var theme: String
    var fontName: String

    var didChangeText: (FireflySyntaxEditor) -> Void
    var didChangeSelectedRange: (FireflySyntaxEditor, NSRange) -> Void
    var textViewDidBeginEditing: (FireflyTextView) -> Void
    var textViewDidEndEditing: (FireflyTextView) -> Void

    public init(
        text: Binding<String>,
        cursorPosition: Binding<CGRect?>? = nil,
        implementUIKeyCommands: (keyCommands: (Selector) -> [UIKeyCommand]?, receiver: (UIKeyCommand) -> Void)? = nil,
        getMoveCursorFunction: ((@escaping ((Int, Int, Int, Bool, Bool)) -> Void) -> Void)? = nil,
        selectedTextRange: Binding<UITextRange?>? = nil,
        
        returnKeyType: UIReturnKeyType? = nil,
        handleReturnKey: (() -> Bool)? = nil,
        
        language: String,
        theme: String,
        fontName: String,
        didChangeText: @escaping (FireflySyntaxEditor) -> Void,
        didChangeSelectedRange: @escaping (FireflySyntaxEditor, NSRange) -> Void,
        textViewDidBeginEditing: @escaping (FireflyTextView) -> Void,
        textViewDidEndEditing: @escaping (FireflyTextView) -> Void
    ) {
        self._text = text
        
        self.cursorPosition = cursorPosition
        self.implementUIKeyCommands = implementUIKeyCommands
        self.getMoveCursorFunction = getMoveCursorFunction
        self.selectedTextRange = selectedTextRange
        
        self.returnKeyType = returnKeyType
        self.handleReturnKey = handleReturnKey
        
        self.language = language
        self.theme = theme
        self.fontName = fontName
        
        self.didChangeText = didChangeText
        self.didChangeSelectedRange = didChangeSelectedRange
        self.textViewDidBeginEditing = textViewDidBeginEditing
        self.textViewDidEndEditing = textViewDidEndEditing
    }

    public func makeUIView(context: Context) -> FireflySyntaxView {
        let wrappedView = FireflySyntaxView()
        wrappedView.delegate = context.coordinator
        context.coordinator.wrappedView = wrappedView
        context.coordinator.wrappedView.text = text
        context.coordinator.wrappedView.setFont(font: fontName)
        context.coordinator.wrappedView.setTheme(name: theme)
        context.coordinator.wrappedView.setLanguage(nLanguage: language)
        if let returnKeyType = returnKeyType {
            context.coordinator.wrappedView.textView.returnKeyType = returnKeyType
        }
        if let getMoveCursorFunction = getMoveCursorFunction {
            getMoveCursorFunction(context.coordinator.wrappedView.textView.moveCursor(change:))
        }
        return wrappedView
    }

    public func updateUIView(_ uiView: FireflySyntaxView, context: Context) {
        if context.coordinator.wrappedView.fontName != fontName {
            context.coordinator.wrappedView.setFont(font: fontName)
        }
        if context.coordinator.wrappedView.theme != theme {
            context.coordinator.wrappedView.setTheme(name: theme)
        }
        if context.coordinator.wrappedView.language != language {
            context.coordinator.wrappedView.setLanguage(nLanguage: language)
        }
        if let returnKeyType = returnKeyType, returnKeyType != context.coordinator.wrappedView.textView.returnKeyType {
            context.coordinator.wrappedView.textView.returnKeyType = returnKeyType
            context.coordinator.wrappedView.textView.reloadInputViews()
        }
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
     
    public class Coordinator: FireflyDelegate {
        
        public var cursorPositionChange: ((CGRect?) -> Void)?
        public var implementUIKeyCommands: (
            keyCommands: (Selector) -> [UIKeyCommand]?,
            receiver: (_ sender: UIKeyCommand) -> Void
        )?
        
        public func didClickLink(_ link: URL) { }
        public var handleReturnKey: (() -> Bool)?
        public var onSelectedTextRange: ((UITextRange?) -> Void)?
        
        let parent: FireflySyntaxEditor
        var wrappedView: FireflySyntaxView!
        
        init(_ parent: FireflySyntaxEditor) {
            self.parent = parent
            if let cursorPosition = parent.cursorPosition {
                self.cursorPositionChange = {
                    cursorPosition.wrappedValue = $0
                }
            }
            if let implementUIKeyCommands = parent.implementUIKeyCommands {
                self.implementUIKeyCommands = implementUIKeyCommands
            }
            if let handleReturnKey = parent.handleReturnKey {
                self.handleReturnKey = handleReturnKey
            }
            if let selectedTextRange = parent.selectedTextRange {
                self.onSelectedTextRange = {
                    selectedTextRange.wrappedValue = $0
                }
            }
        }
        
        public func didChangeText(_ syntaxTextView: FireflyTextView) {
            Dispatch.main {
                self.parent.text = syntaxTextView.text
            }
            parent.didChangeText(parent)
        }
        
        public func didChangeSelectedRange(_ syntaxTextView: FireflyTextView, selectedRange: NSRange) {
            parent.didChangeSelectedRange(parent, selectedRange)
        }
        
        public func textViewDidBeginEditing(_ textView: FireflyTextView) {
            parent.textViewDidBeginEditing(textView)
        }
        
        public func textViewDidEndEditing(_ textView: FireflyTextView) {
            parent.textViewDidEndEditing(textView)
        }
    }
}
