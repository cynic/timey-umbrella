module ClientServer exposing (..)
import Json.Decode as D
import Json.Encode as E
import Http exposing (..)
import Data exposing (..)
import Utility exposing (ymdToDate)
import Time
import Utility exposing (intToMonth)
import Set
import Dict

baseUrl : String
baseUrl = "http://localhost:4000/api"

timeDecoder : D.Decoder SimpleTime
timeDecoder =
  D.string
  |> D.andThen
    (\timeString ->
      case String.split ":" timeString of
        [hour, minute] ->
          case ( String.toInt hour, String.toInt minute ) of
            ( Just h, Just m ) ->
              if h >= 0 && h < 24 && m >= 0 && m < 60 then
                D.succeed (SimpleTime h m)
              else
                D.fail ("Invalid time in time '" ++ timeString ++ "'")
            ( Nothing, _ ) ->
              D.fail ("Invalid hour in time '" ++ timeString ++ "'")
            ( _, Nothing ) ->
              D.fail ("Invalid minute in time '" ++ timeString ++ "'")
        _ ->
          D.fail "Invalid time format"
    )

dateDecoder : D.Decoder Date
dateDecoder =
  D.string
  |> D.andThen
    (\dateString ->
      case String.split "/" dateString of
        [year, month, day] ->
          case ( String.toInt year, String.toInt month, String.toInt day ) of
            ( Just y, Just m, Just d ) ->
              D.succeed (ymdToDate y (intToMonth m) d)
            ( Nothing, _, _ ) ->
              D.fail ("Invalid year in date '" ++ dateString ++ "'")
            ( _, Nothing, _ ) ->
              D.fail ("Invalid month in date '" ++ dateString ++ "'")
            ( _, _, Nothing ) ->
              D.fail ("Invalid day in date '" ++ dateString ++ "'")
        _ ->
          D.fail "Invalid date format"
    )

taskTypeStrings : Set.Set String
taskTypeStrings =
  Set.fromList
    [ "archive", "to_buy", "idea", "milestone", "practice"
    , "someday", "todo", "supervision", "routine", "checkback"
    , "event"
    ]

taskTypeStringDecoder : D.Decoder String
taskTypeStringDecoder =
  D.string
  |> D.andThen
    (\taskString ->
      if Set.member taskString taskTypeStrings then
        D.succeed taskString
      else
        D.fail ("Invalid task-type '" ++ taskString ++ "'")
    )

bigDurationDecoder : D.Decoder Duration
bigDurationDecoder =
  D.string
  |> D.andThen
    (\durationString ->
      case String.split " " durationString of
        [num, unit] ->
          case ( String.toInt num, unit ) of
            ( Just n, "d" ) ->
              D.succeed (Days n)
            ( Just n, "w" ) ->
              D.succeed (Weeks n)
            ( Nothing, _ ) ->
              D.fail ("Invalid number in big duration '" ++ durationString ++ "'")
            ( _, _ ) ->
              D.fail ("Invalid unit in big duration '" ++ durationString ++ "'")
        _ ->
          D.fail ("Invalid duration format '" ++ durationString ++ "'")
    )

smallishDurationDecoder : D.Decoder Duration
smallishDurationDecoder =
  D.string
  |> D.andThen
    (\durationString ->
      case String.split " " durationString of
        [h, "h", m, "m"] ->
          case ( String.toInt h, String.toInt m ) of
            ( Just h_, Just m_ ) ->
              D.succeed (Hours h_ m_)
            ( Nothing, _ ) ->
              D.fail ("Invalid hour in smallish duration '" ++ durationString ++ "'")
            ( _, Nothing ) ->
              D.fail ("Invalid minute in smallish duration '" ++ durationString ++ "'")
        [h, "h"] ->
          String.toInt h
          |> Maybe.map (\h_ -> D.succeed (Hours h_ 0))
          |> Maybe.withDefault (D.fail ("Invalid number in smallish duration '" ++ durationString ++ "'"))
        [x, "m"] ->
          String.toInt x
          |> Maybe.map (\m -> D.succeed (Minutes m))
          |> Maybe.withDefault (D.fail ("Invalid number in smallish duration '" ++ durationString ++ "'"))
        [x, "d"] ->
          String.toInt x
          |> Maybe.map (\d -> D.succeed (Days d))
          |> Maybe.withDefault (D.fail ("Invalid number in smallish duration '" ++ durationString ++ "'"))
        [x, "w"] ->
          String.toInt x
          |> Maybe.map (\w -> D.succeed (Weeks w))
          |> Maybe.withDefault (D.fail ("Invalid number in smallish duration '" ++ durationString ++ "'"))
        _ ->
          D.fail ("Invalid duration smallish format '" ++ durationString ++ "'")
    )

