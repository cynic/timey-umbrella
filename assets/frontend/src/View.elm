module View exposing (..)

import Data exposing (..)
import Html exposing (Html, div, text, span, li, ol, table, td, tr, th)
import Html.Attributes exposing (contenteditable, id, class, classList, title)
import Html.Keyed as Keyed
import Time.Extra exposing (..)
import Time exposing (..)
import List.Extra

posixToDate : Time.Zone -> Time.Posix -> Date
posixToDate zone nowish =
  Date
    (Time.toYear zone nowish)
    (Time.toMonth zone nowish)
    (Time.toDay zone nowish)
    (Time.toWeekday zone nowish)

monthToString : Time.Month -> String
monthToString month =
  case month of
    Jan -> "January"
    Feb -> "February"
    Mar -> "March"
    Apr -> "April"
    May -> "May"
    Jun -> "June"
    Jul -> "July"
    Aug -> "August"
    Sep -> "September"
    Oct -> "October"
    Nov -> "November"
    Dec -> "December"

monthToInt : Time.Month -> Int
monthToInt month =
  case month of
    Time.Jan -> 1
    Time.Feb -> 2
    Time.Mar -> 3
    Time.Apr -> 4
    Time.May -> 5
    Time.Jun -> 6
    Time.Jul -> 7
    Time.Aug -> 8
    Time.Sep -> 9
    Time.Oct -> 10
    Time.Nov -> 11
    Time.Dec -> 12

intToMonth : Int -> Time.Month
intToMonth m =
  case m of
    1 -> Time.Jan
    2 -> Time.Feb
    3 -> Time.Mar
    4 -> Time.Apr
    5 -> Time.May
    6 -> Time.Jun
    7 -> Time.Jul
    8 -> Time.Aug
    9 -> Time.Sep
    10 -> Time.Oct
    11 -> Time.Nov
    _ -> Time.Dec

classFor : Token -> String
classFor token =
  case token of
    Today -> "when"
    Tomorrow -> "when"
    Duration _ -> "duration"
    Description -> ""

tokenWithoutCompletion : String -> Token -> String -> Html Msg
tokenWithoutCompletion s token txt =
  span
    [ classList
        [ ("token-viz", token /= Description)
        , (classFor token, token /= Description)
        ]
    ]
    [ text txt ]

tokenWithCompletion : String -> Token -> String -> String -> Html Msg
tokenWithCompletion s token completion txt =
  span
    [ classList
        [ ("token-viz", token /= Description)
        , (classFor token, token /= Description)
        ]
    , Html.Attributes.attribute "data-completionlen" (String.fromInt <| String.length completion)
    ]
    [ text txt
    , span
        [ class "completion"
        , contenteditable False
        , Html.Attributes.attribute "inert" "true"
        , Html.Attributes.attribute "data-completion" completion
        ]
        [ text completion ]
    ]
  
isWithinOffset : Int -> Int -> Int -> Bool
isWithinOffset offset extent caretPosition =
  offset <= caretPosition && offset + extent >= caretPosition

tokenToView : String -> Int -> (Token, Maybe String, Offset) -> Html Msg
tokenToView s caretPosition (token, completion, {offset, extent}) =
  let
    txt = String.slice offset (offset+extent) s
  in
    case (completion, caretPosition |> isWithinOffset offset extent) of
      (Nothing, _) ->
        tokenWithoutCompletion s token txt
      (_, False) ->
        tokenWithoutCompletion s token txt
      (Just completion_, True) ->
        tokenWithCompletion s token completion_ txt

viewTodoList : Model -> Html Msg
viewTodoList model =
  ol
    []    
    ( List.map
      (\{ s, created, duration } ->
        li
          [ class "todo" ]
          [ span
              [ class "todo-text" ]
              [ text s ]
          , span
              [ class "todo-created" ]
              [ text <| "Created " ++ String.fromInt created.year ++ "-" ++ monthToString created.month ++ "-" ++ String.fromInt created.day ]
          , case duration of
              Nothing ->
                text ""
              Just duration_ ->
                span
                  [ class "duration" ]
                  [ case duration_ of
                      Minutes m ->
                        if m == 1 then
                          text "1 minute"
                        else if m < 60 then
                          text <| String.fromInt m ++ " minutes"
                        else
                          let
                            h = modBy 60 m
                            min = m - h * 60
                          in
                            if min == 0 then
                              text <| String.fromInt h ++ "h"
                            else
                              text <| String.fromInt h ++ "h" ++ String.fromInt min ++ "m"
                      Hours h 0 ->
                        text <| String.fromInt h ++ "h"
                      Hours h m ->
                        text <| String.fromInt h ++ "h" ++ String.fromInt m ++ "m"
                  ]
          ]
      )
      model.data
    )

