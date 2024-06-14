module EncodeDecode exposing (..)

import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import Test exposing (..)
import Main exposing (tokenise, parse)
import View exposing (isWithinOffset)
import Data exposing (..)
import Json.Decode as D
import Json.Encode as E
import ClientServer exposing (..)

roundtrip_task_tests : Test
roundtrip_task_tests =
  describe "We can roundtrip"
    [ test "an archived item" <|
      \_ ->
        let datum = ArchivedItem <| Task20 10 "hello" []
        in
          Expect.equal
            (Ok datum)
            (D.decodeString taskDecoder <| E.encode 0 <| taskEncoder datum)
    ]