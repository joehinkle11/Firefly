//
//  FireflySyntaxView + TextDelegate.swift
//  Refly
//
//  Created by Zachary lineman on 9/28/20.
//

import UIKit

extension FireflySyntaxView: UITextViewDelegate {
        
    //MARK: UITextViewDelegate
    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if let textRange = NSRange(location: max(0, range.location - 10), length: 10).toTextRange(textInput: textView),
           let previews10Characters = textView.text(in: textRange) {
            onNewText?(previews10Characters, text)
        } else {
            onNewText?("", text)
        }
        let vRange = getVisibleRange()
        if vRange.encompasses(r2: range) { shouldHighlightOnChange = true } else { highlightAll = true }
        
        let selectedRange = textView.selectedRange
        var insertingText = text
        
        if text == "\n", let handleReturnKeyFunction = delegate?.handleReturnKey {
            // if handleReturnKey returns true, it means they will handle the event
            if handleReturnKeyFunction() {
                return false
            }
        }
        
        if text == "\"",
           let nextCharStartPos = textView.position(from: textView.beginningOfDocument, offset: range.upperBound),
           let nextCharEndPos = textView.position(from: textView.beginningOfDocument, offset: range.upperBound + 1),
           let textRange = textView.textRange(from: nextCharStartPos, to: nextCharEndPos),
           let nextCharacter = textView.text(in: textRange),
           nextCharacter == "\"" {
            if let newRangeToSelect = textView.textRange(from: nextCharEndPos, to: nextCharEndPos) {
                self.textView.selectedTextRange = newRangeToSelect
                lastChar = nil
                return false
            }
        }
        
        if placeholdersAllowed {
            //There is a bug here that when a multi-line string that is larger than the visible area is present, it will be partially highlighted because the ranges get messed up.
            let inside = textStorage.insidePlaceholder(cursorRange: selectedRange)
            if inside.0 {
                if let token = inside.1 {
                    let fullRange = NSRange(location: 0, length: self.text.utf8.count)
                    if token.range.upperBound < fullRange.upperBound {
                        textStorage.removeAttribute(.font, range: token.range)
                        textStorage.removeAttribute(.foregroundColor, range: token.range)
                        textStorage.removeAttribute(.editorPlaceholder, range: token.range)
                        
                        textStorage.addAttributes([.font: textStorage.syntax.currentFont, .foregroundColor: textStorage.syntax.theme.defaultFontColor], range: token.range)
                        textStorage.replaceCharacters(in: token.range, with: text)
                        textStorage.cachedTokens.removeAll { (token) -> Bool in return token == token }
                        updateSelectedRange(NSRange(location: token.range.location + text.count, length: 0))
                        textStorage.highlight(getVisibleRange(), cursorRange: selectedRange)
                        
                        return false
                    } else {
                        //Oops they ended up in the middle of a token so just delete what they have and rehighlight the view
                        forceHighlight()
                    }
                }
            }
        }
        
        
        if insertingText == "" && range.length > 0 {
            // Updater on backspace
            updateGutterNow = true
            return true
        } else if insertingText.contains("\n") {
            //If they pasted something with \n
            updateGutterNow = true
        }

        let nsText = textView.text as NSString
        var currentLine = nsText.substring(with: nsText.lineRange(for: textView.selectedRange))
        if currentLine.hasSuffix("\n") {
            currentLine.removeLast()
        }
        let newlineInsert: String = getNewlineInsert(currentLine)
        guard let tView = textView as? FireflyTextView  else { return false }

