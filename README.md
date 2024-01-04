From: https://w3c.github.io/input-events/#interface-InputEvent-Attributes

```
inputType                       User's expression of intention    Part of IME composition   beforeinput cancelable    State of selection
✅"insertText"                    insert typed plain text 	No 	Yes 	Any
✅"insertReplacementText"         replace existing text by means of a spell checker, auto-correct or similar 	No 	Yes 	Any
❌"insertLineBreak" 	            insert a line break 	No 	Yes 	Any
❌"insertParagraph" 	            insert a paragraph break 	No 	Yes 	Any
❌"insertOrderedList" 	          insert a numbered list 	No 	Yes 	Any
❌"insertUnorderedList" 	        insert a bulleted list 	No 	Yes 	Any
❌"insertHorizontalRule" 	        insert a horizontal rule 	No 	Yes 	Any
❌"insertFromYank" 	              replace the current selection with content stored in a kill buffer 	No 	Yes 	Any
❌"insertFromDrop" 	              insert content by means of drop 	No 	Yes 	Any
✅"insertFromPaste" 	            paste content from clipboard or paste image from client provided image library 	No 	Yes 	Any
❌"insertFromPasteAsQuotation" 	  paste content from the clipboard as a quotation 	No 	Yes 	Any
⁉️"insertTranspose" 	            transpose the last two [=grapheme cluster=]. that were entered 	No 	Yes 	Any
✅"insertCompositionText" 	      replace the current composition string 	Yes 	No 	Any
❌"insertLink" 	                  insert a link 	No 	Yes 	Any
⁉️"deleteWordBackward" 	          delete a word directly before the caret position 	No 	Yes 	Collapsed
⁉️"deleteWordForward" 	          delete a word directly after the caret position 	No 	Yes 	Collapsed
❌"deleteSoftLineBackward" 	      delete from the caret to the nearest visual line break before the caret position 	No 	Yes 	Collapsed
❌"deleteSoftLineForward" 	      delete from the caret to the nearest visual line break after the caret position 	No 	Yes 	Collapsed
❌"deleteEntireSoftLine" 	        delete from to the nearest visual line break before the caret position to the nearest visual line break after the caret position 	No 	Yes 	Collapsed
❌"deleteHardLineBackward" 	      delete from the caret to the nearest beginning of a block element or br element before the caret position 	No 	Yes 	Collapsed
❌"deleteHardLineForward" 	      delete from the caret to the nearest end of a block element or br element after the caret position 	No 	Yes 	Collapsed
❌"deleteByDrag" 	                remove content from the DOM by means of drag 	No 	Yes 	Any
✅"deleteByCut" 	                remove the current selection as part of a cut 	No 	Yes 	Any
✅"deleteContent" 	              delete the selection without specifying the direction of the deletion and this intention is not covered by another inputType 	No 	Yes 	Non-collapsed
✅"deleteContentBackward" 	      delete the content directly before the caret position and this intention is not covered by another inputType or delete the selection with the selection collapsing to its start after the deletion 	No 	Yes 	Any
✅"deleteContentForward" 	        delete the content directly after the caret position and this intention is not covered by another inputType or delete the selection with the selection collapsing to its end after the deletion 	No 	Yes 	Any
⁉️"historyUndo" 	                undo the last editing action 	No 	Yes 	Any
⁉️"historyRedo" 	                to redo the last undone editing action 	No 	Yes 	Any
❌"formatBold" 	                  initiate bold text 	No 	Yes 	Any
❌"formatItalic" 	                initiate italic text 	No 	Yes 	Any
❌"formatUnderline" 	            initiate underline text 	No 	Yes 	Any
❌"formatStrikeThrough" 	        initiate stricken through text 	No 	Yes 	Any
❌"formatSuperscript" 	          initiate superscript text 	No 	Yes 	Any
❌"formatSubscript" 	            initiate subscript text 	No 	Yes 	Any
❌"formatJustifyFull" 	          make the current selection fully justified 	No 	❌Yes 	Any
❌"formatJustifyCenter" 	        center align the current selection 	No 	Yes 	Any
❌"formatJustifyRight" 	          right align the current selection 	No 	Yes 	Any
❌"formatJustifyLeft" 	          left align the current selection 	No 	Yes 	Any
❌"formatIndent" 	                indent the current selection 	No 	Yes 	Any
❌"formatOutdent" 	              outdent the current selection 	No 	Yes 	Any
❌"formatRemove" 	                remove all formatting from the current selection 	❌No 	Yes 	Any
❌"formatSetBlockTextDirection"   set the text block direction 	No 	Yes 	Any
❌"formatSetInlineTextDirection"  set the text inline direction 	No 	Yes 	Any
❌"formatBackColor" 	            change the background color 	No 	Yes 	Any
❌"formatFontColor" 	            change the font color 	No 	Yes 	Any
❌"formatFontName" 	              change the font-family 	No 	Yes 	Any
```