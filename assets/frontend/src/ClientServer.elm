module ClientServer exposing (..)
import Json.Decode as D
import Json.Encode as E
import Http exposing (..)
import Data exposing (..)
import Utility exposing (ymdToDate)
import Time

baseUrl : String
baseUrl = "http://localhost:4000"

checklistItemDecoder : D.Decoder ChecklistItem
checklistItemDecoder =
  D.map3
    (\id desc created_ms ->
      ChecklistItem
        id
        desc
        (Time.millisToPosix created_ms |> Utility.posixToDate Time.utc)
        NothingPending
    )
    (D.field "id" D.int)
    (D.field "description" D.string)
    (D.field "created" D.int)
  

withinDataDecoder : D.Decoder a -> D.Decoder a
withinDataDecoder decoder =
  D.field "data" decoder

getChecklistItems : Cmd Msg
getChecklistItems =
  Http.get
    { url = baseUrl ++ "/checklist_items"
    , expect = Http.expectJson GotChecklistItems (withinDataDecoder (D.list checklistItemDecoder))
    }

createChecklistItem : String -> Cmd Msg
createChecklistItem description =
  Http.post
    { url = baseUrl ++ "/checklist_items"
    , body =
        Http.jsonBody <|
          E.object
            [ ("checklist_item"
              , E.object
                  [ ("description"
                    , E.string description
                    )
                  ]
              )
            ]
    , expect = Http.expectJson GotChecklistItem (withinDataDecoder checklistItemDecoder)
    }

deleteChecklistItem : Int -> Cmd Msg
deleteChecklistItem id =
  Http.request
    { method = "DELETE"
    , headers = []
    , url = baseUrl ++ "/checklist_items/" ++ String.fromInt id
    , body = Http.emptyBody
    , expect = Http.expectWhatever (\_ -> PerformChecklistDelete id)
    , timeout = Nothing
    , tracker = Nothing
    }