        if let lastChar = lastChar {
            let lastString: String = String(lastChar) + insertingText
            if lastString == "/*" {
                insertingText += "\n\t\(newlineInsert)\n\(newlineInsert)*/"

                textView.textStorage.replaceCharacters(in: selectedRange, with: insertingText)
                updateSelectedRange(NSRange(location: selectedRange.lowerBound + 3 + newlineInsert.count, length: 0))
                textView.setNeedsDisplay()
                self.lastChar = insertingText.last
                shouldHighlightOnChange = false
                textStorage.editingRange = selectedRange
                textStorage.highlight(getVisibleRange(), cursorRange: selectedRange)
                
                delegate?.didChangeText(tView)
                
                return false
            } else if lastChar == "\"" && text != "\"" && (tView.currentWord() != "\"\"") {
                insertingText += "\""
                
                textView.textStorage.replaceCharacters(in: selectedRange, with: insertingText)
                updateSelectedRange(NSRange(location: selectedRange.lowerBound + 1, length: 0))
                textView.setNeedsDisplay()
                self.lastChar = text.last
                shouldHighlightOnChange = false
                textStorage.editingRange = selectedRange
                textStorage.highlight(getVisibleRange(), cursorRange: selectedRange)
                
                delegate?.didChangeText(tView)

                return false
            } else if lastChar == "{" && text != "}" {
                //Maybe change it so after you hit enter it adds the }
                // Update on new line
                if text == "\n" {
                    insertingText += "\t\(newlineInsert)\n\(newlineInsert)}"
                    textView.textStorage.replaceCharacters(in: selectedRange, with: insertingText)
                    updateSelectedRange(NSRange(location: selectedRange.lowerBound + 2 + newlineInsert.count, length: 0))
                } else {
                    insertingText += "}"
                    textView.textStorage.replaceCharacters(in: selectedRange, with: insertingText)
                    updateSelectedRange(NSRange(location: selectedRange.lowerBound + 1, length: 0))
                }
                
                textView.setNeedsDisplay()
                self.lastChar = text.last
                shouldHighlightOnChange = false
                textStorage.editingRange = selectedRange
                textStorage.highlight(getVisibleRange(), cursorRange: selectedRange)
                
                delegate?.didChangeText(tView)

                return false
            } else if lastChar == "(" && text != ")" {
                insertingText += ")"
                
                textView.textStorage.replaceCharacters(in: selectedRange, with: insertingText)
                updateSelectedRange(NSRange(location: selectedRange.lowerBound + 1, length: 0))
                textView.setNeedsDisplay()
                self.lastChar = text.last
                shouldHighlightOnChange = false
                textStorage.editingRange = selectedRange
                textStorage.highlight(getVisibleRange(), cursorRange: selectedRange)
                
                delegate?.didChangeText(tView)

                return false
            }
        }
        
        lastChar = insertingText.last
        if insertingText == "\n" {
            // Update on new line
            insertingText += newlineInsert
            textView.textStorage.replaceCharacters(in: selectedRange, with: insertingText)
            
            updateSelectedRange(NSRange(location: selectedRange.lowerBound + insertingText.count, length: 0))
            textView.setNeedsDisplay()
            updateGutterWidth()
            shouldHighlightOnChange = false
            textStorage.editingRange = selectedRange
            textStorage.highlight(getVisibleRange(), cursorRange: selectedRange)
            
            delegate?.didChangeText(tView)

            return false
        }
        
