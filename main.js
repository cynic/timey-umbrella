/* For positions within a `contenteditable`, I've used/adapted the following code/resources:

- https://stackoverflow.com/a/41034697
- https://gist.github.com/jh3y/6c066cea00216e3ac860d905733e65c7#file-getcursorxy-js
- https://github.com/konstantinmuenster/notion-clone/commit/4c7193418e4bec03cd250293304b962265367557
- https://www.w3.org/TR/edit-context/

…as well as the usual MDN etc documentation.
*/

/*
What problem am I leaving open?

The cursor seems to skip back to the start of the input after every keypress.
So when input comes in too fast (e.g., backspace held down), the key suddenly
"stops working" at the right place and the cursor is teleported to the very
start of the contenteditable.

1. WHY is it teleported to the start in the first place?? Can this just be stopped?

All the way until the end of the `beforeinput` event, there's no issue.
The event completes correctly.  However, at the start of `setCaretPosition`,
the caret position is suddenly 0.

Between the two of these, this happens:
  1. The `awesomeBarInput` functionality is invoked.  This happens immediately,
     as a function call.  All good.
  2. `shiftCaret` is called (call to JS from Elm).  All good.
  3. `setCaretPosition` is deferred; it's called with `setTimeout`.  All good.
  4. View function is called and DOM is diffed/updated.  Caret position set to 0,
     and this does not appear to be under my control (it's an Elm-ism, I think).
  5. `setCaretPosition`, which was deferred, is called and the caret position is
     updated.

Between (4) and (5), the user has the opportunity to input data at the INCORRECT
position (i.e. 0).

2. If not, can I at least detect it and/or correct it?

Yes.  I've changed the design:
("bar", Keyed.node "
  1. The `awesomeBarInput` functionality is invoked.  This happens immediately,
     as a function call.  All good.

     NOTE: this might OR MIGHT NOT continue on to (2) etc. `NoOp` might result in
     nothing else being done.

  2. `shiftCaret` is called (call to JS from Elm).  It assigns the correct caret
     position to `caretPosition`.
  3. View function is called and DOM is diffed/updated.  Caret position set to 0,
     and this does not appear to be under my control (it's an Elm-ism, I think).
  4. A mutation observer (set up during initialization of awesomebar) picks up the
     DOM change as soon as it happens, and calls `setCaretPosition`, which uses the
     `caretPosition` sent through in (2).

There is much less time taken between (3) and (4), so to the user, the caret
position seems to always be correct.
*/

caretPosition = 0; // this is set via the `shiftCaret` port
isComposing = false;
lastInputEvent = null;
lastInputEvent_range = null;
bar = null;
textRange = null;
caretTracker = 0; // this is SEPARATE from caretPosition.
// 👆 this is used to tell Elm what JS sees as the caret position.  It will not
// result in Elm forcing a change of caret position.

let app = Elm.Main.init({
  node: document.getElementById('myapp'),
  flags: null
});

document.addEventListener("keyup", (e) => { checkCaretChange(); });
document.addEventListener("mouseup", (e) => { checkCaretChange(); });

function setCaretPosition() {
  const children = Array.from(bar.childNodes);
  var char_count = caretPosition;
  for (const child of children) {
    if (child.nodeType == Node.ELEMENT_NODE && child.dataset.completion !== undefined) {
      // skip over completions.
      continue;
    }
    console.log(child);
    this_length = child.textContent.length;
    if (char_count - this_length <= 0) { // we've reached the right place!
      let offset = char_count;
      let s = document.getSelection();
      let txt = child.childNodes[0]; // this would be a TEXT node.
      textRange = document.createRange();
      textRange.setStart(txt, offset);
      textRange.collapse(true);
      s.removeAllRanges();
      s.addRange(textRange);
    }
    char_count -= this_length;
  }
}

_debug_getCaretPosition_f = null;
_debug_getCaretPosition_a = null;