smallDurationDecoder : D.Decoder Duration
smallDurationDecoder =
  D.string
  |> D.andThen
    (\durationString ->
      case String.split " " durationString of
        [h, "h", m, "m"] ->
          case ( String.toInt h, String.toInt m ) of
            ( Just h_, Just m_ ) ->
              D.succeed (Hours h_ m_)
            ( Nothing, _ ) ->
              D.fail ("Invalid hour in small duration '" ++ durationString ++ "'")
            ( _, Nothing ) ->
              D.fail ("Invalid minute in small duration '" ++ durationString ++ "'")
        [h, "h"] ->
          String.toInt h
          |> Maybe.map (\h_ -> D.succeed (Hours h_ 0))
          |> Maybe.withDefault (D.fail ("Invalid number in small duration '" ++ durationString ++ "'"))
        [x, "m"] ->
          String.toInt x
          |> Maybe.map (\m -> D.succeed (Minutes m))
          |> Maybe.withDefault (D.fail ("Invalid number in small duration '" ++ durationString ++ "'"))
        _ ->
          D.fail ("Invalid duration small format '" ++ durationString ++ "'")
    )

actionDecoder : D.Decoder TaskAction
actionDecoder =
  D.field "tag" D.string
  |> D.andThen
    (\tag ->
      case tag of
        "created" ->
          D.field "created" taskTypeStringDecoder
          |> D.map Created
        "spawned_from" ->
          D.map2 SpawnedFrom
            (D.field "spawner" D.int)
            (D.field "this" taskTypeStringDecoder)
        "transitioned_from" ->
          D.map2 TransitionedFrom
            (D.field "old" D.int)
            (D.field "to" taskTypeStringDecoder)
        "bought" ->
          D.succeed Bought
        "achieved" ->
          D.succeed Achieved
        "delayed" ->
          D.map2 Delayed
            (D.field "reason" D.string)
            (D.field "newDate" dateDecoder)
        "practice_done" ->
          D.oneOf
            [ (D.field "log" D.string |> D.map (\log -> PracticeDone (Just log)))
            , D.succeed <| PracticeDone Nothing
            ]
        "done" ->
          D.succeed Done
        "okay" ->
          D.succeed Okay
        "pushedOffBy" ->
          D.map PushedOffBy
            (D.field "delay" bigDurationDecoder)
        "ignore" ->
          D.map Ignore
            (D.field "reason" D.string)
        "waitngForResponse" ->
          D.succeed WaitingForResponse
        "reschedule" ->
          D.map2 RescheduleTo
            (D.field "newDate" dateDecoder)
            (D.field "newTime" timeDecoder)
        "happened" ->
          D.oneOf
            [ (D.field "log" D.string |> D.map (\log -> Happened (Just log)))
            , D.succeed <| Happened Nothing
            ]
        "transition" ->
          D.map2 Transition
            (D.field "from" taskTypeStringDecoder)
            (D.field "to" taskTypeStringDecoder)
        _ -> D.fail ("Invalid action tag '" ++ tag ++ "'")
    
    )

actionHistoryItemDecoder : D.Decoder { action : TaskAction, date : Date }
actionHistoryItemDecoder =
  D.map2
    (\action date ->
      { action = action
      , date = date
      }
    )
    (D.field "act" actionDecoder)
    (D.field "dt" dateDecoder)

intervalDict : Dict.Dict String PlusInterval
intervalDict =
  Dict.fromList
    [ ( "days", PlusDays )
    , ( "workdays", PlusWorkdays )
    , ( "weeks", PlusWeeks )
    , ( "months", PlusMonths )
    , ( "years", PlusYears )
    ]

