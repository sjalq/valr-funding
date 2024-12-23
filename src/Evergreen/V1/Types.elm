module Evergreen.V1.Types exposing (..)

import Browser
import Browser.Navigation
import Http
import Lamdera
import Lamdera.Debug
import Url


type AdminRoute
    = AdminDefault
    | AdminLogs


type Route
    = Default
    | Admin AdminRoute
    | NotFound
    | Funding String


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
    { key : Browser.Navigation.Key
    , currentRoute : Route
    , adminPage : AdminPageModel
    , fundingRates : List ( FundingRate, Float )
    , symbol : String
    }


type alias BackendModel =
    { logs : List String
    , rates : List FundingRate
    , symbols : List String
    }


type ToBackend
    = NoOpToBackend
    | Admin_FetchLogs
    | Admin_ClearLogs
    | Admin_CheckPasswordBackend String
    | Admin_TriggerFundingRatesFetch
    | FetchFundingRates String


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | UrlRequested Browser.UrlRequest
    | NoOpFrontendMsg
    | DirectToBackend ToBackend
    | Admin_PasswordOnChange String
    | Admin_SubmitPassword


type alias ConnectionId =
    Lamdera.ClientId


type ToFrontend
    = NoOpToFrontend
    | Admin_Logs_ToFrontend (List String)
    | Admin_LoginResponse Bool
    | FE_GotFundingRates (List ( FundingRate, Float ))


type BackendMsg
    = NoOpBackendMsg
    | DirectToFrontend ConnectionId ToFrontend
    | Log String
    | BE_GotFundingRates Lamdera.Debug.Posix (Result Http.Error ( List String, List FundingRate ))
    | BE_FetchFundingRates Lamdera.Debug.Posix
