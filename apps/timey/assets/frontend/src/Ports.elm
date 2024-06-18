port module Ports exposing (..)
import Json.Encode as E

-- Tell JS to add the event listener.
port displayAwesomeBar : () -> Cmd msg
-- Tell JS to remove the event listener.
port hideAwesomeBar : () -> Cmd msg
-- Tell JS to move the caret to the correct position.
port shiftCaret : Int -> Cmd msg
-- Tell JS that there is no action to take; next input can be processed.
port noActionPerformed : () -> Cmd msg

-- Tell Elm that there's awesomebar input.
port awesomeBarInput : (E.Value -> msg) -> Sub msg
-- Tell Elm that the listener is removed, so the element can go too.
port listenerRemoved : (() -> msg) -> Sub msg
-- Tell Elm that the "Escape" key has been pressed.alias
port sendSpecial : (String -> msg) -> Sub msg
-- Tell Elm that the cursor has moved
port caretMoved : (E.Value -> msg) -> Sub msg