// We have one of these cases:
// div#awesomebar > div > span > text
// OR
// div#awesomebar > div > text
function getCaretPositions() {
  const selection = window.getSelection();
  let getFocusPosition = () => {
    // find the node with focus.
    const focused = selection.focusNode;
    if (focused === null) return -1;
    const offset = selection.focusOffset;
    // if this is a text-node, then the awesomebar must be two levels up.
    var focused_child;
    // case: div#awesomebar > div > text
    if (focused.nodeType == Node.TEXT_NODE && focused.parentNode.parentNode.id === "awesomebar") {
      focused_child = focused;
    // case: div #awesomebar > div > span > text
    } else if (focused.nodeType == Node.TEXT_NODE && focused.parentNode.parentNode.parentNode.id === "awesomebar") {
      focused_child = focused.parentNode;
    } else {
      console.log("FOCUS: Where is this node?  I don't know.  See _debug_getCaretPosition_f.");
      _debug_getCaretPosition_f = focused;
      console.log(focused);
      return -1;
    }
    // Now get the very first child of the awesomebar, counting chars on the way.
    var char_count = offset;
    for (var current = focused_child.previousSibling; current; current = current.previousSibling) {
      if (current.nodeType == Node.ELEMENT_NODE && current.dataset.completion !== undefined) {
        // skip over completions.
        continue;
      }
      console.log(current);
      char_count += current.textContent.length;
    }
    // assign!
    return char_count;
  }
  let focus = getFocusPosition();
  let getAnchorPosition = () => {
    // okay.  Now, get the anchor offset.  The anchor doesn't move, but the focus does.
    // Together, they will give me the real range within the string.
    if (selection.isCollapsed) {
      return focus; // the two are the same.
    }
    // find the node with focus.
    const anchor = selection.anchorNode;
    if (anchor === null) return -1;
    const offset = selection.anchorOffset;
    // if this is a text-node, then the awesomebar must be two levels up.
    var anchor_child;
    // case: div#awesomebar > div > text
    if (anchor.nodeType == Node.TEXT_NODE && anchor.parentNode.parentNode.id === "awesomebar") {
      anchor_child = anchor;
    // case: div #awesomebar > div > span > text
    } else if (anchor.nodeType == Node.TEXT_NODE && anchor.parentNode.parentNode.parentNode.id === "awesomebar") {
      anchor_child = anchor.parentNode;
    } else {
      console.log("ANCHOR: Where is this node?  I don't know.  See _debug_getCaretPosition_a.");
      _debug_getCaretPosition_a = anchor;
      console.log(anchor);
      return -1;
    }
    // Now get the very first child of the awesomebar, counting chars on the way.
    var char_count = offset;
    for (var current = anchor_child.previousSibling; current; current = current.previousSibling) {
      if (current.nodeType == Node.ELEMENT_NODE && current.dataset.completion !== undefined) {
        // skip over completions.
        continue;
      }
      console.log(current);
      char_count += current.textContent.length;
    }
    // assign!
    return char_count;
  };
  let anchor = getAnchorPosition();

  // give back the start and end
  if (focus === -1 || anchor === -1) {
    return null;
  }
  return { start: Math.min(focus, anchor), end: Math.max(focus, anchor) };
}

function checkCaretChange() {
  if (bar === null) {
    return;
  }
  const old = caretTracker;
  const tmp = getCaretPositions();
  if (tmp) {
    caretTracker = tmp;
    console.log(caretTracker);
    if (old != caretTracker && caretTracker.start === caretTracker.end) {
      app.ports.caretMoved.send(caretTracker);
    }
  }
}

function trackCompositionStart(e) {
  console.log("Composition started.");
  isComposing = true;
  lastInputEvent_range = caretTracker;
}

function trackCompositionEnd(e) {
  console.log("Composition ended.");
  isComposing = false;
  if (lastInputEvent === null) { // can happen if canceled
    lastInputEvent_range = null;
    return;
  }
  beforeInputListener(lastInputEvent);
  lastInputEvent = null;
  lastInputEvent_range = null;
}

