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
caretTracker = { start: 0, end: 0 }; // this is SEPARATE from caretPosition.
// 👆 this is used to tell Elm what JS sees as the caret position.
// However, after updating the caret position manually, the caretTracker will be
// updated as well to the manually-set value.

let app = Elm.Main.init({
  node: document.getElementById('myapp'),
  flags: null
});

const caretChangingKeys = new Set([
  "ArrowLeft", "ArrowRight", "ArrowUp", "ArrowDown", "Home", "End"
]);
document.addEventListener("keyup", (e) => {
  // When insertions, deletions, pastes, composition, etc happens,
  // I can rely on Elm to give back the correct caret position, so all is well.
  // However, when the user moves the caret around with specific keys,
  // I need to inform Elm about that.
  if (caretChangingKeys.has(e.key)) {
    e.stopPropagation();
    // console.log(`Keyup: will now check cursor position, ${e.key} pressed.`);
    checkCaretChange();
  }
});
document.addEventListener("mouseup", (e) => {
  if (document.activeElement.id !== "awesomebar") {
    return true;
  }
  e.stopPropagation();
  checkCaretChange();
});
document.addEventListener("selectionchange", (e) => {
  if (document.activeElement.id !== "awesomebar") {
    return true;
  }
  // console.log(`Selection change: will now check cursor position, '${bar.textContent}'`);
  checkCaretChange();
});

function userTextLength() {
  var char_count = 0;
  for (var current = bar.firstChild; current; current = current.nextSibling) {
    // console.log(current);
    char_count += current.textContent.length;
    if (current.nodeType === Node.ELEMENT_NODE && current.dataset.completionlen !== undefined) {
      char_count -= parseInt(current.dataset.completionlen);
    }
  }
  return char_count;
}

function countForwardsTo(char_count) {
  for (var current = bar.firstChild; current; current = current.nextSibling) {
    // console.log(current);
    var len = current.textContent.length;
    if (current.nodeType === Node.ELEMENT_NODE && current.dataset.completionlen !== undefined) {
      len -= parseInt(current.dataset.completionlen);
    }
    if (char_count - len <= 0) {
      return { node: current, offset: char_count };
    }
    char_count -= len;
  }
  return char_count;
}

function setCaretPosition() {
  //console.log(`Setting caret position to ${caretPosition}`);
  let s = document.getSelection();
  let { node, offset } = countForwardsTo(caretPosition);
  let r = document.createRange();
  r.setStart(textNodeIn(node), offset);
  s.removeAllRanges();
  s.addRange(r);
  s.collapseToStart();
  // caretTracker = { start: caretPosition, end: caretPosition };
}

function countBackwardsFrom(node, char_count) {
  for (var current = node; current; current = current.previousSibling) {
    // console.log(current);
    char_count += current.textContent.length;
    if (current.nodeType === Node.ELEMENT_NODE && current.dataset.completionlen !== undefined) {
      char_count -= parseInt(current.dataset.completionlen);
    }
  }
  return char_count;
}

function countNodesForwards(node, count) {
  var char_count = 0;
  for (var i = 0, current = node.firstChild; i < count && current; i++, current = current.nextSibling) {
    char_count += current.textContent.length;
    if (current.nodeType === Node.ELEMENT_NODE && current.dataset.completionlen !== undefined) {
      char_count -= parseInt(current.dataset.completionlen);
    }
  }
  return char_count;
}

