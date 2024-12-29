module Evergreen.V4.Types exposing (..)

import Browser
import Browser.Dom
import Browser.Navigation
import Evergreen.V4.Fusion
import Evergreen.V4.Fusion.Patch
import Http
import Lamdera
import Lamdera.Debug
import Url


type AdminRoute
    = AdminDefault
    | AdminLogs
    | AdminFetchModel
    | AdminFusion


type alias Pair =
    String


type alias CompoundingPeriod =
    Int


type alias Page =
    Int


type Route
    = Default
    | Admin AdminRoute
    | NotFound
    | Funding Pair CompoundingPeriod Page
    | Heatmap


type alias AdminPageModel =
    { logs : List String
    , isAuthenticated : Bool
    , password : String
    , remoteUrl : String
    }


type alias FundingRate =
    { currencyPair : String
    , fundingRate : String
    , fundingTime : String
    }


type alias AnnualizedRate =
    { fundingRate : FundingRate
    , annualizedRate : Float
    , compoundedRate : Float
    , compoundedAnnualizedRate : Float
    }


type alias FrontendModel =
    { key : Browser.Navigation.Key
    , currentRoute : Route
    , adminPage : AdminPageModel
    , allFundingRates : List FundingRate
    , annualizedFundingRates : List AnnualizedRate
    , paginatedFundingRates : List AnnualizedRate
    , symbol : String
    , days : Int
    , page : Int
    , totalPages : Int
    , viewport : Maybe Browser.Dom.Viewport
    , fundingDaysSlider : Int
    , fusionState : Evergreen.V4.Fusion.Value
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
    | FetchFundingRates String (Maybe String)
    | FetchAllFundingRates
    | Admin_FetchRemoteModel String
    | Fusion_PersistPatch Evergreen.V4.Fusion.Patch.Patch
    | Fusion_Query Evergreen.V4.Fusion.Query


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
    | UpdateFundingDaysSlider Int
    | ApplyFundingDays Int
    | Admin_RemoteUrlChanged String
    | Admin_FusionPatch Evergreen.V4.Fusion.Patch.Patch
    | Admin_FusionQuery Evergreen.V4.Fusion.Query


type alias ConnectionId =
    Lamdera.ClientId


type ToFrontend
    = NoOpToFrontend
    | Admin_Logs_ToFrontend (List String)
    | Admin_LoginResponse Bool
    | FE_GotFundingRates (List FundingRate)
    | Admin_FusionResponse Evergreen.V4.Fusion.Value


type BackendMsg
    = NoOpBackendMsg
    | DirectToFrontend ConnectionId ToFrontend
    | Log String
    | GotRemoteModel (Result Http.Error BackendModel)
    | BE_GotFundingRates Lamdera.Debug.Posix (Result Http.Error ( List String, List FundingRate ))
    | BE_FetchFundingRates Lamdera.Debug.Posix
    | BE_FetchSymbolRates ConnectionId String
