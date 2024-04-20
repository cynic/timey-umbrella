module Data exposing (..)

import Time
import Http

-- MODEL

type alias Date =
  { year : Int
  , month : Time.Month
  , day : Int
  , weekday : Time.Weekday
  }

-- type alias RoughInterval =
--   (Int, Int) -- e.g. roughly every 5-8 days/minutes/etc

-- type Pause
--   = Indefinitely { since : Date }
--   | Approximately RoughInterval -- measured in days

-- type TimeExpenditure
--   -- just unknown
--   = Undefined
--   | About RoughInterval -- measured in minutes/hours depending on suffix

-- type DeadlineTypes
--   -- this is the deadline by which the thing MUST be done.  Usually set by other people…
--   = HardDeadline Date
--   -- now, this is a "deadline" by which I kind of want to have it done, and there's a hard deadline too by which it MUST be done
--   | SoftDeadline Date Date
--   -- I want to have done some of this done just to keep some form of forward-progress, but when it's actually done is unknown.  Maybe never?
--   | ForwardProgress 

-- type Status
--   = Active
--   | Completed Posix
--   | Paused { previously : Status, now : Status }
--   | BallPlayed { checkAfter : RoughInterval } -- in days

-- type alias Todo =
--   { created : Date
--   , text : String
--   , status : Status
--   , spawnContext : Maybe String -- can be an event, a person, a todo
--   }

-- type CoreDatum
--   = Start

-- type alias CoreDatumModel =
--   {
--   }

type SmallDuration
  = Minutes Int
  | Hours Int Int

-- AwesomeBar start
type Token
  = Today
  | Tomorrow
  | Description
  | Duration SmallDuration
  -- | AcceptLiterally
  -- | Cursor
  -- | AfterDays Int
  -- | AfterWeeks Int
type alias Offset =
  { offset : Int
  , extent : Int
  }

type alias AwesomeBarState =
  { s : String
  , i : Int -- caret position
  , parse : List (Token, Maybe String, Offset)
  }
-- AwesomeBar end

type LongerDurationUnit
  = Week
  | Month
  | Quarter

type WhenInDuration a
  = End
  | Start
  | On (List a)

type BigDuration
  = Days Int -- after how many days. 0 = today, 1 = tomorrow, etc.
  | Weekdays (WhenInDuration Time.Weekday)
  | Workdays (WhenInDuration Time.Weekday)
  | Weekends (WhenInDuration Time.Weekday)
  | Weeks (WhenInDuration Time.Weekday)
  | Months (WhenInDuration Int) -- days of month.  EXCLUDE 28-31??
  | Years (WhenInDuration (Time.Month, Int)) -- months, days of month

type Recurrence
  = LastCompletedDatePlus BigDuration
  | Every Int BigDuration -- The Int is for the recurrence, e.g. every 2 [unit], every 1 [unit], etc
  | Once (WhenInDuration (Time.Month, Int)) -- month & day, exactly

type alias When =
  { anchor : Date
  , recurrence : Recurrence
  }

type Mode
  = Waiting
  | AwesomeBar AwesomeBarState

type ABSpecialKey
  = Escape
  | Tab
  | Enter
  | ArrowDown
  | ArrowUp

type ABMsg
  = SetString String Int
  | ListenerRemoved
  | Key ABSpecialKey
  | CaretMoved Int

type Msg
  = NoOp
  | SwitchMode Mode
  | AB ABMsg
  | Tick Time.Posix
  | GetZone Time.Zone
  | GotChecklistItems (Result Http.Error (List ChecklistItem))
  | GotChecklistItem (Result Http.Error ChecklistItem)
  | DeleteChecklistItem Int
  | PerformChecklistDelete Int -- do it on the client-side, once the server has agreed.

-- type alias Todo =
--   { s : String
--   , created : Date
--   , duration : Maybe SmallDuration
--   }

type UIStatus -- for ops that must first be verified by the server
  = NothingPending
  | DeletionRequested

type alias ChecklistItem =
  { id : Int
  , s : String
  , created : Date
  , pending : UIStatus
  }

type alias Model =
  { mode : Mode
  , nowish : Time.Posix
  , zone : Time.Zone
  , checklisten : List ChecklistItem
  }

type DateSearchDirection
  = SearchForward
  | SearchBackward

type DateSearchStart
  = StartIncluding Date
  | StartExcluding Date

type alias DateSearch =
  { start : DateSearchStart
  , direction : DateSearchDirection
  , predicate : Date -> Bool
  }

type alias ParserFunction =
  -- the token, the completion (if any), the number of tokens swallowed
  List String -> Maybe (Token, Maybe String, Int)