function getCaretPosition(selection, getNode, getOffset) {
  // right!
  // Now, the focusNode can be a few things:
  // 1. A text node
  // 2. A span node
  // 3. The awesomebar itself
  // 4. The awesomebar-container
  // We'll handle each of these cases in turn.
  let node = getNode(selection);
  let offset = getOffset(selection);
  if (node.nodeType === Node.TEXT_NODE) {
    // Two cases here:
    // 1. It might be a text-node within a <span>
    // 2. It might be a text-node within the awesomebar itself
    if (node.parentNode.tagName === "SPAN") {
      // Case 1: Get the parent of this, and work backwards from it.
      return countBackwardsFrom(node.parentNode.previousSibling, offset);
    } else {
      // Case 2: Work backwards from previous nodes within the awesomebar.
      return countBackwardsFrom(node.previousSibling, offset);
    }
  }
  if (node.nodeType === Node.ELEMENT_NODE && node.tagName === "SPAN") {
    return countBackwardsFrom(node.previousSibling, 0);
  }
  // for cases #3 & #4, count `offset` nodes forward.
  if (node.id === "awesomebar") {
    return countNodesForwards(bar, offset);
  }
  console.log(`ERROR in getCaretPosition?? I don't know what to do with this node👇`);
  console.log(node);
  return null;
  //return countBackwardsFrom(bar.lastChild ? bar.lastChild.previousSibling : null, 0);
}
// We have one of these cases:
// div#awesomebar span > text
// OR
// div#awesomebar > text
function getCaretPositions() {
  // console.log(`Updating caret position, '${bar.textContent}'`);
  if (document.activeElement.id !== "awesomebar") {
    console.log("Active element is NOT the awesomebar, it is 👇");
    console.log(document.activeElement);
    return null;
  }
  let selection = window.getSelection();
  if (selection.isCollapsed) {
    let v = getCaretPosition(selection, (sel) => sel.focusNode, (sel) => sel.focusOffset);
    return { start: v, end: v };
  }
  let a = getCaretPosition(selection, (sel) => sel.anchorNode, (sel) => sel.anchorOffset);
  let b = getCaretPosition(selection, (sel) => sel.focusNode, (sel) => sel.focusOffset);
  return { start: Math.min(a, b), end: Math.max(a, b) };
}

function checkCaretChange() {
  if (bar === null) {
    return;
  }
  const old = caretTracker;
  const tmp = getCaretPositions();
  if (tmp) {
    caretTracker = tmp;
    // console.log(caretTracker);
    if (old != caretTracker && caretTracker.start === caretTracker.end) {
      app.ports.caretMoved.send(caretTracker);
    }
  }
}

function trackCompositionStart(e) {
  // console.log("Composition started.");
  isComposing = true;
  lastInputEvent_range = caretTracker;
}

function trackCompositionEnd(e) {
  // console.log("Composition ended.");
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
  event.stopPropagation();
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
    // console.log(packaged);
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
    // console.log(packaged);
    app.ports.awesomeBarInput.send(packaged);
  }
}

function textNodeIn(node) {
  if (node.nodeType === Node.TEXT_NODE) {
    // console.log(`Returning node ${node} with nodeType ${node.nodeType}, wanted ${Node.TEXT_NODE}`);
    return node;
  }
  var stack = [node];
  while (stack.length > 0) {
    // console.log(stack);
    var current = stack.pop();
    for (var i = 0; i < current.childNodes.length; i++) {
      if (current.childNodes[i].nodeType === Node.TEXT_NODE) {
        // console.log(`Returning node ${current.childNodes[i]} with nodeType ${current.childNodes[i].nodeType} (wanted ${Node.TEXT_NODE})`);
        return current.childNodes[i];
      } else {
        stack.push(current.childNodes[i]);
      }
    }
  }
  console.log("textNodeIn(…): Nothing, null'ing out.");
  return null;
}

// Callback function to execute when mutations are observed
const observation = (mutationList, _observer) => {
  for (const mutation of mutationList) {
    //console.log(mutation);
    const arr = Array.from(mutation.addedNodes);
    if (mutation.type === "childList" && arr.length > 0 && mutation.target.id === "awesomebar") {
      // console.log(`A child node has been added or removed within ${mutation.target.id}`);
      // console.log(mutation.removedNodes);
      // console.log(mutation.addedNodes);
      // setCaretPosition(textNodeIn(mutation.addedNodes[0]));
      setCaretPosition();
      return;
    }
    if (mutation.type == "characterData") {
      // console.log(`Character data has changed within ${mutation.target.parentNode.tagName} ${mutation.target.parentNode.id}, now '${mutation.target.textContent}'`);
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
  observer.disconnect();
  // reset all the state-tracking variables
  textRange = null;
  bar = null;
  isComposing = false;
  caretPosition = 0;
  lastInputEvent = null;
  caretTracker = { start: 0, end: 0 };
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
  bar.focus();

  // Start observing the target node for configured mutations
  observer.observe(bar, { characterData: true, childList: true, subtree: true });
}

app.ports.displayAwesomeBar.subscribe(initializeBar);
app.ports.hideAwesomeBar.subscribe(goodbyeBar);

app.ports.shiftCaret.subscribe((p) => {
  // console.log(`Shift-caret(${p}) message received, text content is '${bar.textContent}'`);
  caretPosition = p;
  caretTracker = { start: caretPosition, end: caretPosition };
  if (userTextLength() >= p) {
    // go ahead & invoke now.
    setCaretPosition();
  }
});