decrementDay : Date -> Date
decrementDay date =
  partsToPosix Time.utc (Parts date.year date.month date.day 0 0 0 0)
  |> (\posix -> millisToPosix (posixToMillis posix - 86300000)) -- a bit less than 1 day, but that's fine.
  |> posixToDate Time.utc

incrementDay : Date -> Date
incrementDay date =
  partsToPosix Time.utc (Parts date.year date.month date.day 0 0 0 0)
  |> (\posix -> millisToPosix (posixToMillis posix + 86500000)) -- a bit more than 1 day, but that's fine.
  |> posixToDate Time.utc

addWeeks : Int -> Date -> Date
addWeeks weeks date =
  partsToPosix Time.utc (Parts date.year date.month date.day 0 0 0 0)
  |> (\posix -> millisToPosix (posixToMillis posix + (weeks * 7 * 86400000) + 100000)) -- a bit more than 1 week, but that's fine.
  |> posixToDate Time.utc

getSaturday : Date -> Date
getSaturday date =
  if date.weekday == Sat then
    date
  else
    getSaturday (decrementDay date)

isWeekend : Date -> Bool
isWeekend date =
  date.weekday == Sat || date.weekday == Sun

isWeekday : Date -> Bool
isWeekday date =
  not (isWeekend date)

cmpDate : Date -> Date -> Order
cmpDate date1 date2 =
  let
    posix1 =
      partsToPosix Time.utc (Parts date1.year date1.month date1.day 0 0 0 0)
      |> Time.posixToMillis
    posix2 =
      partsToPosix Time.utc (Parts date2.year date2.month date2.day 0 0 0 0)
      |> Time.posixToMillis
  in
    compare posix1 posix2

viewCalendar : (Date -> Bool) -> Date -> Int -> Html Msg
viewCalendar highlight today numWeeks =
  -- find the closest Saturday.  This is when my week starts 😂… 'cos, yeah, I said so!
  let
    saturday =
      getSaturday today
  in
    Html.table
      [ class "calendar" ]
      (( Html.tr
        [ class "calendar-week" ]
        ( ["S", "S", "M", "T", "W", "T", "F"]
          |> List.map (\dayname ->
            Html.th [ class "calendar-dayname" ] [ text dayname ]
          )
        )
      ) ::
      ( List.range 0 (numWeeks - 1)
      |> List.map (\weekNo ->
          Html.tr
            [ class "calendar-week" ]
            ( List.range 1 6 -- not 1 7, because the initial is given
              |> List.Extra.scanl (\_ state -> incrementDay state) (addWeeks weekNo saturday)
              |> List.map (\day ->
                let
                  cmp = cmpDate day today
                in
                  Html.td
                    [ class "calendar-day"
                    , classList
                        [ ("today", cmp == EQ)
                        , ("past", cmp == LT)
                        --, ("future", cmp == GT)
                        , ("month-start", day.day == 1)
                        , ("weekend", day.weekday == Sat || day.weekday == Sun)
                        , ("highlight", highlight day)
                        ]
                    , if day.day == 1 then
                        title <| monthToString day.month
                      else
                        class "" -- ignored.
                    ]
                    [ text <| String.fromInt day.day ]
              )
            )
      ))
    )

viewAwesomeBar : Model -> AwesomeBarState -> Html Msg
viewAwesomeBar model state =
  div
    []
    [ Keyed.node "div"
        [ id "awesomebar-container"
        ]
        [ ("title", div
          [ id "awesomebar-title" ]
          [ text "Task" ])
        -- this next bit is keyed to a constant just to stop Elm from recreating the element.
        -- If Elm DOES recreate the element, the events associated with it externally… disappear!
        , ("bar", div
            [ contenteditable True
            , id "awesomebar"
            ]
            ( let
                last = List.drop (List.length state.parse - 1) state.parse |> List.head
                first = List.head state.parse
                prefix =
                  Maybe.map (\(_, _, { offset }) ->
                    text <| String.repeat offset " "
                  ) first
                suffix =
                  Maybe.map (\(_, _, { offset, extent }) ->
                    text <| String.repeat (String.length state.s - (offset + extent)) " "
                  ) last
                tokenHtml =
                  List.map (tokenToView state.s state.i) state.parse
              in
                case (prefix, suffix) of
                  (Nothing, Nothing) ->
                    tokenHtml
                  (Just prefixHtml, Nothing) ->
                    prefixHtml :: tokenHtml
                  (Nothing, Just suffixHtml) ->
                    tokenHtml ++ [suffixHtml]
                  (Just prefixHtml, Just suffixHtml) ->
                    (prefixHtml :: tokenHtml) ++ [suffixHtml]
            )
          )
        ]
    ]
