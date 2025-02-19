module Types exposing (..)

import Auth.Common
import Browser exposing (UrlRequest)
import Browser.Navigation exposing (Key)
import Dict exposing (Dict)
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
    , authFlow : Auth.Common.Flow
    , authRedirectBaseUrl : Url
    , login : LoginState
    , currentUser : Maybe UserFrontend
    }


type alias BackendModel =
    { logs : List String
    , pendingAuths : Dict Lamdera.SessionId Auth.Common.PendingAuth
    , sessions : Dict Lamdera.SessionId Auth.Common.UserInfo
    , users : Dict Email User
    }


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
    | GoogleSigninRequested
    | Logout


type ToBackend
    = NoOpToBackend
    | Admin_FetchLogs
    | Admin_ClearLogs
    | Admin_CheckPasswordBackend String
    | Admin_FetchRemoteModel String
    | AuthToBackend Auth.Common.ToBackend
    | GetUserToBackend
    | LoggedOut


type BackendMsg
    = NoOpBackendMsg
    | Log String
    | GotRemoteModel (Result Http.Error BackendModel)
    | AuthBackendMsg Auth.Common.BackendMsg


type ToFrontend
    = NoOpToFrontend
      -- Admin page
    | Admin_Logs_ToFrontend (List String)
    | Admin_LoginResponse Bool
    | AuthToFrontend Auth.Common.ToFrontend
    | AuthSuccess Auth.Common.UserInfo
    | UserInfoMsg (Maybe Auth.Common.UserInfo)
    | UserDataToFrontend UserFrontend


type alias Email =
    String


type alias User =
    { email : Email }


type alias UserFrontend =
    { email : Email }


type LoginState
    = JustArrived
    | NotLogged Bool
    | LoginTokenSent
    | LoggedIn Auth.Common.UserInfo
