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

type alias SimpleTime =
  { hour : Int
  , minute : Int
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

type Duration
  = Minutes Int
  | Hours Int Int
  | Days Int
  | Weeks Int

-- AwesomeBar start
type Token
  = Today
  | Tomorrow
  | Description
  | Duration Duration
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

-- type LongerDurationUnit
--   = Week
--   | Month
--   | Quarter

type WhenInInterval a
  = End Int -- subtraction, max. 10?
  | Start Int -- addition, max. 10?
  | On (List a)

type WeekendDay
  = Saturday
  | Sunday

type RepetitionUnits
  = DaysPassed -- after how many days. 0 = today, 1 = tomorrow, etc.
  -- | OnDays (List Time.Weekday)
  | Workdays
  | Weekends (List WeekendDay)
  | WeeksPassed (List Time.Weekday)
  | MonthsPassed (WhenInInterval Int) -- days of month.  EXCLUDE 28-31??  Or cap it to the closest large one?
  | YearsPassed (List (Time.Month, Int)) -- months, days of month

type PlusInterval
  = PlusDays
  | PlusWorkdays
  | PlusWeeks -- i.e. 7 days
  | PlusMonths -- i.e. plus the number of days _in the month examined_
  | PlusYears

type Recurrence
  = LastCompletedDate PlusInterval Int
  | Every Int RepetitionUnits -- The Int is for the recurrence, e.g. every 2 [unit], every 1 [unit], etc
  | OnceOnly

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
  | NonSpecial

type AwesomeBarMsg
  = SetString String Int
  | ListenerRemoved
  | Key ABSpecialKey
  | CaretMoved Int

type DisallowedReason
  = CannotDeleteNothing
  | InputTypeNotSupported String
  | AwesomeBarNotActivated
  | CaretPositionUnchanged
  | InvalidJsonValueReceived String

type Msg
  = SwitchMode Mode
  | AB AwesomeBarMsg
  | NotAllowed DisallowedReason
  | Tick Time.Posix
  | GetZone Time.Zone
  | GotTasks (Result Http.Error (List Task))
  | GotTask (Result Http.Error Task)
  | DeleteTask Int
  | PerformTaskDelete Int -- do it on the client-side, once the server has agreed.
  | CompleteTask Int
  | ServerDone String

-- type alias Todo =
--   { s : String
--   , created : Date
--   , duration : Maybe SmallDuration
--   }

type UIStatus -- for ops that must first be verified by the server
  = NothingPending
  | DeletionRequested

-- type alias ActiveTask =
--   { id : Int
--   , s : String
--   , created : Date
--   , pending : UIStatus
--   , status : TaskStatus
--   }

type TaskAction -- possible actions that can be done.
  = Created String -- the type created, /ab initio/
  | SpawnedFrom Int String -- the spawner-ID and the type created
  | TransitionedFrom Int String -- the old-ID and the type created
  | Bought
  --- for milestones
  | Achieved
  --- for milestones. Reason and new date.
  | Delayed String Date
  --- for practice. Logging, optionally, what was done.
  | PracticeDone (Maybe String)
  --- for Someday, Todo, Supervision, and Routine
  | Done
  --- for CheckBack
  | Okay
  --- for Todo and Supervision-Task and CheckBack
  | PushedOffBy Duration
  --- for Todo and Supervision-Task
  | Ignore String -- why
  --- for CheckBack, when sent reminder and now waiting for response
  | WaitingForResponse
  --- for Event
  | RescheduleTo Date SimpleTime
  --- for Event.  Logging, optionally, what was done.
  | Happened (Maybe String)
  | Transition String String -- from /type/, to /type/

type alias ActionHistory =
  List
    { action : TaskAction
    , date : Date
    }

-- the different kinds of tasks.  I'm pretty sure I'm missing some of the different 'kinds' of tasks, and
-- naming is hard!  So I'm just going to go with BASIC-style naming, leaving room for other types in-between
-- the numbers.  Old habits die hard, I guess.
type Task -- all have an id
  = ArchivedItem Task20 -- maybe call this the graveyard!
  | ShoppingListItem Task20
  | Idea Task60
  | Milestone Task80
  | Practice Task100
  | Someday Task120
  | Todo Task140
  | SupervisionTask Task160
  | Routine Task180
  | CheckBack Task200
  | Event Task220

type alias Task20 = -- archived item
  { id : Int
  , description : String
  , life : ActionHistory
  }

-- type alias Task40 = Task20

type alias Task60 = -- Idea
  { id : Int
  , description : String
  , created : Date
  , life : ActionHistory
  }

type alias Task80 = -- Milestone
  { id : Int
  , description : String
  , deadline : Date
  , life : ActionHistory
  }

type alias Task100 = -- Practice
  { id : Int
  , description : String
  , estimate : Duration
  , life : ActionHistory
  }

type alias Task120 = -- Someday
  { id : Int
  , description : String
  , created : Date
  , estimate : Duration
  , life : ActionHistory
  }

type alias Task140 = -- \Todo
  { id : Int
  , description : String
  , created : Date
  , estimate : Maybe Duration
  , deadline : Date
  , life : ActionHistory
  }

type alias Task160 = -- Supervision-Task
  { id : Int
  , description : String
  , created : Date
  , deadline : Date
  , student : String
  , life : ActionHistory
  }

type alias Task180 = -- Routine
  { id : Int
  , description : String
  , estimate : Duration
  , when : When
  , life : ActionHistory
  }

type alias Task200 = -- CheckBack
  { id : Int
  , description : String
  , deadline : Date
  , life : ActionHistory
  }

type alias Task220 = -- Event
  { id : Int
  , description : String
  , created : Date
  , duration : Duration
  , time : SimpleTime
  , when : When
  , life : ActionHistory
  }

type alias Model =
  { mode : Mode
  , nowish : Time.Posix
  , zone : Time.Zone
  , data : List Task
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