plusIntervalDecoder : D.Decoder PlusInterval
plusIntervalDecoder =
  D.string
  |> D.andThen
    (\intervalString ->
      case Dict.get intervalString intervalDict of
        Just interval ->
          D.succeed interval
        Nothing ->
          D.fail ("Invalid interval '" ++ intervalString ++ "'")
    )

weekendDayDecoder : D.Decoder WeekendDay
weekendDayDecoder =
  D.string
  |> D.andThen
    (\dayString ->
      case dayString of
        "sat" ->
          D.succeed Saturday
        "sun" ->
          D.succeed Sunday
        _ ->
          D.fail ("Invalid weekend day '" ++ dayString ++ "'")
    )

weekdayDecoder : D.Decoder Time.Weekday
weekdayDecoder =
  D.string
  |> D.andThen
    (\dayString ->
      case dayString of
        "mon" ->
          D.succeed Time.Mon
        "tue" ->
          D.succeed Time.Tue
        "wed" ->
          D.succeed Time.Wed
        "thu" ->
          D.succeed Time.Thu
        "fri" ->
          D.succeed Time.Fri
        -- SHOULD I be including Sat & Sun here?
        "sat" ->
          D.succeed Time.Sat
        "sun" ->
          D.succeed Time.Sun
        _ ->
          D.fail ("Invalid weekday '" ++ dayString ++ "'")
    )

decodeMonthInterval : D.Decoder (WhenInInterval Int)
decodeMonthInterval =
  D.oneOf
    [ D.field "days" (D.list D.int) |> D.map On
    , D.field "from_start" D.int |> D.map Start
    , D.field "from_end" D.int |> D.map End
    ]

monthAndDayDecoder : D.Decoder (Time.Month, Int)
monthAndDayDecoder =
  D.map2
    (\month day -> ( intToMonth month, day ))
    (D.field "m" D.int)
    (D.field "d" D.int)

repetitionUnitsDecoder : D.Decoder RepetitionUnits
repetitionUnitsDecoder =
  D.field "tag" D.string
  |> D.andThen
    (\tag ->
      case tag of
        "days" ->
          D.succeed DaysPassed
        "workdays" ->
          D.succeed Workdays
        "weekends" ->
          D.field "on" (D.list weekendDayDecoder) |> D.map Weekends
        "weeks" ->
          D.field "on" (D.list weekdayDecoder) |> D.map WeeksPassed
        "months" ->
          decodeMonthInterval |> D.map MonthsPassed
        "years" ->
          D.field "on" (D.list monthAndDayDecoder) |> D.map YearsPassed
        _ ->
          D.fail ("Invalid repetition units tag '" ++ tag ++ "'")
    )

recurrenceDecoder : D.Decoder Recurrence
recurrenceDecoder =
  D.field "tag" D.string
  |> D.andThen
    (\tag ->
      case tag of
        "last_completed_date" ->
          D.map2 LastCompletedDate
            (D.field "interval" plusIntervalDecoder)
            (D.field "n" D.int)
        "every" ->
          D.map2 Every
            (D.field "n" D.int)
            (D.field "specifically" repetitionUnitsDecoder)
        "once" ->
          D.succeed OnceOnly
        _ ->
          D.fail ("Invalid recurrence tag '" ++ tag ++ "'")
    )

whenDecoder : D.Decoder When
whenDecoder =
  D.field "anchor" dateDecoder
  |> D.andThen
    (\anchor ->
      D.field "recurrence" recurrenceDecoder
      |> D.map (When anchor)
    )

decodeIdea : Int -> String -> ActionHistory -> D.Decoder Task
decodeIdea id desc life =
  D.map
    (\created ->
      Idea <| Task60 id desc created life
    )
    (D.field "created" dateDecoder)

decodeMilestone : Int -> String -> ActionHistory -> D.Decoder Task
decodeMilestone id desc life =
  D.map
    (\deadline ->
      Milestone <| Task80 id desc deadline life
    )
    (D.field "deadline" dateDecoder)

