//
//  FireflyDelegate.swift
//  Firefly
//
//  Created by Zachary lineman on 9/29/20.
//  Copyright © 2020 Zachary Lineman. All rights reserved.
//

import Foundation
import UIKit

public protocol FireflyDelegate: AnyObject {
    var cursorPositionChange: ((_ cursorPosition: CGRect?) -> Void)? { get }
    
    var onSelectedTextRange: ((UITextRange?) -> Void)? { get }
    
    var implementUIKeyCommands: (
        keyCommands: (_ selector: Selector) -> [UIKeyCommand]?,
        receiver: (_ sender: UIKeyCommand) -> Void
    )? { get }
    
    var handleReturnKey: (() -> Bool)? { get }

    func didChangeText(_ syntaxTextView: FireflyTextView)

    func didChangeSelectedRange(_ syntaxTextView: FireflyTextView, selectedRange: NSRange)

    func textViewDidBeginEditing(_ syntaxTextView: FireflyTextView)
    
    func textViewDidEndEditing(_ textView: FireflyTextView)
    
    func didClickLink(_ link: String)

}

// Provide default empty implementations of methods that are optional.
public extension FireflyDelegate {
    var cursorPositionChange: ((_ cursorPosition: CGRect?) -> Void)? { nil }
    
    var onSelectedTextRange: ((UITextRange?) -> Void)? { nil }
    
    var implementUIKeyCommands: (keyCommands: (Selector) -> [UIKeyCommand]?, receiver: (UIKeyCommand) -> Void)? { nil }
    
    var handleReturnKey: (() -> Bool)? { nil }
    
    func didChangeText(_ syntaxTextView: FireflyTextView) { }

    func didChangeSelectedRange(_ syntaxTextView: FireflyTextView, selectedRange: NSRange) { }

    func textViewDidBeginEditing(_ syntaxTextView: FireflyTextView) { }
    
    func textViewDidEndEditing(_ textView: FireflyTextView) {}
    
    func didClickLink(_ link: String) { }
}
