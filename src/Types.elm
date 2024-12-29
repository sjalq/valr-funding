module Types exposing (..)

import Browser exposing (UrlRequest)
import Browser.Navigation exposing (Key)
import Fusion
import Fusion.Patch
import Http
import Lamdera exposing (ClientId, SessionId)
import Url exposing (Url)



{- Represents a currently connection to a Lamdera client -}


type alias ConnectionId =
    Lamdera.ClientId



{- Represents the browser cookie Lamdera uses to identify a browser -}


type alias BrowserCookie =
    Lamdera.SessionId


type Route
    = Default
    | Admin AdminRoute
    | NotFound


type AdminRoute
    = AdminDefault
    | AdminLogs
    | AdminFetchModel
    | AdminFusion


type alias AdminPageModel =
    { logs : List String
    , isAuthenticated : Bool
    , password : String
    , remoteUrl : String
    }


type alias FrontendModel =
    { key : Key
    , currentRoute : Route
    , adminPage : AdminPageModel
    , fusionState : Fusion.Value
    }


type alias BackendModel =
    { logs : List String }


type FrontendMsg
    = UrlClicked UrlRequest
    | UrlChanged Url
    | UrlRequested UrlRequest
    | NoOpFrontendMsg
    | DirectToBackend ToBackend
      --- Admin
    | Admin_PasswordOnChange String
    | Admin_SubmitPassword
    | Admin_RemoteUrlChanged String
    | Admin_FusionPatch Fusion.Patch.Patch
    | Admin_FusionQuery Fusion.Query


type ToBackend
    = NoOpToBackend
    | Admin_FetchLogs
    | Admin_ClearLogs
    | Admin_CheckPasswordBackend String
    | Admin_FetchRemoteModel String
    | Fusion_PersistPatch Fusion.Patch.Patch
    | Fusion_Query Fusion.Query


type BackendMsg
    = NoOpBackendMsg
    | Log String
    | GotRemoteModel (Result Http.Error BackendModel)


type ToFrontend
    = NoOpToFrontend
      -- Admin page
    | Admin_Logs_ToFrontend (List String)
    | Admin_LoginResponse Bool
    | Admin_FusionResponse Fusion.Value
