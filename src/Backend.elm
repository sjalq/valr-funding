module Backend exposing (..)

import Auth.Common
import Auth.Flow
import Auth.Method.EmailMagicLink
import Auth.Method.OAuthGithub
import Auth.Method.OAuthGoogle
import Dict exposing (Dict)
import Env
import Lamdera
import RPC
import Supplemental exposing (..)
import Task
import Time exposing (Posix)
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
      , pendingAuths = Dict.empty
      , sessions = Dict.empty
      , users = Dict.empty
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

        AuthBackendMsg authMsg ->
            Auth.Flow.backendUpdate (backendConfig model) authMsg


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

        AuthToBackend authToBackend ->
            Auth.Flow.updateFromFrontend (backendConfig model) connectionId browserCookie authToBackend model

        GetUserToBackend ->
            case Dict.get browserCookie model.sessions of
                Just userInfo ->
                    case Dict.get userInfo.email model.users of
                        Just user ->
                            ( model, Cmd.batch [ Lamdera.sendToFrontend connectionId <| UserInfoMsg <| Just userInfo, Lamdera.sendToFrontend connectionId <| UserDataToFrontend <| userToFrontend user ] )

                        Nothing ->
                            let
                                user =
                                    createUser userInfo

                                newModel =
                                    insertUser userInfo.email user model
                            in
                            ( newModel, Cmd.batch [ Lamdera.sendToFrontend connectionId <| UserInfoMsg <| Just userInfo, Lamdera.sendToFrontend connectionId <| UserDataToFrontend <| userToFrontend user ] )

                Nothing ->
                    ( model, Lamdera.sendToFrontend connectionId <| UserInfoMsg Nothing )

        LoggedOut ->
            ( { model | sessions = Dict.remove browserCookie model.sessions }, Cmd.none )


log =
    Supplemental.log NoOpBackendMsg


renewSession : Lamdera.SessionId -> Lamdera.ClientId -> BackendModel -> ( BackendModel, Cmd BackendMsg )
renewSession _ _ model =
    ( model, Cmd.none )


handleAuthSuccess : BackendModel -> Lamdera.SessionId -> Lamdera.ClientId -> Auth.Common.UserInfo -> Auth.Common.MethodId -> Maybe Auth.Common.Token -> Time.Posix -> ( BackendModel, Cmd BackendMsg )
handleAuthSuccess backendModel sessionId clientId userInfo _ _ _ =
    let
        sessionsWithOutThisOne : Dict Lamdera.SessionId Auth.Common.UserInfo
        sessionsWithOutThisOne =
            Dict.filter (\_ { email } -> email /= userInfo.email) backendModel.sessions

        newSessions =
            Dict.insert sessionId userInfo sessionsWithOutThisOne

        response =
            AuthSuccess userInfo
    in
    ( { backendModel | sessions = newSessions }, Cmd.batch [ Lamdera.sendToFrontend clientId response ] )


logout : Lamdera.SessionId -> Lamdera.ClientId -> BackendModel -> ( BackendModel, Cmd msg )
logout sessionId _ model =
    ( { model | sessions = model.sessions |> Dict.remove sessionId }, Cmd.none )


backendConfig : BackendModel -> Auth.Flow.BackendUpdateConfig FrontendMsg BackendMsg ToFrontend FrontendModel BackendModel
backendConfig model =
    { asToFrontend = AuthToFrontend
    , asBackendMsg = AuthBackendMsg
    , sendToFrontend = Lamdera.sendToFrontend
    , backendModel = model
    , loadMethod = Auth.Flow.methodLoader config.methods
    , handleAuthSuccess = handleAuthSuccess model
    , isDev = True
    , renewSession = renewSession
    , logout = logout
    }


config : Auth.Common.Config FrontendMsg ToBackend BackendMsg ToFrontend FrontendModel BackendModel
config =
    { toBackend = AuthToBackend
    , toFrontend = AuthToFrontend
    , backendMsg = AuthBackendMsg
    , sendToFrontend = Lamdera.sendToFrontend
    , sendToBackend = Lamdera.sendToBackend
    , renewSession = renewSession
    , methods = [ Auth.Method.OAuthGoogle.configuration Env.googleAppClientId Env.googleAppClientSecret ]
    }


createUser : Auth.Common.UserInfo -> User
createUser userInfo =
    { email = userInfo.email }


userToFrontend : User -> UserFrontend
userToFrontend user =
    { email = user.email }


insertUser : Email -> User -> BackendModel -> BackendModel
insertUser email newUser model =
    { model | users = Dict.insert email newUser model.users }