decodePractice : Int -> String -> ActionHistory -> D.Decoder Task
decodePractice id desc life =
  D.map
    (\estimate ->
      Practice <| Task100 id desc estimate life
    )
    (D.field "estimate" smallishDurationDecoder)

decodeSomeday : Int -> String -> ActionHistory -> D.Decoder Task
decodeSomeday id desc life =
  D.map2
    (\created estimate ->
      Someday <| Task120 id desc created estimate life
    )
    (D.field "created" dateDecoder)
    (D.field "estimate" smallishDurationDecoder)

decodeTodo : Int -> String -> ActionHistory -> D.Decoder Task
decodeTodo id desc life =
  D.map2
    (\created deadline -> ( created, deadline ))
    (D.field "created" dateDecoder)
    (D.field "deadline" dateDecoder)
  |> D.andThen
    (\(created, deadline) ->
      D.oneOf
        [ ( D.field "estimate" smallishDurationDecoder
            |> D.map (\estimate -> Todo <| Task140 id desc created (Just estimate) deadline life)
          )
        , D.succeed (Todo <| Task140 id desc created Nothing deadline life)
        ]
    )

decodeSupervision : Int -> String -> ActionHistory -> D.Decoder Task
decodeSupervision id desc life =
  D.map3
    (\created deadline student ->
      SupervisionTask <| Task160 id desc created deadline student life
    )
    (D.field "created" dateDecoder)
    (D.field "deadline" dateDecoder)
    (D.field "student" D.string)

decodeRoutine : Int -> String -> ActionHistory -> D.Decoder Task
decodeRoutine id desc life =
  D.map2
    (\estimate when ->
      Routine <| Task180 id desc estimate when life
    )
    (D.field "estimate" smallDurationDecoder)
    (D.field "when" whenDecoder)

decodeCheckBack : Int -> String -> ActionHistory -> D.Decoder Task
decodeCheckBack id desc life =
  D.map
    (\deadline ->
      CheckBack <| Task200 id desc deadline life
    )
    (D.field "deadline" dateDecoder)

decodeEvent : Int -> String -> ActionHistory -> D.Decoder Task
decodeEvent id desc life =
  D.map4
    (\created duration time when ->
      Event <| Task220 id desc created duration time when life
    )
    (D.field "created" dateDecoder)
    (D.field "duration" smallishDurationDecoder)
    (D.field "time" timeDecoder)
    (D.field "when" whenDecoder)
    
taskDecoder : D.Decoder Task
taskDecoder =
  D.map4
    (\id desc tag life ->
      { id = id
      , desc = desc
      , tag = tag
      , life = life
      }
      -- Task20
      --   id
      --   desc
      --   []
      --   -- (Time.millisToPosix created_ms |> Utility.posixToDate Time.utc)
      --   -- NothingPending
    )
    (D.field "id" D.int)
    (D.field "description" D.string)
    (D.field "tag" D.string)
    (D.field "life" (D.list actionHistoryItemDecoder))
  |> D.andThen (\{ id, desc, tag, life } ->
    case tag of
      "archive" -> D.succeed <| ArchivedItem (Task20 id desc life)
      "to_buy" -> D.succeed <| ShoppingListItem (Task20 id desc life)
      "idea" -> decodeIdea id desc life
      "milestone" -> decodeMilestone id desc life
      "practice" -> decodePractice id desc life
      "someday" -> decodeSomeday id desc life
      "todo" -> decodeTodo id desc life
      "supervision" -> decodeSupervision id desc life
      "routine" -> decodeRoutine id desc life
      "checkback" -> decodeCheckBack id desc life
      "event" -> decodeEvent id desc life
      _ -> D.fail ("Invalid task tag '" ++ tag ++ "'")
  )


---------------------
ymdToString : Date -> String
ymdToString date =
  String.fromInt date.year ++ "/" ++ String.fromInt (Utility.monthToInt date.month) ++ "/" ++ String.fromInt date.day

durationEncoder : Duration -> E.Value
durationEncoder duration =
  case duration of
    Minutes m ->
      E.string (String.fromInt m ++ " m")
    Hours h m ->
      E.string (String.fromInt h ++ " h " ++ String.fromInt m ++ " m")
    Days d ->
      E.string (String.fromInt d ++ " d")
    Weeks w ->
      E.string (String.fromInt w ++ " w")

