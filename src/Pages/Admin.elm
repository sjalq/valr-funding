module Pages.Admin exposing (..)

import Env
import Html exposing (..)
import Html.Attributes as Attr
import Html.Events exposing (onClick)
import Lamdera
import Types exposing (..)


init : FrontendModel -> AdminRoute -> ( FrontendModel, Cmd FrontendMsg )
init model adminRoute =
    if Env.stillTesting == "1" then
        ( { model | adminPage = { isAuthenticated = True, password = "", logs = model.adminPage.logs } }
        , case adminRoute of
            AdminLogs ->
                Lamdera.sendToBackend Admin_FetchLogs

            _ ->
                Cmd.none
        )

    else
        case ( model.adminPage.isAuthenticated, adminRoute ) of
            ( True, AdminLogs ) ->
                ( model, Lamdera.sendToBackend Admin_FetchLogs )

            _ ->
                ( model, Cmd.none )


view : FrontendModel -> Html FrontendMsg
view model =
    if not model.adminPage.isAuthenticated then
        viewLogin model

    else
        div [ Attr.class "bg-gray-100 min-h-screen" ]
            [ div [ Attr.class "container mx-auto px-4 py-8" ]
                [ h1 [ Attr.class "text-3xl font-bold mb-4" ]
                    [ text "Admin Page" ]
                , viewTabs model
                , viewTabContent model
                ]
            ]


viewTabs : FrontendModel -> Html FrontendMsg
viewTabs model =
    div [ Attr.class "flex border-b border-gray-200 mb-4" ]
        [ viewTab AdminDefault model "Default"
        , viewTab AdminLogs model "Logs"
        ]


viewTab : AdminRoute -> FrontendModel -> String -> Html FrontendMsg
viewTab tab model label =
    let
        activeClass =
            if Admin tab == model.currentRoute then
                "border-b-2 border-blue-500 text-blue-600"

            else
                "text-gray-600"

        route =
            case tab of
                AdminDefault ->
                    "/admin"

                AdminLogs ->
                    "/admin/logs"
    in
    a
        [ Attr.href route
        , Attr.class ("py-2 px-4 " ++ activeClass)
        ]
        [ text label ]


viewTabContent : FrontendModel -> Html FrontendMsg
viewTabContent model =
    case model.currentRoute of
        Admin AdminDefault ->
            viewDefaultTab model

        Admin AdminLogs ->
            viewLogsTab model

        _ ->
            text "Not found"


viewDefaultTab : FrontendModel -> Html FrontendMsg
viewDefaultTab model =
    div []
        [ text "Default admin content"
        , div [ Attr.class "mt-4" ]
            [ button
                [ onClick (DirectToBackend Admin_TriggerFundingRatesFetch)
                , Attr.class "bg-blue-500 hover:bg-blue-600 text-white px-4 py-2 rounded"
                ]
                [ text "Trigger Funding Rates Fetch" ]
            ]
        ]


viewLogsTab : FrontendModel -> Html FrontendMsg
viewLogsTab model =
    div [ Attr.class "bg-black text-yellow-100 font-mono p-4 rounded" ]
        [ div [ Attr.class "flex justify-between items-center mb-4" ]
            [ h2 [ Attr.class "text-xl" ] [ text "System Logs" ]
            , button
                [ onClick (DirectToBackend Admin_ClearLogs)
                , Attr.class "bg-red-500 hover:bg-red-600 text-white px-3 py-1 rounded"
                ]
                [ text "Clear Logs" ]
            ]
        , div [ Attr.class "space-y-1" ]
            (model.adminPage.logs
                |> List.reverse
                |> List.indexedMap viewLogEntry
            )
        ]


viewLogEntry : Int -> String -> Html FrontendMsg
viewLogEntry index log =
    div []
        [ span [ Attr.class "pr-2" ] [ text (String.fromInt index) ]
        , span [ Attr.class "text-green-200" ] [ text log ]
        ]


viewLogin : FrontendModel -> Html FrontendMsg
viewLogin model =
    div [ Attr.class "min-h-screen flex items-center justify-center bg-gray-100" ]
        [ div [ Attr.class "bg-white p-8 rounded-lg shadow-md w-96" ]
            [ h2 [ Attr.class "text-2xl font-bold mb-4" ] [ text "Admin Login" ]
            , input
                [ Attr.type_ "password"
                , Attr.placeholder "Enter admin password"
                , Attr.value model.adminPage.password
                , Html.Events.onInput Admin_PasswordOnChange
                , Attr.class "w-full px-3 py-2 border rounded mb-4"
                ]
                []
            , button
                [ onClick Admin_SubmitPassword
                , Attr.class "w-full bg-blue-500 text-white py-2 px-4 rounded hover:bg-blue-600"
                ]
                [ text "Login" ]
            ]
        ]