function beforeInputListener(event) {
  if (event.inputType.match("^history..do")) {
    return; // don't handle this.
  }
  if (isComposing) {
    // console.log(`Got ${event.inputType} but still composing.`);
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
  // console.log(event);
  if (event.inputType === "insertReplacementText") {
    const replacement = event.dataTransfer.getData("text");
    const range = event.getTargetRanges()[0];
    // Now tell Elm about it.
    // console.log(`Input type: ${event.inputType}.  Start=${range.startOffset}, End=${range.endOffset}.`);
    let packaged =
      { inputType: event.inputType
        , data: replacement
        , start: range.startOffset
        , end: range.endOffset
      };
    console.log(packaged);
    app.ports.awesomeBarInput.send(packaged);
  } else {
    // Here I need to get the selection position as well.
    // If we're in 'beforeinput', then we can assume focus??
    // I'm not 100% sure, but I don't see how it can be false
    // (barring programmatic input), so the temptation is to go with it…
    // But hey, what can I say, I'm a safety girl!
    // bar.focus();
    [ start, end ] =
      (() => {
        if (lastInputEvent_range) {
          return [ lastInputEvent_range.start, lastInputEvent_range.end ];
        } else {
          // const range = window.getSelection().getRangeAt(0);
          // const preSelectionRange = range.cloneRange();
          // preSelectionRange.selectNodeContents(bar);
          // preSelectionRange.setEnd(range.startContainer, range.startOffset);
          // const start = preSelectionRange.toString().length;
          // const end = start + range.toString().length;
          // return [ start, end ];
          return [ caretTracker.start, caretTracker.end ];
        }
      })();
    // unless there is an ACTUAL selection, `start` and `end` should be the same.
    // Now tell Elm about it.
    // console.log(`Input type: ${event.inputType}.  Start=${start}, End=${end}.`);
    let packaged =
      { inputType: event.inputType
        , data: event.inputType === "insertFromPaste"
            ? event.dataTransfer.getData("text")
            : event.data ?? ""
        , start: start
        , end: end
      };
    console.log(packaged);
    app.ports.awesomeBarInput.send(packaged);
  }
}

// function setCaretPosition(textNode) {
//     let s = document.getSelection();
//     textRange = document.createRange();
//     textRange.setStart(textNode, caretPosition);
//     textRange.collapse(true);
//     s.removeAllRanges();
//     s.addRange(textRange);
// };

function textNodeIn(node) {
  if (node.nodeType === Node.TEXT_NODE) {
    return node;
  }
  return Array.from(node.childNodes).find(textNodeIn);
}

// Callback function to execute when mutations are observed
const observation = (mutationList, _observer) => {
  for (const mutation of mutationList) {
    const arr = Array.from(mutation.addedNodes);
    if (mutation.type === "childList" && arr.length > 0 && mutation.target.id === "awesomebar") {
      // console.log(`A child node has been added or removed within ${mutation.target.id}`);
      // console.log(mutation.removedNodes);
      // console.log(mutation.addedNodes);
      // setCaretPosition(textNodeIn(mutation.addedNodes[0]));
      setCaretPosition();
      return;
    }
  }
};

// Create an observer instance linked to the callback function
const observer = new MutationObserver(observation);

function goodbyeBar() {
  bar.removeEventListener("beforeinput", beforeInputListener);
  bar.removeEventListener("compositionstart", trackCompositionStart);
  bar.removeEventListener("compositionend", trackCompositionEnd);
  bar.removeEventListener("caret", checkCaretChange);
  observer.disconnect();
  // reset all the state-tracking variables
  textRange = null;
  bar = null;
  isComposing = false;
  caretPosition = 0;
  lastInputEvent = null;
  caretTracker = 0;
  // Tell Elm that it can now get rid of the element
  app.ports.listenerRemoved.send(null);
}

function initializeBar() {
  bar = document.getElementById("awesomebar");
  if (!bar) {
    setTimeout(initializeBar, 50);
    return;
  }
  bar.addEventListener("beforeinput", beforeInputListener);
  bar.addEventListener("compositionstart", trackCompositionStart);
  bar.addEventListener("compositionend", trackCompositionEnd);
  bar.addEventListener("caret", checkCaretChange);
  bar.focus();

  // Start observing the target node for configured mutations
  observer.observe(bar, { characterData: true, childList: true, subtree: false });
}

app.ports.displayAwesomeBar.subscribe(initializeBar);
app.ports.hideAwesomeBar.subscribe(goodbyeBar);

app.ports.shiftCaret.subscribe((p) => {
  caretPosition = p;
});