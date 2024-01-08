module Main exposing (..)

import Browser
import Html exposing (Html, div, text, span)
import Browser.Navigation as Navigation
import Url exposing (Url)
import Time exposing (Posix)
import Browser.Events
import Json.Decode as D
import Html.Attributes exposing (contenteditable, id, class)
import Browser.Dom as Dom
import Task
import Html.Events exposing (on, preventDefaultOn)
import Platform.Cmd as Cmd
import String.Extra as String
import Ports
import Html.Keyed as Keyed

-- MODEL

type alias Date =
  { year : Int
  , month : Int
  , day : Int
  }

type alias RoughInterval =
  (Int, Int) -- e.g. roughly every 5-8 days/minutes/etc

type Pause
  = Indefinitely { since : Date }
  | Approximately RoughInterval -- measured in days

type TimeExpenditure
  -- just unknown
  = Undefined
  | About RoughInterval -- measured in minutes/hours depending on suffix

type DeadlineTypes
  -- this is the deadline by which the thing MUST be done.  Usually set by other people…
  = HardDeadline Date
  -- now, this is a "deadline" by which I kind of want to have it done, and there's a hard deadline too by which it MUST be done
  | SoftDeadline Date Date
  -- I want to have done some of this done just to keep some form of forward-progress, but when it's actually done is unknown.  Maybe never?
  | ForwardProgress 

type Status
  = Active
  | Completed Posix
  | Paused { previously : Status, now : Status }
  | BallPlayed { checkAfter : RoughInterval } -- in days

type alias Todo =
  { created : Date
  , text : String
  , status : Status
  , spawnContext : Maybe String -- can be an event, a person, a todo
  }

type CoreDatum
  = Start

type alias CoreDatumModel =
  { 
  }

-- AwesomeBar start
type alias StringData = String

type Token
  = Today StringData
  | Tomorrow StringData
  | Description StringData
  | Whitespace Int -- number of whitespace characters
  | AcceptLiterally
  | Cursor
  | CursorIn Token Int -- offset from the beginning of the literal string
  -- | AfterDays Int
  -- | AfterWeeks Int

type alias AwesomeBarToken = Token

type alias Offset =
  { offset : Int
  , extent : Int
  }

type alias AwesomeBarState =
  { s : String
  , i : Int -- caret position
  , tokenised : List Offset
  , parse : List AwesomeBarToken
  }
-- AwesomeBar end

type Mode
  = Waiting
  | AwesomeBar AwesomeBarState

type ABSpecialKey
  = Escape
  | Tab
  | Enter

type ABMsg
  = SetString String Int
  | ListenerRemoved
  | Key ABSpecialKey

type Msg
  = NoOp
  | SwitchMode Mode
  | AB ABMsg

type alias Model =
  { key : Navigation.Key
  , mode : Mode
  }


init : () -> Url -> Navigation.Key -> (Model, Cmd Msg)
init _ _ key =
  ( { key = key
  , mode = Waiting
  }
  , Cmd.none
  )

-- type alias ParserState =
--   { offsetCount : Int
--   , currentParse : List Token
--   }

-- startingParserState : ParserState
-- startingParserState =
--   { offsetCount = 0
--   , currentParse = []
--   }

-- -- parseIntoTokens : (Int, List String) -> ParserState -> List Token
-- -- parseIntoTokens (caret, list) state =
-- --   {- the cursor might be anywhere in the list, including right at the start or
-- --      right at the end.  In the parser state, I track the `offsetCount`, which is
-- --      the number of characters that I've encountered thus far.

-- --      If the offsetCount is
-- --   -}
-- --   case list of
-- --     [] ->
-- --       state.currentParse
-- --     ""::restOfList ->
-- --       {- The only way I'll see an empty string is if I have two consecutive spaces.
-- --          So if I have a whitespace as my most recent parse, extend it; otherwise,
-- --          put in a whitespace token with 2 consecutive spaces.
-- --       -}
-- --       case state.currentParse of
-- --         Whitespace n::restOfParse ->
-- --           parseIntoTokens caret restOfList
-- --             { state
-- --             | currentParse = Whitespace (n + 1)::restOfParse
-- --             , offsetCount = state.offsetCount + 1
-- --             }
-- --         other ->
-- --           parseIntoTokens caret restOfList
-- --             { state
-- --             | currentParse = Whitespace 2::other
-- --             , offsetCount = state.offsetCount + 2
-- --             }
-- --     _ ->
-- --       {- Chances are that this is a normal word (or phrase), but it may be keyword(s)
-- --          with some special meaning.  So, let's see what we can find, longest
-- --          chain-of-meaning being prioritised over a smaller one, and taking the
-- --          current parse into account.
-- --       -}
-- --       if 
-- --     [] ->
-- --       state.currentParse

