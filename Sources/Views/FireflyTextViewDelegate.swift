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
    
    var scrollViewDidScroll: ((_ scrollView: UIScrollView, _ scrollToCursorPositionWasCalled: Bool) -> Void)? { get }
    
    var onSelectedTextRange: ((UITextRange?) -> Void)? { get }
    
    var onCurrentWord: ((String?) -> Void)? { get }
    
    var implementUIKeyCommands: (
        keyCommands: (_ selector: Selector) -> [UIKeyCommand]?,
        receiver: (_ sender: UIKeyCommand) -> Void
    )? { get }
    
    var handleReturnKey: (() -> Bool)? { get }

    func didChangeText(_ syntaxTextView: FireflyTextView)

    func didChangeSelectedRange(_ syntaxTextView: FireflyTextView, selectedRange: NSRange)
    
    func didChangeSelectedRangeWithoutTextChange(_ syntaxTextView: FireflyTextView, selectedRange: NSRange)

    func textViewDidBeginEditing(_ syntaxTextView: FireflyTextView)
    
    func textViewDidEndEditing(_ textView: FireflyTextView)
    
    func didClickLink(_ link: String)

}
