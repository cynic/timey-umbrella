module Utility exposing (..)
import Time exposing (..)
import Data exposing (..)
import Time.Extra exposing (..)
import Easter exposing (easter, EasterMethod(..))

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

seekDate : DateSearch -> Date
seekDate search =
  let
    next =
      case search.direction of
        SearchForward ->
          incrementDay
        SearchBackward ->
          decrementDay
    doSeek dt =
      if search.predicate dt then
        dt
      else
        doSeek (next dt)
  in
    case search.start of
      StartIncluding dt ->
        doSeek dt
      StartExcluding dt ->
        doSeek (next dt)

getSaturday : Date -> Date
getSaturday date =
  seekDate
    (DateSearch (StartIncluding date) SearchBackward (\d -> d.weekday == Sat))

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

weekDay : Int -> Month -> Int -> Time.Weekday
weekDay year month day =
  Time.Extra.partsToPosix Time.utc (Time.Extra.Parts year month day 0 0 0 0)
  |> Time.toWeekday Time.utc

ymdToDate : Int -> Month -> Int -> Date
ymdToDate year month day =
  Date year month day (weekDay year month day)

publicHolidays : Int -> List (Date, String) -- in South Africa
publicHolidays year =
  let
    easterDate =
      easter Western year
      |> (\dt -> ymdToDate dt.year dt.month dt.day)
    extraHolidays =
      case year of
        2024 ->
          [ (ymdToDate year May 29, "General Election Day")
          ]
        _ ->
          []
  in
    extraHolidays ++
    [ (ymdToDate year Jan 1, "New Year's Day")
    , (ymdToDate year Mar 21, "Human Rights Day")
    , (seekDate (DateSearch (StartExcluding easterDate) SearchBackward (\d -> d.weekday == Fri))
      , "Good Friday"
      )
    , (seekDate (DateSearch (StartExcluding easterDate) SearchForward (\d -> d.weekday == Mon))
      , "Family Day"
      )
    , (ymdToDate year Apr 27, "Freedom Day")
    , (ymdToDate year May 1, "Workers' Day")
    , (ymdToDate year Jun 16, "Youth Day")
    , (ymdToDate year Aug 9, "National Women's Day")
    , (ymdToDate year Sep 24, "Heritage Day")
    , (ymdToDate year Dec 16, "Day of Reconciliation")
    , (ymdToDate year Dec 25, "Christmas Day")
    , (ymdToDate year Dec 26, "Day of Goodwill")
    ]
    |> List.map (\(dt, name) ->
      ( seekDate (DateSearch (StartIncluding dt) SearchForward (\d -> d.weekday /= Sun))
      , name
      )
    )
