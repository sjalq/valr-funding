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


type alias Pair =
    String


type alias Page =
    Int


type alias CompoundingPeriod =
    Int


type Route
    = Default
    | Admin AdminRoute
    | NotFound
    | Funding Pair CompoundingPeriod Page
    | Heatmap


type AdminRoute
    = AdminDefault
    | AdminLogs
    | AdminFetchModel


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
    { key : Key
    , currentRoute : Route
    , adminPage : AdminPageModel
    , allFundingRates : List FundingRate
    , annualizedFundingRates : List AnnualizedRate
    , paginatedFundingRates : List AnnualizedRate
    , symbol : String
    , days : Int
    , page : Int
    , totalPages : Int
    , viewport : Maybe Viewport
    , fundingDaysSlider : Int
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
      --- Admin
    | Admin_PasswordOnChange String
    | Admin_SubmitPassword
    | GetViewport
    | GotViewport Browser.Dom.Viewport
    | UpdateFundingDaysSlider Int
    | ApplyFundingDays Int
    | Admin_RemoteUrlChanged String


type ToBackend
    = NoOpToBackend
      --- Admin ---
    | Admin_FetchLogs
    | Admin_ClearLogs
    | Admin_CheckPasswordBackend String
    | Admin_TriggerFundingRatesFetch
      ---
    | FetchFundingRates String (Maybe String)
    | FetchAllFundingRates
    | Admin_FetchRemoteModel String


type BackendMsg
    = NoOpBackendMsg
    | DirectToFrontend ConnectionId ToFrontend
    | Log String
    | GotRemoteModel (Result Http.Error BackendModel)
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
