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

_debug_getCaretPosition = null;

// We have one of these cases:
// div#awesomebar > div > span > text
// OR
// div#awesomebar > div > text
function getCaretPosition() {
  const selection = window.getSelection();
  // find the node with focus.
  const focused = selection.focusNode;
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
    console.log("Where is this node?  I don't know.  See _debug_getCaretPosition.");
    _debug_getCaretPosition = focused;
    console.log(focused);
    return;
  }
  // Now get the very first child of the awesomebar, counting chars on the way.
  char_count = offset;
  for (var current = focused_child.previousSibling; current; current = current.previousSibling) {
    if (current.nodeType == Node.ELEMENT_NODE && current.dataset.completion !== undefined) {
      // skip over completions.
      continue;
    }
    console.log(current);
    char_count += current.textContent.length;
  }
  // this will be the focus.
  return char_count;
}

function checkCaretChange() {
  if (bar === null) {
    return;
  }
  const old = caretTracker;
  caretTracker = getCaretPosition();
  console.log(`Caret position: ${caretTracker}`);
  if (old != caretTracker) {
    app.ports.caretMoved.send(caretTracker);
  }
}

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
    app.ports.awesomeBarInput.send(
      {
        inputType: event.inputType
        , data: replacement
        , start: range.startOffset
        , end: range.endOffset
      });
    } else {
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
      // console.log(`Input type: ${event.inputType}.  Start=${start}, End=${end}.`);
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