tokenise : String -> Int -> Maybe Offset -> List Offset -> List Offset
tokenise s i current acc =
  case (String.slice i (i+1) s, current) of
    -- end-of-input cases
    ("", Nothing) ->
      List.reverse acc
    ("", Just c) ->
      List.reverse (c :: acc)
    -- whitespace cases
    (" ", Nothing) ->
      tokenise s (i+1) Nothing acc
    (" ", Just c) ->
      tokenise s (i+1) Nothing (c :: acc)
    (_, Nothing) ->
      tokenise s (i+1) (Just { offset = i, extent = 1 }) acc
    (_, Just c) ->
      tokenise s (i+1) (Just { c | extent = c.extent + 1 }) acc

-- UPDATE
update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
  NoOp ->
    (model, Cmd.none)
  SwitchMode (AwesomeBar x) ->
    ({ model | mode = AwesomeBar x }, Ports.displayAwesomeBar ())
  SwitchMode Waiting ->
    ({ model | mode = Waiting }, Cmd.none)
  AB abmsg ->
    case model.mode of
      AwesomeBar x ->
        case abmsg of
          ListenerRemoved ->
            ({ model | mode = Waiting }, Cmd.none)
          Key Escape ->
            (model, Ports.hideAwesomeBar ())
          Key Tab ->
            (model, Cmd.none)
          Key Enter ->
            (model, Cmd.none)
          SetString s i ->
            ({ model | mode = AwesomeBar { x | s = s, i = i, tokenised = tokenise s 0 Nothing [] } }
            , Ports.shiftCaret i
            )
      Waiting ->
        (model, Cmd.none)

-- VIEW


view : Model -> Browser.Document Msg
view model =
  { title = "Hello, Elm!"
  , body =
    [ div []
      [ text "Hello, Elm!" ]
    , case model.mode of
      Waiting ->
        div [] [ text "Waiting…" ]
      AwesomeBar state ->
        div
          []
          [ Keyed.node "div"
              [ id "awesomebar-container" ]
              [ ("title", div
                [ id "awesomebar-title" ]
                [ text "Task" ])
              , ("bar", Keyed.node "div"
                [ contenteditable True
                , id "awesomebar"
                ]
                [ ( state.s
                  , div
                      []
                      [ text <| {-Debug.log "Generating TEXT node"-} state.s
                      , span
                          [ class "completion"
                          , contenteditable False
                          ]
                          [ text "orrow" ]
                      ])
                ])
              ]
          , div
            []
            ( List.map
                (\{offset, extent} ->
                  span
                    [ class "token-viz" ]
                    [ text <| String.fromInt offset
                    , text "-"
                    , text <| String.fromInt (offset + extent)
                    , text " "
                    , text "“"
                    , text <| String.slice offset (offset+extent) state.s
                    , text "”"
                    ]
                )
                state.tokenised
            )
          ]
    ]
  }


-- SUBSCRIPTIONS

type EventInputType
  = InsertText Int -- offset position of caret
  | DeleteBackwards
  | DeleteForwards
  | Disallow