timeEncoder : SimpleTime -> E.Value
timeEncoder time =
  E.string (String.fromInt time.hour ++ ":" ++ String.fromInt time.minute)

actionEncoder : TaskAction -> E.Value
actionEncoder act =
  case act of
    Created type_ ->
      E.object
        [ ( "tag", E.string "created" )
        , ( "created", E.string type_ )
        ]
    SpawnedFrom spawner this ->
      E.object
        [ ( "tag", E.string "spawned_from" )
        , ( "spawner", E.int spawner )
        , ( "this", E.string this )
        ]
    TransitionedFrom old to ->
      E.object
        [ ( "tag", E.string "transitioned_from" )
        , ( "old", E.int old )
        , ( "to", E.string to )
        ]
    Bought ->
      E.object
        [ ( "tag", E.string "bought" ) ]
    Achieved ->
      E.object
        [ ( "tag", E.string "achieved" ) ]
    Delayed reason newDate ->
      E.object
        [ ( "tag", E.string "delayed" )
        , ( "reason", E.string reason )
        , ( "newDate", E.string (ymdToString newDate) )
        ]
    PracticeDone maybeLog ->
      case maybeLog of
        Just log ->
          E.object
            [ ( "tag", E.string "practice_done" )
            , ( "log", E.string log )
            ]
        Nothing ->
          E.object
            [ ( "tag", E.string "practice_done" ) ]
    Done ->
      E.object
        [ ( "tag", E.string "done" ) ]
    Okay ->
      E.object
        [ ( "tag", E.string "okay" ) ]
    PushedOffBy delay ->
      E.object
        [ ( "tag", E.string "pushedOffBy" )
        , ( "delay", durationEncoder delay )
        ]
    Ignore reason ->
      E.object
        [ ( "tag", E.string "ignore" )
        , ( "reason", E.string reason )
        ]
    WaitingForResponse ->
      E.object
        [ ( "tag", E.string "waitingForResponse" ) ]
    RescheduleTo newDate newTime ->
      E.object
        [ ( "tag", E.string "reschedule" )
        , ( "newDate", E.string (ymdToString newDate) )
        , ( "newTime", timeEncoder newTime )
        ]
    Happened maybeLog ->
      case maybeLog of
        Just log ->
          E.object
            [ ( "tag", E.string "happened" )
            , ( "log", E.string log )
            ]
        Nothing ->
          E.object
            [ ( "tag", E.string "happened" ) ]
    Transition from to ->
      E.object
        [ ( "tag", E.string "transition" )
        , ( "from", E.string from )
        , ( "to", E.string to )
        ]

encodeActionHistoryItemEncoder : { action : TaskAction, date : Date } -> E.Value
encodeActionHistoryItemEncoder actionHistoryItem =
  E.object
    [ ( "act", actionEncoder actionHistoryItem.action )
    , ( "dt", E.string (ymdToString actionHistoryItem.date) )
    ]

weekendDayEncoder : WeekendDay -> E.Value
weekendDayEncoder day =
  case day of
    Saturday ->
      E.string "sat"
    Sunday ->
      E.string "sun"

weekdayEncoder : Time.Weekday -> E.Value
weekdayEncoder day =
  case day of
    Time.Mon ->
      E.string "mon"
    Time.Tue ->
      E.string "tue"
    Time.Wed ->
      E.string "wed"
    Time.Thu ->
      E.string "thu"
    Time.Fri ->
      E.string "fri"
    Time.Sat ->
      E.string "sat"
    Time.Sun ->
      E.string "sun"

monthIntervalEncoder : WhenInInterval Int -> E.Value
monthIntervalEncoder when =
  case when of
    On days ->
      E.object
        [ ( "days", E.list E.int days ) ]
    Start n ->
      E.object
        [ ( "from_start", E.int n ) ]
    End n ->
      E.object
        [ ( "from_end", E.int n ) ]

