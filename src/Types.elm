module Types exposing (..)

import Browser exposing (UrlRequest)
import Browser.Dom exposing (Viewport)
import Browser.Navigation exposing (Key)
import Http
import Lamdera exposing (ClientId, SessionId)
import Lamdera.Debug exposing (Posix)
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
    | Funding String
    | Heatmap


type AdminRoute
    = AdminDefault
    | AdminLogs


type alias AdminPageModel =
    { logs : List String
    , isAuthenticated : Bool
    , password : String
    }


type alias FundingRate =
    { currencyPair : String
    , fundingRate : String
    , fundingTime : String
    }


type alias FrontendModel =
    { key : Key
    , currentRoute : Route
    , adminPage : AdminPageModel
    , fundingRates : List ( FundingRate, Float )
    , allFundingRates : List FundingRate
    , symbol : String
    , viewport : Maybe Viewport
    }


type alias BackendModel =
    { logs : List String
    , rates : List FundingRate
    , symbols : List String
    }


type FrontendMsg
    = UrlClicked UrlRequest
    | UrlChanged Url
    | UrlRequested UrlRequest
    | NoOpFrontendMsg
    | DirectToBackend ToBackend
    | Admin_PasswordOnChange String
    | Admin_SubmitPassword
    | GetViewport
    | GotViewport Browser.Dom.Viewport


type ToBackend
    = NoOpToBackend
      --- Admin ---
    | Admin_FetchLogs
    | Admin_ClearLogs
    | Admin_CheckPasswordBackend String
    | Admin_TriggerFundingRatesFetch
      ---
    | FetchFundingRates String
    | FetchAllFundingRates


type BackendMsg
    = NoOpBackendMsg
    | DirectToFrontend ConnectionId ToFrontend
    | Log String
      ----------
    | BE_GotFundingRates Posix (Result Http.Error ( List String, List FundingRate ))
    | BE_FetchFundingRates Posix
    | BE_FetchSymbolRates ConnectionId String


type ToFrontend
    = NoOpToFrontend
      -- Admin page
    | Admin_Logs_ToFrontend (List String)
    | Admin_LoginResponse Bool
    | FE_GotFundingRates (List FundingRate)
    | FE_GotCompoundedRates (List ( FundingRate, Float ))