classifyInput : String -> String -> EventInputType
classifyInput inputType data =
  case {-Debug.log "inputType"-} inputType of
    "insertText" ->
      InsertText (String.length data)
    "insertReplacementText" ->
      InsertText (String.length data)
    "insertFromPaste" ->
      InsertText (String.length data)
    "deleteByCut" ->
      DeleteBackwards
    "deleteContent" ->
      DeleteBackwards
    "deleteContentBackward" ->
      DeleteBackwards
    "deleteContentForward" ->
      DeleteForwards
    "insertCompositionText" ->
      InsertText 0
    -- "insertLineBreak" ->
    --   Disallow
    -- "insertParagraph" ->
    --   Disallow
    -- "insertOrderedList" ->
    --   Disallow
    -- "insertUnorderedList" ->
    --   Disallow
    -- "insertHorizontalRule" ->
    --   Disallow
    -- "insertFromYank" ->
    --   Disallow
    -- "insertFromDrop" ->
    --   Disallow
    -- "insertFromPasteAsQuotation" ->
    --   Disallow
    -- "insertTranspose" ->
    --   Disallow
    -- "insertLink" ->
    --   Disallow
    -- "deleteWordBackward" ->
    --   Disallow
    -- "deleteWordForward" ->
    --   Disallow
    -- "deleteSoftLineBackward" ->
    --   Disallow
    -- "deleteSoftLineForward" ->
    --   Disallow
    -- "deleteEntireSoftLine" ->
    --   Disallow
    -- "deleteHardLineBackward" ->
    --   Disallow
    -- "deleteHardLineForward" ->
    --   Disallow
    -- "deleteByDrag" ->
    --   Disallow
    -- "historyUndo" ->
    --   Disallow
    -- "historyRedo" ->
    --   Disallow
    -- "formatBold" ->
    --   Disallow
    -- "formatItalic" ->
    --   Disallow
    -- "formatUnderline" ->
    --   Disallow
    -- "formatStrikeThrough" ->
    --   Disallow
    -- "formatSuperscript" ->
    --   Disallow
    -- "formatSubscript" ->
    --   Disallow
    -- "formatJustifyFull" ->
    --   Disallow
    -- "formatJustifyCenter" ->
    --   Disallow
    -- "formatJustifyRight" ->
    --   Disallow
    -- "formatJustifyLeft" ->
    --   Disallow
    -- "formatIndent" ->
    --   Disallow
    -- "formatOutdent" ->
    --   Disallow
    -- "formatRemove" ->
    --   Disallow
    -- "formatSetBlockTextDirection" ->
    --   Disallow
    -- "formatSetInlineTextDirection" ->
    --   Disallow
    -- "formatBackColor" ->
    --   Disallow
    -- "formatFontColor" ->
    --   Disallow
    -- "formatFontName" ->
    --   Disallow
    x -> -- this should never happen.
      Debug.log "Unhandled inputType seen" x
      |> \_ -> Disallow

decodeInput : Model -> AwesomeBarState -> D.Decoder Msg
decodeInput model state =
  D.map4
    (\inputType data start end ->
      case classifyInput inputType data of
        Disallow ->
          NoOp
        InsertText added ->
          let
            -- added = {-Debug.log "Chars added" <|-} String.length data
            left = {-Debug.log "Prefix" <|-} String.left start state.s
            right = {-Debug.log "Suffix" <|-} String.dropLeft end state.s
          in
            AB (SetString (left ++ data ++ right) (start + added))
        DeleteBackwards ->
          if start == 0 && end == start then
            NoOp
          else if start == end then
            AB (SetString (String.left (start - 1) state.s ++ String.dropLeft end state.s) (start - 1))
          else
            AB (SetString (String.left start state.s ++ String.dropLeft end state.s) start)
        DeleteForwards ->
          if start == end then
            AB (SetString (String.left start state.s ++ String.dropLeft (end + 1) state.s) start)
          else
            AB (SetString (String.left start state.s ++ String.dropLeft end state.s) start)
    )
    (D.field "inputType" D.string)
    (D.field "data" D.string)
    (D.field "start" D.int)
    (D.field "end" D.int)
  -- D.field 
  -- |> D.map
  --   (\input ->
  --     (AB (SetString input), True)
  --   )

decodeSpecialKey : String -> Msg
decodeSpecialKey key =
  case key of
    "Escape" ->
      AB <| Key Escape
    "Tab" ->
      AB <| Key Tab
    "Enter" ->
      AB <| Key Enter
    _ ->
      NoOp

subscriptions : Model -> Sub Msg
subscriptions model =
  case model.mode of
    Waiting ->
      Browser.Events.onKeyDown
        ( D.field "key" D.string
        |> D.map
          (\key ->
          if key == " " then SwitchMode (AwesomeBar { s = "", i = 0, parse = [Cursor], tokenised = [] })
          else NoOp
          )
        )
    AwesomeBar state ->
      Sub.batch
        [ Ports.awesomeBarInput (D.decodeValue (decodeInput model state) >> Result.withDefault NoOp)
        , Ports.listenerRemoved (\_ -> AB ListenerRemoved)
        , Ports.sendSpecial decodeSpecialKey
        ]

-- PROGRAM


main : Program () Model Msg
main =
  Browser.application
  { init = init
  , update = update
  , view = view
  , subscriptions = subscriptions
  , onUrlRequest = \_ -> NoOp
  , onUrlChange = \_ -> NoOp
  }
