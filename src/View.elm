module View exposing (..)

import Data exposing (..)
import Html exposing (Html, div, text, span, li, ol)
import Html.Attributes exposing (contenteditable, id, class, classList)
import Html.Keyed as Keyed

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
              [ text <| "Created " ++ String.fromInt created.year ++ "-" ++ String.fromInt created.month ++ "-" ++ String.fromInt created.day ]
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
