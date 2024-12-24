module Evergreen.V3.Types exposing (..)

import Browser
import Browser.Dom
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
    | Heatmap


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
    , allFundingRates : List FundingRate
    , symbol : String
    , viewport : Maybe Browser.Dom.Viewport
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
    | FetchAllFundingRates


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | UrlRequested Browser.UrlRequest
    | NoOpFrontendMsg
    | DirectToBackend ToBackend
    | Admin_PasswordOnChange String
    | Admin_SubmitPassword
    | GetViewport
    | GotViewport Browser.Dom.Viewport


type alias ConnectionId =
    Lamdera.ClientId


type ToFrontend
    = NoOpToFrontend
    | Admin_Logs_ToFrontend (List String)
    | Admin_LoginResponse Bool
    | FE_GotFundingRates (List FundingRate)
    | FE_GotCompoundedRates (List ( FundingRate, Float ))


type BackendMsg
    = NoOpBackendMsg
    | DirectToFrontend ConnectionId ToFrontend
    | Log String
    | BE_GotFundingRates Lamdera.Debug.Posix (Result Http.Error ( List String, List FundingRate ))
    | BE_FetchFundingRates Lamdera.Debug.Posix
    | BE_FetchSymbolRates ConnectionId String
