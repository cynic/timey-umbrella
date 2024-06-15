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
import Set
import Utility exposing (ymdToDate)
import Time

taskTypeStringFuzzer : Fuzzer String
taskTypeStringFuzzer =
  Fuzz.oneOfValues (Set.toList taskTypeStrings)

dateFuzzer : Fuzzer Date
dateFuzzer =
  Fuzz.map3 ymdToDate
    (Fuzz.intRange 2000 3050)
    (Fuzz.oneOfValues
      [ Time.Jan, Time.Feb, Time.Mar, Time.Apr
      , Time.May, Time.Jun, Time.Jul, Time.Aug
      , Time.Sep, Time.Oct, Time.Nov, Time.Dec
      ]
    )
    (Fuzz.intRange 1 31)

timeFuzzer : Fuzzer SimpleTime
timeFuzzer =
  Fuzz.map2 SimpleTime
    (Fuzz.intRange 0 23)
    (Fuzz.intRange 0 59)

bigDurationFuzzer : Fuzzer Duration
bigDurationFuzzer =
  Fuzz.oneOf
    [ Fuzz.map Days (Fuzz.intAtLeast 0)
    , Fuzz.map Weeks (Fuzz.intAtLeast 0)
    ]

smallDurationFuzzer : Fuzzer Duration
smallDurationFuzzer =
  Fuzz.oneOf
    [ Fuzz.map2 Hours (Fuzz.intRange 0 23) (Fuzz.intRange 0 59)
    , Fuzz.map Minutes (Fuzz.intAtLeast 0)
    ]

smallishDurationFuzzer : Fuzzer Duration
smallishDurationFuzzer =
  Fuzz.oneOf
    [ Fuzz.map2 Hours (Fuzz.intRange 0 23) (Fuzz.intRange 0 59)
    , Fuzz.map Minutes (Fuzz.intRange 0 59)
    , Fuzz.map Days (Fuzz.intAtLeast 0)
    ]

anyDurationFuzzer : Fuzzer Duration
anyDurationFuzzer =
  Fuzz.oneOf
    [ Fuzz.map2 Hours (Fuzz.intRange 0 23) (Fuzz.intRange 0 59)
    , Fuzz.map Minutes (Fuzz.intRange 0 59)
    , Fuzz.map Days (Fuzz.intAtLeast 0)
    , Fuzz.map Weeks (Fuzz.intAtLeast 0)
    ]

actionFuzzer : Fuzzer TaskAction
actionFuzzer =
  Fuzz.oneOf
    [ Fuzz.map Created taskTypeStringFuzzer
    , Fuzz.map2 SpawnedFrom
        (Fuzz.intAtLeast 0)
        taskTypeStringFuzzer
    , Fuzz.map2 TransitionedFrom
        (Fuzz.intAtLeast 0)
        taskTypeStringFuzzer
    , Fuzz.constant Bought
    , Fuzz.constant Achieved
    , Fuzz.map2 Delayed
        Fuzz.string
        dateFuzzer
    , Fuzz.map PracticeDone
        (Fuzz.maybe Fuzz.string)
    , Fuzz.constant Done
    , Fuzz.constant Okay
    , Fuzz.map PushedOffBy bigDurationFuzzer
    , Fuzz.map Ignore Fuzz.string
    , Fuzz.constant WaitingForResponse
    , Fuzz.map2 RescheduleTo
        dateFuzzer
        timeFuzzer
    , Fuzz.map Happened
        (Fuzz.maybe Fuzz.string)
    , Fuzz.map2 Transition
        taskTypeStringFuzzer
        taskTypeStringFuzzer
    ]

actionHistoryItemFuzzer : Fuzzer { action : TaskAction, date : Date }
actionHistoryItemFuzzer =
  Fuzz.map2
    (\action date -> { action = action, date = date })
    actionFuzzer
    dateFuzzer

archivedItemFuzzer : Fuzzer Task
archivedItemFuzzer =
  Fuzz.map3
    (\id desc life ->
      ArchivedItem <| Task20 id desc life
    )
    (Fuzz.intAtLeast 0)
    Fuzz.string
    (Fuzz.list actionHistoryItemFuzzer)

roundtrip_task_tests : Test
roundtrip_task_tests =
  describe "We can roundtrip"
    [ fuzz archivedItemFuzzer "an archived item" <|
      \datum ->
        Expect.equal
          (Ok datum)
          (D.decodeString taskDecoder <| E.encode 0 <| taskEncoder datum)
    ]