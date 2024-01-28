module Data exposing (..)

import Time
import Browser.Navigation as Navigation

-- MODEL

type alias Date =
  { year : Int
  , month : Int
  , day : Int
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
  , tokenised : List Offset
  , parse : List (Token, Maybe String, Offset)
  }
-- AwesomeBar end

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

type alias Todo =
  { s : String
  , created : Date
  , duration : Maybe SmallDuration
  }

type alias Model =
  { key : Navigation.Key
  , mode : Mode
  , nowish : Time.Posix
  , zone : Time.Zone
  , data : List Todo
  }
