/* For positions within a `contenteditable`, I've used/adapted the following code/resources:

- https://stackoverflow.com/a/41034697
- https://gist.github.com/jh3y/6c066cea00216e3ac860d905733e65c7#file-getcursorxy-js
- https://github.com/konstantinmuenster/notion-clone/commit/4c7193418e4bec03cd250293304b962265367557
- https://www.w3.org/TR/edit-context/

…as well as the usual MDN etc documentation.
*/

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

let app = Elm.Main.init({
  node: document.getElementById('myapp'),
  flags: null
});

caretPosition = 0;

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
    // else console.log(e.target);
  }
);
isComposing = false;
lastInputEvent = null;
function trackCompositionStart(e) {
  isComposing = true;
}
function trackCompositionEnd(e) {
  isComposing = false;
  beforeInputListener(lastInputEvent);
  lastInputEvent = null;
}
function beforeInputListener(event) {
  if (isComposing) {
    console.log(`Got ${event.inputType} but still composing.`);
    lastInputEvent = event;
    return; // let the composition continue; come back when it's done.
  }
  if (event.inputType.match("^(insert|delete).*")) {
    // I have to `preventDefault` here because Elm won't handle the actual event.
    // That is because the actual event doesn't contain caret position;
    // I have to synthesise that information & send it through.
    // 
    // It will be notified about its characteristics instead.
    event.preventDefault();
  }
  console.log(event);
  if (event.inputType === "insertReplacementText") {
    const replacement = event.dataTransfer.getData("text");
    const range = event.getTargetRanges()[0];
    // Now tell Elm about it.
    console.log(`Input type: ${event.inputType}.  Start=${range.startOffset}, End=${range.endOffset}.`);
    app.ports.awesomeBarInput.send(
      {
        inputType: event.inputType
        , data: replacement
        , start: range.startOffset
        , end: range.endOffset
      });
  } else {
    const bar = document.getElementById("awesomebar");
    // Here I need to get the selection position as well.
    // If we're in 'beforeinput', then we can assume focus??
    // I'm not 100% sure, but I don't see how it can be false
    // (barring programmatic input), so the temptation is to go with it…
    // But hey, what can I say, I'm a safety girl!
    // bar.focus();
    const range = window.getSelection().getRangeAt(0);
    const preSelectionRange = range.cloneRange();
    preSelectionRange.selectNodeContents(bar);
    preSelectionRange.setEnd(range.startContainer, range.startOffset);
    const start = preSelectionRange.toString().length;
    const end = start + range.toString().length;
    // unless there is an ACTUAL selection, `start` and `end` should be the same.
    // Now tell Elm about it.
    console.log(`Input type: ${event.inputType}.  Start=${start}, End=${end}.`);
    app.ports.awesomeBarInput.send(
      {
        inputType: event.inputType
        , data: event.inputType === "insertFromPaste"
            ? event.dataTransfer.getData("text")
            : event.data ?? ""
        , start: start
        , end: end
      });
    }
}
function goodbyeBar() {
  const bar = document.getElementById("awesomebar");
  if (!bar) {
    return;
  }
  bar.removeEventListener("beforeinput", beforeInputListener);
  bar.removeEventListener("compositionstart", trackCompositionStart);
  bar.removeEventListener("compositionend", trackCompositionEnd);
  app.ports.listenerRemoved.send(null); // Tell Elm that it can now get rid of the element
}
function initializeBar() {
  const bar = document.getElementById("awesomebar");
  if (!bar) {
    setTimeout(initializeBar, 50);
    return;
  }
  bar.addEventListener("beforeinput", beforeInputListener);
  bar.addEventListener("compositionstart", trackCompositionStart);
  bar.addEventListener("compositionend", trackCompositionEnd);
  bar.focus();
}
app.ports.displayAwesomeBar.subscribe(initializeBar);
app.ports.hideAwesomeBar.subscribe(goodbyeBar);

function textNodeIn(node) {
  if (node.nodeType === Node.TEXT_NODE) {
    return node;
  }
  return Array.from(node.childNodes).find(textNodeIn);
}

function setCaretPosition(pos, bar) {
  // This is called AFTER text-changes have been made.
  // "pos" gives the position in characters from the start.
  // First, let's get the container that contains the text.
  console.log(`Setting caret position to ${pos}, for '${bar.innerText}'`);
  let s = document.getSelection();
  let r = document.createRange();
  let textNode = textNodeIn(s.focusNode);
  caretPosition = pos; // should I do this? 🤔
  if (textNode) {
    count = 0;
    let execute = function() {
      try {
        r.setStart(textNode, pos);
        r.collapse(true);
        s.removeAllRanges();
        s.addRange(r);
      } catch (e) {
        console.log(e);
        if (count < 5) {
          count++;
          setTimeout(execute, 5); // the system must be under some stress…?
        }
      }
    };
    execute();
  }
};
app.ports.shiftCaret.subscribe((p) => {
  const bar = document.getElementById("awesomebar");
  if (!bar) {
    return;
  }
  setTimeout(() => setCaretPosition(p, bar), 0)
});
// app.ports.saveToStorage.subscribe(function(state) {
//   localStorage.setItem("state", state);
//   console.log(JSON.parse(state));
// });
// app.ports.loadResult.subscribe(function(result) {
//   window.alert(result);
// });
