/* For positions within a `contenteditable`, I've used/adapted the following code/resources:

- https://stackoverflow.com/a/41034697
- https://gist.github.com/jh3y/6c066cea00216e3ac860d905733e65c7#file-getcursorxy-js
- https://github.com/konstantinmuenster/notion-clone/commit/4c7193418e4bec03cd250293304b962265367557

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

function setCurrentCursorPosition(chars) {
  if (chars >= 0) {
    var selection = window.getSelection();

    range = createRange(document.getElementById("awesomebar").parentNode, { count: chars });

    if (range) {
      range.collapse(false);
      selection.removeAllRanges();
      selection.addRange(range);
    }
  }
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
  const bar = document.getElementById("awesomebar");
  // Here I need to get the selection position as well.
  // If we're in 'beforeinput', then we can assume focus??
  // I'm not 100% sure, but I don't see how it can be false
  // (barring programmatic input), so the temptation is to go with it…
  // But hey, what can I say, I'm a safety girl!
  bar.focus();
  const sel = document.getSelection();
  const range = sel.getRangeAt(0);
  const clone_range = range.cloneRange();
  clone_range.selectNodeContents(bar);
  clone_range.setEnd(range.startContainer, range.startOffset);
  const start = clone_range.toString().length;
  const end = start + range.toString().length;
  console.log(`Input type: ${event.inputType}.  Start=${start}, End=${end}.`);
  // unless there is an ACTUAL selection, `start` and `end` should be the same.
  if (event.inputType.match("^(insert|delete).*")) {
    // I have to `preventDefault` here because Elm won't handle the actual event.
    // That is because the actual event doesn't contain caret position;
    // I have to synthesise that information & send it through.
    // 
    // It will be notified about its characteristics instead.
    event.preventDefault();
  }
  // Now tell Elm about it.
  console.log(event);
  app.ports.awesomeBarInput.send(
    {
      inputType: event.inputType
      , data: event.data ?? ""
      , start: start
      , end: end
    });
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

function setCaretPosition(pos) {
  // This is called AFTER text-changes have been made.
  // "pos" gives the position in characters from the start.
  // First, let's get the container that contains the text.
  const bar = document.getElementById("awesomebar");
  if (!bar) {
    return;
  }
  console.log(`Setting caret position to ${pos}, for '${bar.innerText}'`);
  let s = document.getSelection();
  let r = document.createRange();
  let textNode = textNodeIn(s.focusNode);
  caretPosition = pos; // should I do this? 🤔
  if (textNode) {
    r.setStart(textNode, pos);
    r.collapse(true);
    s.removeAllRanges();
    s.addRange(r);
  }
};
app.ports.shiftCaret.subscribe((p) => setTimeout(() => setCaretPosition(p), 0));
// app.ports.saveToStorage.subscribe(function(state) {
//   localStorage.setItem("state", state);
//   console.log(JSON.parse(state));
// });
// app.ports.loadResult.subscribe(function(result) {
//   window.alert(result);
// });
