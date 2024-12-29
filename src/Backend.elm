module Backend exposing (..)

import Env
import Fusion.Generated.Types
import Fusion.Patch
import Lamdera
import RPC
import Supplemental exposing (..)
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
            , RPC.fetchImportedModel remoteUrl "1234567890"
                |> Task.attempt GotRemoteModel
            )

        Fusion_PersistPatch patch ->
            let
                value =
                    Fusion.Patch.patch { force = False } patch (Fusion.Generated.Types.toValue_BackendModel model)
                        |> Result.withDefault (Fusion.Generated.Types.toValue_BackendModel model)
            in
            case
                Fusion.Generated.Types.build_BackendModel value
            of
                Ok newModel ->
                    ( newModel
                      -- , Lamdera.sendToFrontend connectionId (Admin_FusionResponse value)
                    , Cmd.none
                    )

                Err err ->
                    ( model
                    , Cmd.none
                    )
                        |> log ("Failed to apply fusion patch: " ++ Debug.toString err)

        Fusion_Query query ->
            ( model
            , Lamdera.sendToFrontend connectionId (Admin_FusionResponse (Fusion.Generated.Types.toValue_BackendModel model))
            )


log =
    Supplemental.log NoOpBackendMsg
