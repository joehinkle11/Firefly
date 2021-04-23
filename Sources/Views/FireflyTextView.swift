//
//  FireflyTextView.swift
//  Refly
//
//  Created by Zachary lineman on 9/28/20.
//

import UIKit

public class FireflyTextView: UITextView {
    /// used to keep track if text changes or not
    internal var lastTextHashOnSelectionChange: Int = 0
    
    var gutterWidth: CGFloat = 20 {
        didSet {
            textContainerInset.left = gutterWidth
        }
    }
    
    /// Returns a CGRect for the cursor position in the text view's coordinates. If no cursor is present, it returns nil.
    /// source: https://stackoverflow.com/a/43167060/3902590
    public func cursorPosition() -> CGRect? {
        if let selectedRange = self.selectedTextRange
        {
            // `caretRect` is in the `textView` coordinate space.
            return self.caretRect(for: selectedRange.end)
        } else {
            // No selection and no caret in UITextView.
            return nil
        }
    }
    
    internal var scrollToCursorPositionWasCalled = false
    /// put the caret to the center of the scroll view (by scrolling the view)
    public func scrollToCursorPosition() {
        guard let caret = cursorPosition() else {
            return
        }
        let desiredY = max(caret.origin.y - self.bounds.height + 20, min(caret.origin.y - 20, self.contentOffset.y - 0.01))
        if desiredY > self.contentOffset.y {
            Dispatch.main {
                self.scrollToCursorPositionWasCalled = true
                self.setContentOffset(.init(x: self.contentOffset.x, y: desiredY), animated: false)
            }
        }
     }
    
    /// directionGoingRight: true = right, false = left
    func getNextRange(x: Int, y: Int, mode: Int, directionGoingRight: Bool) -> UITextRange? {
        func moveUpOrDownByOne(y: Int) -> UITextRange? {
            if let cursorPosition = cursorPosition() {
                if let newPosition = self.closestPosition(to: .init(x: cursorPosition.midX, y: cursorPosition.midY + (cursorPosition.height * CGFloat(y)))) {
                    return self.textRange(from: newPosition, to: newPosition)
                }
            }
            return nil
        }
        if mode == 0 {
            if y != 0 {
                return moveUpOrDownByOne(y: y)
            } else if let selectedRange = self.selectedTextRange {
                if let newPosition = self.position(from: directionGoingRight ? selectedRange.end : selectedRange.start, offset: x) {
                    return self.textRange(from: newPosition, to: newPosition)
                }
            }
        } else if mode == 1 {
            if y != 0 {
                return moveUpOrDownByOne(y: y)
            } else if let currentSelectedRange = self.selectedTextRange, let currentWordRange = self.currentWordRange2(from: directionGoingRight ? currentSelectedRange.end : currentSelectedRange.start) {
                // by word
                var newLocation = currentWordRange.start
                if x > 0 {
                    if currentWordRange.end == (directionGoingRight ? currentSelectedRange.end : currentSelectedRange.start) {
                        guard let loc = self.position(from: currentSelectedRange.end, offset: x) else {
                            return nil
                        }
                        newLocation = loc
                    } else {
                        newLocation = currentWordRange.end
                    }
                } else {
                    if currentWordRange.start == (directionGoingRight ? currentSelectedRange.end : currentSelectedRange.start) {
                        guard let loc = self.position(from: currentSelectedRange.start, offset: x) else {
                            return nil
                        }
                        newLocation = loc
                    } else {
                        newLocation = currentWordRange.start
                    }
                }
                return self.textRange(from: newLocation, to: newLocation)
            }
        } else if mode == 2 {
            if y > 0 {
                return self.textRange(from: self.endOfDocument, to: self.endOfDocument)
            } else if y < 0 {
                return self.textRange(from: self.beginningOfDocument, to: self.beginningOfDocument)
            } else if let currentLineRange = self.currentLineRange() {
                // by line
                if x > 0 {
                    return self.textRange(from: currentLineRange.end, to: currentLineRange.end)
                } else if x < 0 {
                    return self.textRange(from: currentLineRange.start, to: currentLineRange.start)
                }
            }
        }
        return nil
    }
    
