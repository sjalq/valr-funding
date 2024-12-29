module Evergreen.Migrate.V4 exposing (..)

{-| This migration file was automatically generated by the lamdera compiler.

It includes:

  - A migration for each of the 6 Lamdera core types that has changed
  - A function named `migrate_ModuleName_TypeName` for each changed/custom type

Expect to see:

  - `Unimplementеd` values as placeholders wherever I was unable to figure out a clear migration path for you
  - `@NOTICE` comments for things you should know about, i.e. new custom type constructors that won't get any
    value mappings from the old type by default

You can edit this file however you wish! It won't be generated again.

See <https://dashboard.lamdera.app/docs/evergreen> for more info.

-}

import Evergreen.V3.Types
import Evergreen.V4.Types
import Fusion
import Lamdera.Migrations exposing (..)


frontendModel : Evergreen.V3.Types.FrontendModel -> ModelMigration Evergreen.V4.Types.FrontendModel Evergreen.V4.Types.FrontendMsg
frontendModel old =
    ModelMigrated ( migrate_Types_FrontendModel old, Cmd.none )


backendModel : Evergreen.V3.Types.BackendModel -> ModelMigration Evergreen.V4.Types.BackendModel Evergreen.V4.Types.BackendMsg
backendModel old =
    ModelUnchanged


frontendMsg : Evergreen.V3.Types.FrontendMsg -> MsgMigration Evergreen.V4.Types.FrontendMsg Evergreen.V4.Types.FrontendMsg
frontendMsg old =
    MsgMigrated ( migrate_Types_FrontendMsg old, Cmd.none )


toBackend : Evergreen.V3.Types.ToBackend -> MsgMigration Evergreen.V4.Types.ToBackend Evergreen.V4.Types.BackendMsg
toBackend old =
    MsgMigrated ( migrate_Types_ToBackend old, Cmd.none )


backendMsg : Evergreen.V3.Types.BackendMsg -> MsgMigration Evergreen.V4.Types.BackendMsg Evergreen.V4.Types.BackendMsg
backendMsg old =
    MsgMigrated ( migrate_Types_BackendMsg old, Cmd.none )


toFrontend : Evergreen.V3.Types.ToFrontend -> MsgMigration Evergreen.V4.Types.ToFrontend Evergreen.V4.Types.FrontendMsg
toFrontend old =
    MsgMigrated ( migrate_Types_ToFrontend old, Cmd.none )


migrate_Types_FrontendModel : Evergreen.V3.Types.FrontendModel -> Evergreen.V4.Types.FrontendModel
migrate_Types_FrontendModel old =
    { key = old.key
    , currentRoute = old.currentRoute |> migrate_Types_Route
    , adminPage = old.adminPage |> migrate_Types_AdminPageModel
    , allFundingRates = old.allFundingRates
    , annualizedFundingRates = []
    , paginatedFundingRates = []
    , symbol = old.symbol
    , days = 90
    , page = 1
    , totalPages = 1
    , viewport = old.viewport
    , fundingDaysSlider = 90
    , fusionState = Fusion.Value.VUnloaded
    }


migrate_Types_AdminPageModel : Evergreen.V3.Types.AdminPageModel -> Evergreen.V4.Types.AdminPageModel
migrate_Types_AdminPageModel old =
    { logs = old.logs
    , isAuthenticated = old.isAuthenticated
    , password = old.password
    , remoteUrl = ""
    }


migrate_Types_AdminRoute : Evergreen.V3.Types.AdminRoute -> Evergreen.V4.Types.AdminRoute
migrate_Types_AdminRoute old =
    case old of
        Evergreen.V3.Types.AdminDefault ->
            Evergreen.V4.Types.AdminDefault

        Evergreen.V3.Types.AdminLogs ->
            Evergreen.V4.Types.AdminLogs



migrate_Types_BackendMsg : Evergreen.V3.Types.BackendMsg -> Evergreen.V4.Types.BackendMsg
migrate_Types_BackendMsg old =
    case old of
        Evergreen.V3.Types.NoOpBackendMsg ->
            Evergreen.V4.Types.NoOpBackendMsg

        Evergreen.V3.Types.DirectToFrontend p0 p1 ->
            Evergreen.V4.Types.DirectToFrontend p0 (p1 |> migrate_Types_ToFrontend)

        Evergreen.V3.Types.Log p0 ->
            Evergreen.V4.Types.Log p0

        Evergreen.V3.Types.BE_GotFundingRates p0 p1 ->
            Evergreen.V4.Types.BE_GotFundingRates p0 p1

        Evergreen.V3.Types.BE_FetchFundingRates p0 ->
            Evergreen.V4.Types.BE_FetchFundingRates p0

        Evergreen.V3.Types.BE_FetchSymbolRates p0 p1 ->
            Evergreen.V4.Types.BE_FetchSymbolRates p0 p1


