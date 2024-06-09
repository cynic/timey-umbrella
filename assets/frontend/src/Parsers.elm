module Parsers exposing (..)

import Data exposing (..)
import Parser exposing (Parser, (|.), (|=))
import Parser


-- The Parser.int function only parses integers that AREN'T suffixed with non-whitespace.
-- Well, that's pretty useless to me!
-- So, here's an actual intParser that is useful.
intParser : (Maybe Int, Maybe Int) -> Parser Int
intParser (min, max) =
  Parser.getOffset
  |> Parser.andThen (\ofs0 ->
    Parser.chompWhile (Char.isDigit)
    |> Parser.getChompedString
    |> Parser.andThen (\value ->
      Parser.getOffset
      |> Parser.andThen (\ofs1 ->
        if ofs1 > ofs0 then
          String.toInt value
          |> Maybe.map (\v ->
            case (min, max) of
              (Just min_, Just max_) ->
                if v >= min_ && v <= max_ then
                  Parser.succeed v
                else
                  Parser.problem ("Expected an integer between " ++ String.fromInt min_ ++ " and " ++ String.fromInt max_ ++ ", inclusive; got " ++ value)
              (Just min_, Nothing) ->
                if v >= min_ then
                  Parser.succeed v
                else
                  Parser.problem ("Expected an integer greater than or equal to " ++ String.fromInt min_ ++ "; got " ++ value)
              (Nothing, Just max_) ->
                if v <= max_ then
                  Parser.succeed v
                else
                  Parser.problem ("Expected an integer less than or equal to " ++ String.fromInt max_ ++ "; got " ++ value)
              (Nothing, Nothing) ->
                Parser.succeed v
          )
          |> Maybe.withDefault (Parser.problem ("Expected an integer, got " ++ value))
        else
          Parser.problem ("Expected an integer, but got a blank")
      )
    )
  )

x_dot_y_hParser : Int -> Parser (Duration, Maybe String)
x_dot_y_hParser initial =
  -- syntax: 2.5h , 2.25h, 2.75h
  Parser.succeed identity
  |. Parser.symbol "."
  |= Parser.oneOf
    [ Parser.succeed 30 |. Parser.symbol "5"
    , Parser.succeed 15 |. Parser.symbol "25"
    , Parser.succeed 45 |. Parser.symbol "75"
    ]
  |> Parser.andThen (\final ->
    Parser.oneOf
      [ Parser.succeed (Hours initial final, Just "h")
        |. Parser.end
      , Parser.succeed (Hours initial final, Nothing)
        |. Parser.symbol "h"
        |. Parser.end
      ]
  )

x_fraction_hParser : Int -> Parser (Duration, Maybe String)
x_fraction_hParser initial =
  -- syntax: 2.5h , 2.25h, 2.75h
  Parser.succeed identity
  |= Parser.oneOf
    [ Parser.succeed 30 |. Parser.symbol "½"
    , Parser.succeed 15 |. Parser.symbol "¼"
    , Parser.succeed 20 |. Parser.symbol "⅓"
    , Parser.succeed 40 |. Parser.symbol "⅔"
    , Parser.succeed 45 |. Parser.symbol "¾"
    ]
  |> Parser.andThen (\final ->
    Parser.oneOf
      [ Parser.succeed (Hours initial final, Just "h")
        |. Parser.end
      , Parser.succeed (Hours initial final, Nothing)
        |. Parser.symbol "h"
        |. Parser.end
      ]
  )

x_hmParser : Int -> Parser (Duration, Maybe String)
x_hmParser initial =
  -- syntax: 18m, 1h, etc
  -- syntax: 2h30m 2h10m, etc
  Parser.succeed identity
  |= Parser.oneOf
    [ Parser.end
      |> Parser.andThen (\_ ->
        if initial >= 5 then
          Parser.succeed (Minutes initial, Just "m")
        else
          Parser.succeed (Hours initial 0, Just "h")
      )
    , Parser.succeed (Minutes initial, Nothing) |. Parser.symbol "m" |. Parser.end
    , Parser.succeed (\(final, completion) -> (Hours initial final, completion))
      |. Parser.symbol "h"
      |= Parser.oneOf
        [ Parser.succeed (0, Nothing) |. Parser.end

        , Parser.succeed (5,  Nothing) |. Parser.symbol "5m"  |. Parser.end
        , Parser.succeed (5,  Nothing) |. Parser.symbol "05m" |. Parser.end
        , Parser.succeed (10, Nothing) |. Parser.symbol "10m" |. Parser.end
        , Parser.succeed (15, Nothing) |. Parser.symbol "15m" |. Parser.end
        , Parser.succeed (20, Nothing) |. Parser.symbol "20m" |. Parser.end
        , Parser.succeed (25, Nothing) |. Parser.symbol "25m" |. Parser.end
        , Parser.succeed (30, Nothing) |. Parser.symbol "30m" |. Parser.end
        , Parser.succeed (35, Nothing) |. Parser.symbol "35m" |. Parser.end
        , Parser.succeed (40, Nothing) |. Parser.symbol "40m" |. Parser.end
        , Parser.succeed (45, Nothing) |. Parser.symbol "45m" |. Parser.end
        , Parser.succeed (50, Nothing) |. Parser.symbol "50m" |. Parser.end
        , Parser.succeed (55, Nothing) |. Parser.symbol "55m" |. Parser.end

        , Parser.succeed (5, Just "m") |. Parser.symbol "5" |. Parser.end
        , Parser.succeed (5, Just "m") |. Parser.symbol "05" |. Parser.end
        , Parser.succeed (10, Just "m") |. Parser.symbol "10" |. Parser.end
        , Parser.succeed (15, Just "m") |. Parser.symbol "15" |. Parser.end
        , Parser.succeed (20, Just "m") |. Parser.symbol "20" |. Parser.end
        , Parser.succeed (25, Just "m") |. Parser.symbol "25" |. Parser.end
        , Parser.succeed (30, Just "m") |. Parser.symbol "30" |. Parser.end
        , Parser.succeed (35, Just "m") |. Parser.symbol "35" |. Parser.end
        , Parser.succeed (40, Just "m") |. Parser.symbol "40" |. Parser.end
        , Parser.succeed (45, Just "m") |. Parser.symbol "45" |. Parser.end
        , Parser.succeed (50, Just "m") |. Parser.symbol "50" |. Parser.end
        , Parser.succeed (55, Just "m") |. Parser.symbol "55" |. Parser.end
        ]
    ]

shortDurationParser : Parser (Token, Maybe String)
shortDurationParser =
  Parser.succeed identity
  |. Parser.symbol "~"
  |= intParser (Just 1, Just 120)
  |> Parser.andThen (\initial ->
    Parser.oneOf
      [ x_hmParser initial
      , x_fraction_hParser initial
      , x_dot_y_hParser initial
      ]
  )
  |> Parser.map (\(t, c) -> (Duration t, c))