    /// source for moving left and right: https://stackoverflow.com/a/34922332/3902590
    /// mode 0 = normal, 1 = by word, 2 = to end
    public func moveCursor(change: (x: Int, y: Int, mode: Int, shiftActive: Bool, directionGoingRight: Bool)) {
        guard let nextRange = getNextRange(x: change.x, y: change.y, mode: change.mode, directionGoingRight: change.directionGoingRight) else {
            return
        }
        if change.shiftActive {
            guard let currentPos = self.selectedTextRange else {
                return
            }
            if change.directionGoingRight {
                let currentPosStartInt = self.offset(from: self.beginningOfDocument, to: currentPos.start)
                let nextRangeEndInt = self.offset(from: self.beginningOfDocument, to: nextRange.end)
                if nextRangeEndInt < currentPosStartInt {
                    self.selectedTextRange = self.textRange(from: currentPos.start, to: currentPos.start)
                } else {
                    self.selectedTextRange = self.textRange(from: currentPos.start, to: nextRange.end)
                }
            } else {
                let currentPosEndInt = self.offset(from: self.beginningOfDocument, to: currentPos.end)
                let nextRangeStartInt = self.offset(from: self.beginningOfDocument, to: nextRange.start)
                if nextRangeStartInt > currentPosEndInt {
                    self.selectedTextRange = self.textRange(from: currentPos.end, to: currentPos.end)
                } else {
                    self.selectedTextRange = self.textRange(from: nextRange.start, to: currentPos.end)
                }
            }
        } else {
            self.selectedTextRange = nextRange
        }
    }
    
    
    public func currentWordRange2(from pos: UITextPosition) -> UITextRange? {
        var position = pos
        func getRange(from position: UITextPosition, offset: Int) -> UITextRange? {
            guard let newPosition = self.position(from: position, offset: offset) else { return nil }
            return self.textRange(from: newPosition, to: position)
        }
        
        var wordStartPosition: UITextPosition = self.beginningOfDocument
        var wordEndPosition: UITextPosition = self.endOfDocument
        
        var hasSeenNonWhitespace = false
        
        while let range = getRange(from: position, offset: -1), let text = self.text(in: range), let scalar = text.unicodeScalars.first {
            if (text == " " || text == "\t" || text == "\n") && !hasSeenNonWhitespace {
                
            } else if !CharacterSet.alphanumerics.contains(scalar) && !text.contains("_") {
                wordStartPosition = range.end
                break
            } else {
                hasSeenNonWhitespace = true
            }
            position = range.start
        }
        
        position = pos
        
        hasSeenNonWhitespace = false
        
        while let range = getRange(from: position, offset: 1), let text = self.text(in: range), let scalar = text.unicodeScalars.last {
            if (text == " " || text == "\t" || text == "\n") && !hasSeenNonWhitespace {
                
            } else if !CharacterSet.alphanumerics.contains(scalar) && !text.contains("_") {
                if let pos = self.position(from: range.end, offset: -1) {
                    wordEndPosition = pos
                }
                break
            } else {
                hasSeenNonWhitespace = true
            }
            position = range.end
        }
        
        return self.textRange(from: wordStartPosition, to: wordEndPosition)
    }
    
    public func currentLineRange() -> UITextRange? {
        guard let cursorRange = self.selectedTextRange else { return nil }
        func getRange(from position: UITextPosition, offset: Int) -> UITextRange? {
            guard let newPosition = self.position(from: position, offset: offset) else { return nil }
            return self.textRange(from: newPosition, to: position)
        }
        
        var wordStartPosition: UITextPosition = cursorRange.start
        var wordEndPosition: UITextPosition = self.endOfDocument
        
        var position = cursorRange.start
        
        while let range = getRange(from: position, offset: -1), let text = self.text(in: range) {
            if text != "\n" && text != " " && text != "\t" {
                wordStartPosition = range.start
            }
            if text == "\n" {
                break
            }
            position = range.start
        }
        
        position = cursorRange.start
        
        while let range = getRange(from: position, offset: 1), let text = self.text(in: range) {
            if text == "\n" {
                wordEndPosition = range.start
                break
            }
            position = range.end
        }
        
        return self.textRange(from: wordStartPosition, to: wordEndPosition)
    }
    
    public func currentWordRange() -> UITextRange? {
        guard let cursorRange = self.selectedTextRange else { return nil }
        func getRange(from position: UITextPosition, offset: Int) -> UITextRange? {
            guard let newPosition = self.position(from: position, offset: offset) else { return nil }
            return self.textRange(from: newPosition, to: position)
        }
        
        var wordStartPosition: UITextPosition = self.beginningOfDocument
        var wordEndPosition: UITextPosition = self.endOfDocument
        
        var position = cursorRange.start
        
        while let range = getRange(from: position, offset: -1), let text = self.text(in: range) {
            if text == " " || text == "\n" {
                wordStartPosition = range.end
                break
            }
            position = range.start
        }
        
        position = cursorRange.start
        
        while let range = getRange(from: position, offset: 1), let text = self.text(in: range) {
            if text == " " || text == "\n" {
                wordEndPosition = range.start
                break
            }
            position = range.end
        }
        
        return self.textRange(from: wordStartPosition, to: wordEndPosition)
    }
    
