module Backend exposing (..)

import Env
import Lamdera
import Supplemental exposing (..)
import SupplementalRPC
import Task
import Types exposing (..)


type alias Model =
    BackendModel


app =
    Lamdera.backend
        { init = init
        , update = update
        , updateFromFrontend = updateFromFrontend
        , subscriptions = \m -> Sub.none
        }


init : ( Model, Cmd BackendMsg )
init =
    ( { logs = []
      }
    , Cmd.none
    )


update : BackendMsg -> Model -> ( Model, Cmd BackendMsg )
update msg model =
    case msg of
        NoOpBackendMsg ->
            ( model, Cmd.none )

        Log logMsg ->
            ( model, Cmd.none )
                |> log logMsg

        GotRemoteModel result ->
            case result of
                Ok model_ ->
                    ( model_, Cmd.none )
                        |> log "GotRemoteModel Ok"

                Err err ->
                    ( model, Cmd.none )
                        |> log ("GotRemoteModel Err: " ++ httpErrorToString err)


updateFromFrontend : BrowserCookie -> ConnectionId -> ToBackend -> Model -> ( Model, Cmd BackendMsg )
updateFromFrontend browserCookie connectionId msg model =
    case msg of
        NoOpToBackend ->
            ( model, Cmd.none )

        Admin_FetchLogs ->
            ( model, Lamdera.sendToFrontend connectionId (Admin_Logs_ToFrontend model.logs) )

        Admin_ClearLogs ->
            let
                newModel =
                    { model | logs = [] }
            in
            ( newModel, Lamdera.sendToFrontend connectionId (Admin_Logs_ToFrontend newModel.logs) )

        Admin_CheckPasswordBackend password ->
            ( model
            , if password == Env.modelKey then
                Lamdera.sendToFrontend connectionId (Admin_LoginResponse True)

              else
                Lamdera.sendToFrontend connectionId (Admin_LoginResponse False)
            )

        Admin_FetchRemoteModel remoteUrl ->
            ( model
              -- put your production model key in here to fetch from your prod env.
            , SupplementalRPC.fetchImportedModel remoteUrl "1234567890" Types.w3_decode_BackendModel
                |> Task.attempt GotRemoteModel
            )


log =
    Supplemental.log NoOpBackendMsg