        return true
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateCursorPosition()
        if let scrollViewDidScroll = delegate?.scrollViewDidScroll {
            scrollViewDidScroll(scrollView, textView.scrollToCursorPositionWasCalled)
            textView.scrollToCursorPositionWasCalled = false
        }
    }
    
    public func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        delegate?.didClickLink(URL.absoluteString)
        return false
    }
    
    func getNewlineInsert(_ currentLine: String) -> String {
        var newLinePrefix = ""
        for char in currentLine {
            let tempSet = CharacterSet(charactersIn: "\(char)")
            if tempSet.isSubset(of: .whitespacesAndNewlines) {
                newLinePrefix += "\(char)"
            } else {
                break
            }
        }
        return newLinePrefix
    }
    
    private func updateCursorPosition() {
        if let cursorPositionChange = self.delegate?.cursorPositionChange {
            if let pos = self.textView.cursorPosition() {
                cursorPositionChange(self.textView.convert(pos, to: self.textView.superview))
            } else {
                cursorPositionChange(nil)
            }
        }
        if let onSelectedTextRange = self.delegate?.onSelectedTextRange {
            onSelectedTextRange(self.textView.selectedTextRange)
        }
    }
    
    public func textViewDidChangeSelection(_ textView: UITextView) {
        updateCursorPosition()
        if let didChangeSelectedRange = delegate?.didChangeSelectedRange {
            guard let tView = textView as? FireflyTextView else { return }
            didChangeSelectedRange(tView, self.textView.selectedRange)
        }
        if let didChangeSelectedRangeWithoutTextChange = delegate?.didChangeSelectedRangeWithoutTextChange {
            guard let tView = textView as? FireflyTextView else { return }
            let textHash = tView.text.hashValue
            if tView.lastTextHashOnSelectionChange == textHash {
                didChangeSelectedRangeWithoutTextChange(tView, self.textView.selectedRange)
            } else {
                tView.lastTextHashOnSelectionChange = textHash
            }
        }
        if let onCurrentWord = delegate?.onCurrentWord {
            onCurrentWord(self.textView.currentWord3())
        }
    }
    
    public func textViewDidBeginEditing(_ textView: UITextView) {
        guard let tView = textView as? FireflyTextView else { return }
        delegate?.textViewDidBeginEditing(tView)
        updateOverscrolling(isSelected: true)
    }
    
    public func textViewDidEndEditing(_ textView: UITextView) {
        guard let tView = textView as? FireflyTextView else { return }
        delegate?.textViewDidEndEditing(tView)
        updateOverscrolling(isSelected: false)
    }

    func updateSelectedRange(_ range: NSRange) {
        if range.location + range.length <= text.utf8.count {
            textView.selectedRange = range
        }
    }
    
    public func textViewDidChange(_ textView: UITextView) {
        guard let tView = textView as? FireflyTextView else { return }
        if updateGutterNow {
            updateGutterWidth()
        }
        if shouldHighlightOnChange {
            shouldHighlightOnChange = false
            textStorage.editingRange = tView.selectedRange
            textStorage.highlight(getVisibleRange(), cursorRange: tView.selectedRange)
        } else if highlightAll {
            highlightAll = false
            textStorage.highlight(NSRange(location: 0, length: textStorage.string.count), cursorRange: nil)
        }
        delegate?.didChangeText(tView)
    }
    
    func getVisibleRange() -> NSRange {
        let topLeft = CGPoint(x: textView.bounds.minX, y: textView.bounds.minY)
        let bottomRight = CGPoint(x: textView.bounds.maxX, y: textView.bounds.maxY)
        guard let topLeftTextPosition = textView.closestPosition(to: topLeft),
            let bottomRightTextPosition = textView.closestPosition(to: bottomRight)
            else {
                return NSRange(location: 0, length: 0)
        }
        let charOffset = textView.offset(from: textView.beginningOfDocument, to: topLeftTextPosition)
        let length = textView.offset(from: topLeftTextPosition, to: bottomRightTextPosition)
        let visibleRange = NSRange(location: charOffset, length: length)
        return visibleRange
    }
    
    
    public override var keyCommands: [UIKeyCommand]? {
        delegate?.implementUIKeyCommands?.keyCommands(#selector(handleUIKeyCommand))
    }
    
    @objc func handleUIKeyCommand(sender: UIKeyCommand) {
        delegate?.implementUIKeyCommands?.receiver(sender)
    }
}

extension NSRange {
    func toTextRange(textInput:UITextInput) -> UITextRange? {
        if let rangeStart = textInput.position(from: textInput.beginningOfDocument, offset: location),
            let rangeEnd = textInput.position(from: rangeStart, offset: length) {
            return textInput.textRange(from: rangeStart, to: rangeEnd)
        }
        return nil
    }
}