    public func currentWord() -> String {
        guard let wordRange = currentWordRange() else { return "" }
        
        return self.text(in: wordRange) ?? ""
    }
    
    public func currentWord3() -> (range: UITextRange, currentWordText: String, leadingText: [String])? {
        guard let start = self.selectedTextRange?.start else { return nil }
        guard let wordRange = currentWordRange3(from: start) else { return nil }
        let leadingText = self.leadingText(from: wordRange.start)
        return (range: wordRange, currentWordText: text(in: wordRange) ?? "", leadingText: leadingText ?? [])
    }
    
    public func currentWordRange3(from pos: UITextPosition) -> UITextRange? {
        var position = pos
        func getRange(from position: UITextPosition, offset: Int) -> UITextRange? {
            guard let newPosition = self.position(from: position, offset: offset) else { return nil }
            return self.textRange(from: newPosition, to: position)
        }
        
        var wordStartPosition: UITextPosition = self.beginningOfDocument
        var wordEndPosition: UITextPosition = self.endOfDocument
        
        while let range = getRange(from: position, offset: -1), let text = self.text(in: range), let scalar = text.unicodeScalars.first {
            if !CharacterSet.alphanumerics.contains(scalar) && !text.contains("_") {
                wordStartPosition = range.end
                break
            }
            position = range.start
        }
        
        position = pos
        
        while let range = getRange(from: position, offset: 1), let text = self.text(in: range), let scalar = text.unicodeScalars.last {
            if !CharacterSet.alphanumerics.contains(scalar) && !text.contains("_") {
                if let pos = self.position(from: range.end, offset: -1) {
                    wordEndPosition = pos
                }
                break
            }
            position = range.end
        }
        
        return self.textRange(from: wordStartPosition, to: wordEndPosition)
    }
    
    public func leadingText(from pos: UITextPosition) -> [String]? {
        var position = pos
        func getRange(from position: UITextPosition, offset: Int) -> UITextRange? {
            guard let newPosition = self.position(from: position, offset: offset) else { return nil }
            return self.textRange(from: newPosition, to: position)
        }
        
        var wordStartPosition: UITextPosition = self.beginningOfDocument
        
        var waitUntilWeFind: [String] = []
//        guard var newEnd = self.position(from: pos, offset: -1) else {
//            return nil
//        }
        var newEnd = pos
        var allowSpace = false
        var allowNewline = false
        var texts: [String] = []
        var hasFoundALetterOrSomething = false
        while let range = getRange(from: position, offset: -1), let text = self.text(in: range), let scalar = text.unicodeScalars.first {
            if allowSpace && (text == " " || text == "\t") {
            } else if allowNewline && text == "\n" {
            } else if text == ")" {
                waitUntilWeFind.append("(")
            } else if text == "]" {
                waitUntilWeFind.append("[")
            } else if text == "}" {
                waitUntilWeFind.append("{")
            } else if text == "\"" && waitUntilWeFind.last != "\"" {
                waitUntilWeFind.append("\"")
            } else if let tryToFind = waitUntilWeFind.last {
                if text == tryToFind {
                    waitUntilWeFind = waitUntilWeFind.dropLast()
                    if let range = self.textRange(from: range.start, to: newEnd) {
                        if let nText = self.text(in: range) {
                            texts.append(nText)
                        }
                    }
                    newEnd = range.start
                    if text == "{" {
                        allowSpace = true
                        allowNewline = true
                    } else if text == "(" {
                        allowSpace = true
                        allowNewline = false
                    } else {
                        allowSpace = false
                        allowNewline = false
                    }
                }
            } else if text.contains("(") || text.contains("[") || text.contains("{") {
                texts.append(text)
                newEnd = range.start
            } else if hasFoundALetterOrSomething && text.contains(".") {
                if let range = self.textRange(from: range.start, to: newEnd) {
                    if let nText = self.text(in: range) {
                        texts.append(nText)
                    }
                }
                allowSpace = true
                allowNewline = true
            } else if !CharacterSet.alphanumerics.contains(scalar) && !text.contains("_") && !text.contains(".") && !text.contains("?") && !text.contains("\\") {
                wordStartPosition = range.end
                if let range = self.textRange(from: range.end, to: newEnd) {
                    if let nText = self.text(in: range) {
                        texts.append(nText)
                    }
                }
                break
            } else {
                hasFoundALetterOrSomething = true
                if text.contains(".") {
                    allowSpace = true
                    allowNewline = true
                } else {
                    allowSpace = false
                    allowNewline = false
                }
            }
            position = range.start
        }
        
        position = pos
        if wordStartPosition == self.beginningOfDocument {
            return nil
        }
        return texts.reversed()
    }
}
