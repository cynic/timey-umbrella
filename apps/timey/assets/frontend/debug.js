function createRange(node, chars, range) {
  if (!range) {
    range = document.createRange()
    range.selectNode(node);
    range.setStart(node, 0);
  }

  if (chars.count === 0) {
    range.setEnd(node, chars.count);
  } else if (node && chars.count > 0) {
    if (node.nodeType === Node.TEXT_NODE) {
      if (node.textContent.length < chars.count) {
        chars.count -= node.textContent.length;
      } else {
        range.setEnd(node, chars.count);
        chars.count = 0;
      }
    } else {
      for (var lp = 0; lp < node.childNodes.length; lp++) {
        range = createRange(node.childNodes[lp], chars, range);

        if (chars.count === 0) {
          break;
        }
      }
    }
  }
  return range;
};

function isChildOf(node, parentId) {
  if (node === null) return false;
  return node.id === parentId || isChildOf(node.parentNode, parentId);
}

function getCurrentCursorPosition(parentId) {
  var selection = window.getSelection(),
    charCount = -1,
    node;

  if (selection.focusNode) {
    if (isChildOf(selection.focusNode, parentId)) {
      node = selection.focusNode;
      charCount = selection.focusOffset;

      while (node) {
        if (node.id === parentId) {
          break;
        }

        if (node.previousSibling) {
          node = node.previousSibling;
          charCount += node.textContent.length;
        } else {
          node = node.parentNode;
          if (node === null) {
            break
          }
        }
      }
    }
  }

  return charCount;
};

function debugPos() {
  return getCurrentCursorPosition("awesomebar");
}

function trackCaretPosition() {
  document.addEventListener("keyup",
    (e) => {
      caretPosition = getCurrentCursorPosition("awesomebar");
      console.log(`KeyUp TRACKING: Caret position=${getCurrentCursorPosition("awesomebar")}`);
      if (e.key === "Escape") {
        console.log("ESCAPE");
        app.ports.sendEscape.send(null); // "Escape" can mean many things. Let Elm interpret it.
      }
    });

  document.addEventListener("mouseup", (e) =>
    {
      if (e.target.id === "awesomebar" || e.target.parentNode.id === "awesomebar") {
        caretPosition = getCurrentCursorPosition("awesomebar");
        console.log(`MouseUp TRACKING: Caret position=${getCurrentCursorPosition("awesomebar")}`)
      }
      else console.log(e.target);
    }
  );
}