monthAndDayEncoder : (Time.Month, Int) -> E.Value
monthAndDayEncoder (mon, day) =
  E.object
    [ ( "m", E.int (Utility.monthToInt mon) )
    , ( "d", E.int day )
    ]

repetitionUnitsEncoder : RepetitionUnits -> E.Value
repetitionUnitsEncoder units =
  case units of
    DaysPassed ->
      E.object
        [ ( "tag", E.string "days" ) ]
    Workdays ->
      E.object
        [ ( "tag", E.string "workdays" ) ]
    Weekends days ->
      E.object
        [ ( "tag", E.string "weekends" )
        , ( "on", E.list weekendDayEncoder days )
        ]
    WeeksPassed days ->
      E.object
        [ ( "tag", E.string "weeks" )
        , ( "on", E.list weekdayEncoder days )
        ]
    MonthsPassed interval ->
      E.object
        [ ( "tag", E.string "months" )
        , ( "days", monthIntervalEncoder interval )
        ]
    YearsPassed days ->
      E.object
        [ ( "tag", E.string "years" )
        , ( "on", E.list monthAndDayEncoder days )
        ]

plusIntervalEncoder : PlusInterval -> E.Value
plusIntervalEncoder interval =
  case interval of
    PlusDays ->
      E.string "days"
    PlusWorkdays ->
      E.string "workdays"
    PlusWeeks ->
      E.string "weeks"
    PlusMonths ->
      E.string "months"
    PlusYears ->
      E.string "years"

recurrenceEncoder : Recurrence -> E.Value
recurrenceEncoder recurrence =
  case recurrence of
    LastCompletedDate interval n ->
      E.object
        [ ( "tag", E.string "last_completed_date" )
        , ( "interval", plusIntervalEncoder interval )
        , ( "n", E.int n )
        ]
    Every n specifically ->
      E.object
        [ ( "tag", E.string "every" )
        , ( "n", E.int n )
        , ( "specifically", repetitionUnitsEncoder specifically )
        ]
    OnceOnly ->
      E.object
        [ ( "tag", E.string "once" ) ]

whenEncoder : When -> E.Value
whenEncoder when =
  E.object
    [ ( "anchor", E.string (ymdToString when.anchor) )
    , ( "recurrence", recurrenceEncoder when.recurrence )
    ]