migrate_Types_FrontendMsg : Evergreen.V3.Types.FrontendMsg -> Evergreen.V4.Types.FrontendMsg
migrate_Types_FrontendMsg old =
    case old of
        Evergreen.V3.Types.UrlClicked p0 ->
            Evergreen.V4.Types.UrlClicked p0

        Evergreen.V3.Types.UrlChanged p0 ->
            Evergreen.V4.Types.UrlChanged p0

        Evergreen.V3.Types.UrlRequested p0 ->
            Evergreen.V4.Types.UrlRequested p0

        Evergreen.V3.Types.NoOpFrontendMsg ->
            Evergreen.V4.Types.NoOpFrontendMsg

        Evergreen.V3.Types.DirectToBackend p0 ->
            Evergreen.V4.Types.DirectToBackend (p0 |> migrate_Types_ToBackend)

        Evergreen.V3.Types.Admin_PasswordOnChange p0 ->
            Evergreen.V4.Types.Admin_PasswordOnChange p0

        Evergreen.V3.Types.Admin_SubmitPassword ->
            Evergreen.V4.Types.Admin_SubmitPassword

        Evergreen.V3.Types.GetViewport ->
            Evergreen.V4.Types.GetViewport

        Evergreen.V3.Types.GotViewport p0 ->
            Evergreen.V4.Types.GotViewport p0


migrate_Types_Route : Evergreen.V3.Types.Route -> Evergreen.V4.Types.Route
migrate_Types_Route old =
    case old of
        Evergreen.V3.Types.Default ->
            Evergreen.V4.Types.Default

        Evergreen.V3.Types.Admin p0 ->
            Evergreen.V4.Types.Admin (p0 |> migrate_Types_AdminRoute)

        Evergreen.V3.Types.NotFound ->
            Evergreen.V4.Types.NotFound

        Evergreen.V3.Types.Funding p0 ->
            Evergreen.V4.Types.Default

        Evergreen.V3.Types.Heatmap ->
            Evergreen.V4.Types.Heatmap


migrate_Types_ToBackend : Evergreen.V3.Types.ToBackend -> Evergreen.V4.Types.ToBackend
migrate_Types_ToBackend old =
    case old of
        Evergreen.V3.Types.NoOpToBackend ->
            Evergreen.V4.Types.NoOpToBackend

        Evergreen.V3.Types.Admin_FetchLogs ->
            Evergreen.V4.Types.Admin_FetchLogs

        Evergreen.V3.Types.Admin_ClearLogs ->
            Evergreen.V4.Types.Admin_ClearLogs

        Evergreen.V3.Types.Admin_CheckPasswordBackend p0 ->
            Evergreen.V4.Types.Admin_CheckPasswordBackend p0

        Evergreen.V3.Types.Admin_TriggerFundingRatesFetch ->
            Evergreen.V4.Types.Admin_TriggerFundingRatesFetch

        Evergreen.V3.Types.FetchFundingRates p0 ->
            Evergreen.V4.Types.NoOpToBackend

        Evergreen.V3.Types.FetchAllFundingRates ->
            Evergreen.V4.Types.FetchAllFundingRates


migrate_Types_ToFrontend : Evergreen.V3.Types.ToFrontend -> Evergreen.V4.Types.ToFrontend
migrate_Types_ToFrontend old =
    case old of
        Evergreen.V3.Types.NoOpToFrontend ->
            Evergreen.V4.Types.NoOpToFrontend

        Evergreen.V3.Types.Admin_Logs_ToFrontend p0 ->
            Evergreen.V4.Types.Admin_Logs_ToFrontend p0

        Evergreen.V3.Types.Admin_LoginResponse p0 ->
            Evergreen.V4.Types.Admin_LoginResponse p0

        Evergreen.V3.Types.FE_GotFundingRates p0 ->
            Evergreen.V4.Types.FE_GotFundingRates p0

        Evergreen.V3.Types.FE_GotCompoundedRates p0 ->
            Evergreen.V4.Types.NoOpToFrontend
