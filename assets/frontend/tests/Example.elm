module Example exposing (..)

import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import Test exposing (..)
import Main exposing (tokenise, parse)
import View exposing (isWithinOffset)
import Data exposing (..)

tokenise_tests : Test
tokenise_tests =
  describe "The tokenise function"
    [ describe "when given an empty string"
      [ test "returns an empty list" <|
        \_ ->
          Expect.equal [] (tokenise "")
      ]
    , describe "when given a string with no spaces"
      [ test "returns a list with one element" <|
        \_ ->
          Expect.equal [ Offset 0 5 ] (tokenise "hello")
      ]
    , describe "when given multiple words"
      [ test "returns multiple offsets" <|
        \_ ->
          Expect.equal [ Offset 0 5, Offset 6 2, Offset 9 7 ] (tokenise "hello yo wassup!")
      ]
    , describe "when given a string with leading spaces"
      [ test "takes them into account" <|
        \_ ->
          Expect.equal [ Offset 1 5 ] (tokenise " hello")
      ]
    , describe "when given a string with trailing spaces"
      [ test "takes them into account" <|
        \_ ->
          Expect.equal [ Offset 0 5 ] (tokenise "hello ")
      ]
    , describe "when given a string with multiple spaces"
      [ test "takes them into account" <|
        \_ ->
          Expect.equal [ Offset 0 5, Offset 7 2, Offset 12 7 ] (tokenise "hello  yo   wassup!")
      ]
    ]

parse_tests :Test
parse_tests =
  describe "The parse function"
    [ describe "when given an empty string"
      [ test "returns an empty list" <|
        \_ ->
          Expect.equal [] (parse "")
      ]
    , describe "when given a string without semantics"
      [ test "links non-semantic values to nothing" <|
        \_ ->
          Expect.equal
            [ (Description, Nothing, Offset 0 7)
            , (Description, Nothing, Offset 7 5)
            , (Description, Nothing, Offset 12 3)
            , (Description, Nothing, Offset 15 3)
            , (Description, Nothing, Offset 18 4)
            ]
            (parse "hello, this is my name")
      ]
    , describe "when given a string with"
      [ describe "tod"
        [ test "classifies it as 'today' with the correct completion" <|
          \_ ->
            Expect.equal
              [ (Today, Just "ay", Offset 0 3)
              ]
              (parse "tod")
        ]
      , describe "toda"
        [ test "classifies it as 'today' with the correct completion" <|
          \_ ->
            Expect.equal
              [ (Today, Just "y", Offset 0 4)
              ]
              (parse "toda")
        ]
      , describe "today"
        [ test "classifies it as 'today' with no additional completion" <|
          \_ ->
            Expect.equal
              [ (Today, Nothing, Offset 0 5)
              ]
              (parse "today")
        ]
      , describe "tom"
        [ test "classifies it as 'tomorrow' with the correct completion" <|
          \_ ->
            Expect.equal
              [ (Tomorrow, Just "orrow", Offset 0 3)
              ]
              (parse "tom")
        ]
      , describe "tomo"
        [ test "classifies it as 'tomorrow' with the correct completion" <|
          \_ ->
            Expect.equal
              [ (Tomorrow, Just "rrow", Offset 0 4)
              ]
              (parse "tomo")
        ]
      , describe "tomor"
        [ test "classifies it as 'tomorrow' with the correct completion" <|
          \_ ->
            Expect.equal
              [ (Tomorrow, Just "row", Offset 0 5)
              ]
              (parse "tomor")
        ]
      , describe "tomorr"
        [ test "classifies it as 'tomorrow' with the correct completion" <|
          \_ ->
            Expect.equal
              [ (Tomorrow, Just "ow", Offset 0 6)
              ]
              (parse "tomorr")
        ]
      , describe "tomorro"
        [ test "classifies it as 'tomorrow' with the correct completion" <|
          \_ ->
            Expect.equal
              [ (Tomorrow, Just "w", Offset 0 7)
              ]
              (parse "tomorro")
        ]
      , describe "tomorrow"
        [ test "classifies it as 'tomorrow' with no additional completion" <|
          \_ ->
            Expect.equal
              [ (Tomorrow, Nothing, Offset 0 8)
              ]
              (parse "tomorrow")
        ]
      ]
    , describe "when given a string with multiple semantics"
      [ test "links values to their correct semantics" <|
        \_ ->
          Expect.equal
            [ (Description, Nothing, Offset 0 6)
            , (Today, Nothing, Offset 7 5)
            , (Tomorrow, Nothing, Offset 13 8)
            , (Description, Nothing, Offset 23 4)
            , (Description, Nothing, Offset 28 2)
            , (Description, Nothing, Offset 31 2)
            , (Description, Nothing, Offset 34 4)
            ]
            (parse "hello, today tomorrow  this is my name")
      ]
    ]

isWithinOffset_tests : Test
isWithinOffset_tests =
  describe "The isWithinOffset function"
    [ describe "when given an offset and position"
      [ test "returns true if the position is within the offset" <|
        \_ ->
          Expect.equal True (isWithinOffset 3 6 4)
      , test "returns true if the position is at the start of the offset" <|
        \_ ->
          Expect.equal True (isWithinOffset 3 6 3)
      , test "returns true if the position is at the end of the offset" <|
        \_ ->
          Expect.equal True (isWithinOffset 3 6 9)
      , test "returns false if the position is before the offset" <|
        \_ ->
          Expect.equal False (isWithinOffset 3 6 2)
      , test "returns false if the position is after the offset" <|
        \_ ->
          Expect.equal False (isWithinOffset 3 6 10)
      ]
    ]

suite : Test
suite =
  describe "The String module"
    [ describe "String.reverse" -- Nest as many descriptions as you like.
      [ test "has no effect on a palindrome" <|
        \_ ->
          let
            palindrome =
                "hannah"
          in
            Expect.equal palindrome (String.reverse palindrome)

        -- Expect.equal is designed to be used in pipeline style, like this.
      , test "reverses a known string" <|
        \_ ->
          "ABCDEFG"
            |> String.reverse
            |> Expect.equal "GFEDCBA"

        -- fuzz runs the test 100 times with randomly-generated inputs!
      , fuzz string "restores the original string if you run it again" <|
          \randomlyGeneratedString ->
            randomlyGeneratedString
              |> String.reverse
              |> String.reverse
              |> Expect.equal randomlyGeneratedString
      ]
    ]