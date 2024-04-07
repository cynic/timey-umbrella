module View exposing (..)

import Data exposing (..)
import Html exposing (Html, div, text, span, li, ol, button)
import Html.Attributes exposing (contenteditable, id, class, classList, title)
import Html.Events exposing (onClick)
import Html.Keyed as Keyed
import Time.Extra exposing (..)
import Time exposing (..)
import List.Extra
import Utility exposing (..)

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

viewDuration : SmallDuration -> Html Msg
viewDuration duration =
  span
    [ class "duration" ]
    [ case duration of
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

viewChecklist : Model -> Html Msg
viewChecklist model =
  ol
    [ class "checklist" ]    
    ( List.sortBy (\{id} -> id) model.checklisten
    |> List.map
      (\{ s, created, id } ->
        li
          [ class "checklist-item" ]
          [ button
              [ onClick <| DeleteChecklistItem id
              , class "skeu-convex capsule-left"
              ]
              [ text "✖️" ]
          , span
              [ class "description skeu-convex"
              , title s
              ]
              [ text s ]
          -- , span
          --     [ class "created" ]
          --     [ text <| "Created " ++ String.fromInt created.year ++ "-" ++ monthToString created.month ++ "-" ++ String.fromInt created.day ]
          , button
              [ onClick <| DeleteChecklistItem id
              , class "skeu-convex"
              ]
              [ text "✔️" ]
          , button
              [ onClick <| DeleteChecklistItem id
              , class "skeu-convex capsule-right"
              ]
              [ text "🗑" ]
          ]
      )
    )

viewCalendar : (Date -> Bool) -> Date -> Int -> Html Msg
viewCalendar highlight today numWeeks =
  -- find the closest Saturday.  This is when my week starts 😂… 'cos, yeah, I said so!
  let
    saturday =
      getSaturday today
    holidays = publicHolidays today.year
    getPublicHoliday date =
      holidays
      |> List.Extra.find (\(dt, _) -> cmpDate dt date == EQ)
      |> Maybe.map (\(_, name) -> name)
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
                  holiday = getPublicHoliday day
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
                        , ("public-holiday", holiday /= Nothing)
                        ]
                    , case holiday of
                        Just name ->
                          title (String.fromInt day.day ++ " " ++ monthToString day.month ++ ", " ++ name)
                        Nothing ->
                          title (String.fromInt day.day ++ " " ++ monthToString day.month)
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