taskEncoder : Task -> E.Value
taskEncoder task =
  case task of
    ArchivedItem task_ ->
      E.object
        [ ( "id", E.int task_.id )
        , ( "tag", E.string "archive" )
        , ( "description", E.string task_.description )
        , ( "life", E.list encodeActionHistoryItemEncoder task_.life )
        ]
    ShoppingListItem task_ ->
      E.object
        [ ( "id", E.int task_.id )
        , ( "tag", E.string "to_buy" )
        , ( "description", E.string task_.description )
        , ( "life", E.list encodeActionHistoryItemEncoder task_.life )
        ]
    Idea task_ ->
      E.object
        [ ( "id", E.int task_.id )
        , ( "tag", E.string "idea" )
        , ( "description", E.string task_.description )
        , ( "life", E.list encodeActionHistoryItemEncoder task_.life )
        , ( "created", E.string (ymdToString task_.created) )
        ]
    Milestone task_ ->
      E.object
        [ ( "id", E.int task_.id )
        , ( "tag", E.string "milestone" )
        , ( "description", E.string task_.description )
        , ( "life", E.list encodeActionHistoryItemEncoder task_.life )
        , ( "deadline", E.string (ymdToString task_.deadline) )
        ]
    Practice task_ ->
      E.object
        [ ( "id", E.int task_.id )
        , ( "tag", E.string "practice" )
        , ( "description", E.string task_.description )
        , ( "life", E.list encodeActionHistoryItemEncoder task_.life )
        , ( "estimate", durationEncoder task_.estimate )
        ]
    Someday task_ ->
      E.object
        [ ( "id", E.int task_.id )
        , ( "tag", E.string "someday" )
        , ( "description", E.string task_.description )
        , ( "life", E.list encodeActionHistoryItemEncoder task_.life )
        , ( "created", E.string (ymdToString task_.created) )
        , ( "estimate", durationEncoder task_.estimate )
        ]
    Todo task_ ->
      case task_.estimate of
        Just estimate ->
          E.object
            [ ( "id", E.int task_.id )
            , ( "tag", E.string "todo" )
            , ( "description", E.string task_.description )
            , ( "life", E.list encodeActionHistoryItemEncoder task_.life )
            , ( "created", E.string (ymdToString task_.created) )
            , ( "deadline", E.string (ymdToString task_.deadline) )
            , ( "estimate", durationEncoder estimate )
            ]
        Nothing ->
          E.object
            [ ( "id", E.int task_.id )
            , ( "tag", E.string "todo" )
            , ( "description", E.string task_.description )
            , ( "life", E.list encodeActionHistoryItemEncoder task_.life )
            , ( "created", E.string (ymdToString task_.created) )
            , ( "deadline", E.string (ymdToString task_.deadline) )
            ]
    SupervisionTask task_ ->
      E.object
        [ ( "id", E.int task_.id )
        , ( "tag", E.string "supervision" )
        , ( "description", E.string task_.description )
        , ( "life", E.list encodeActionHistoryItemEncoder task_.life )
        , ( "created", E.string (ymdToString task_.created) )
        , ( "deadline", E.string (ymdToString task_.deadline) )
        , ( "student", E.string task_.student )
        ]
    Routine task_ ->
      E.object
        [ ( "id", E.int task_.id )
        , ( "tag", E.string "routine" )
        , ( "description", E.string task_.description )
        , ( "life", E.list encodeActionHistoryItemEncoder task_.life )
        , ( "estimate", durationEncoder task_.estimate )
        , ( "when", whenEncoder task_.when )
        ]
    CheckBack task_ ->
      E.object
        [ ( "id", E.int task_.id )
        , ( "tag", E.string "checkback" )
        , ( "description", E.string task_.description )
        , ( "life", E.list encodeActionHistoryItemEncoder task_.life )
        , ( "deadline", E.string (ymdToString task_.deadline) )
        ]
    Event task_ ->
      E.object
        [ ( "id", E.int task_.id )
        , ( "tag", E.string "event" )
        , ( "description", E.string task_.description )
        , ( "life", E.list encodeActionHistoryItemEncoder task_.life )
        , ( "created", E.string (ymdToString task_.created) )
        , ( "duration", durationEncoder task_.duration )
        , ( "time", timeEncoder task_.time )
        , ( "when", whenEncoder task_.when )
        ]


----------------------
withinDataDecoder : D.Decoder a -> D.Decoder a
withinDataDecoder decoder =
  D.field "data" decoder

getTasks : Cmd Msg
getTasks =
  Http.get
    { url = baseUrl ++ "/tasks"
    , expect = Http.expectJson GotTasks (withinDataDecoder (D.list taskDecoder))
    }

createTask : String -> Cmd Msg
createTask description =
  Http.post
    { url = baseUrl ++ "/tasks"
    , body =
        Http.jsonBody <|
          E.object
            [ ("task"
              , E.object
                  [ ("text"
                    , E.string description
                    )
                  , ( "status"
                    , E.string "active"
                    )
                  ]
              )
            ]
    , expect = Http.expectJson GotTask (withinDataDecoder taskDecoder)
    }

completeTask : Int -> Cmd Msg
completeTask id =
  Http.request
    { method = "PATCH"
    , headers = []
    , url = baseUrl ++ "/tasks/" ++ String.fromInt id
    , body =
        Http.jsonBody <|
          E.object
            [ ("task"
              , E.object
                  [ ("status"
                    , E.string "complete"
                    )
                  ]
              )
            ]
    , expect = Http.expectWhatever (\_ -> ServerDone <| "Task #" ++ String.fromInt id ++ " completed")
    , timeout = Nothing
    , tracker = Nothing
    }

deleteTask : Int -> Cmd Msg
deleteTask id =
  Http.request
    { method = "DELETE"
    , headers = []
    , url = baseUrl ++ "/tasks/" ++ String.fromInt id
    , body = Http.emptyBody
    , expect = Http.expectWhatever (\_ -> PerformTaskDelete id)
    , timeout = Nothing
    , tracker = Nothing
    }