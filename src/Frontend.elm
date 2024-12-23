module Frontend exposing (..)

import Browser exposing (UrlRequest(..))
import Browser.Dom exposing (Viewport)
import Browser.Events
import Browser.Navigation as Nav
import Html exposing (..)
import Lamdera
import Pages.Admin
import Pages.Default
import Pages.Funding
import Pages.Heatmap
import Pages.PageFrame exposing (viewCurrentPage, viewTabs)
import Route exposing (..)
import Supplemental exposing (..)
import Task
import Time exposing (..)
import Types exposing (..)
import Url exposing (Url)


type alias Model =
    FrontendModel


app =
    Lamdera.frontend
        { init = init
        , onUrlRequest = UrlClicked
        , onUrlChange = UrlChanged
        , update = update
        , updateFromBackend = updateFromBackend
        , subscriptions = subscriptions
        , view = view
        }


subscriptions : FrontendModel -> Sub FrontendMsg
subscriptions model =
    Sub.batch
        [ Browser.Events.onResize
            (\width height ->
                GotViewport
                    { scene = { width = 0, height = 0 }
                    , viewport = { x = 0, y = 0, width = toFloat width, height = toFloat height }
                    }
            )
        ]


init : Url -> Nav.Key -> ( FrontendModel, Cmd FrontendMsg )
init url key =
    let
        route =
            Route.fromUrl url

        model =
            { key = key
            , currentRoute = route
            , adminPage =
                { logs = []
                , isAuthenticated = False
                , password = ""
                }
            , fundingRates = []
            , allFundingRates = []
            , symbol = ""
            , viewport = Nothing
            }
    in
    inits model route
        |> Tuple.mapSecond (\cmd -> Cmd.batch [ cmd, Task.perform GotViewport Browser.Dom.getViewport ])


inits : Model -> Route -> ( Model, Cmd FrontendMsg )
inits model route =
    case route of
        Admin adminRoute ->
            Pages.Admin.init model adminRoute

        Default ->
            Pages.Default.init model

        Funding symbol ->
            Pages.Funding.init { model | symbol = symbol }

        Heatmap ->
            Pages.Heatmap.init model

        _ ->
            ( model, Cmd.none )


update : FrontendMsg -> Model -> ( Model, Cmd FrontendMsg )
update msg model =
    case msg of
        NoOpFrontendMsg ->
            ( model, Cmd.none )

        UrlRequested urlRequest ->
            case urlRequest of
                Internal url ->
                    ( model
                    , Nav.pushUrl model.key (Url.toString url)
                    )

                External url ->
                    ( model
                    , Nav.load url
                    )

        UrlClicked urlRequest ->
            case urlRequest of
                Internal url ->
                    ( model
                    , Nav.pushUrl model.key (Url.toString url)
                    )

                External url ->
                    ( model
                    , Nav.load url
                    )

        UrlChanged url ->
            let
                newModel =
                    { model | currentRoute = Route.fromUrl url }
            in
            inits newModel newModel.currentRoute

        DirectToBackend msg_ ->
            ( model, Lamdera.sendToBackend msg_ )

        GetViewport ->
            ( model, Task.perform GotViewport Browser.Dom.getViewport )

        GotViewport viewport ->
            ( { model | viewport = Just viewport }
            , Cmd.none
            )

        Admin_PasswordOnChange password ->
            let
                oldAdminPage =
                    model.adminPage
            in
            ( { model | adminPage = { oldAdminPage | password = password } }, Cmd.none )

        Admin_SubmitPassword ->
            ( model, Lamdera.sendToBackend (Admin_CheckPasswordBackend model.adminPage.password) )


updateFromBackend : ToFrontend -> Model -> ( Model, Cmd FrontendMsg )
updateFromBackend msg model =
    case msg of
        NoOpToFrontend ->
            ( model, Cmd.none )

        -- Admin page
        Admin_Logs_ToFrontend logs ->
            let
                oldAdminPage =
                    model.adminPage
            in
            ( { model | adminPage = { oldAdminPage | logs = logs } }, Cmd.none )

        Admin_LoginResponse isAuthenticated ->
            let
                oldAdminPage =
                    model.adminPage
            in
            ( { model | adminPage = { oldAdminPage | isAuthenticated = isAuthenticated } }, Cmd.none )

        FE_GotFundingRates rates ->
            ( { model | allFundingRates = model.allFundingRates ++ rates }, Cmd.none )


view : Model -> Browser.Document FrontendMsg
view model =
    { title = "Dashboard"
    , body =
        [ viewTabs model
        , viewCurrentPage model
        ]
    }
