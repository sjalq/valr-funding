module Pages.PageFrame exposing (..)

import Html exposing (..)
import Html.Attributes as Attr
import Pages.Admin
import Pages.Default
import Route exposing (..)
import Types exposing (..)


viewTabs : FrontendModel -> Html FrontendMsg
viewTabs model =
    div [ Attr.class "flex justify-center mb-5" ]
        [ viewTab "Default" Default model.currentRoute
        , viewTab "Admin" (Admin AdminDefault) model.currentRoute
        ]


viewTab : String -> Route -> Route -> Html FrontendMsg
viewTab label page currentPage =
    a
        [ Attr.href (Route.toString page)
        , Attr.classList
            [ ( "px-4 py-2 mx-2 border cursor-pointer", True )
            , ( "bg-gray-300", page == currentPage )
            , ( "bg-white", page /= currentPage )
            ]
        ]
        [ text label ]


viewCurrentPage : FrontendModel -> Html FrontendMsg
viewCurrentPage model =
    case model.currentRoute of
        Default ->
            Pages.Default.view model

        Admin adminRoute ->
            Pages.Admin.view model

        NotFound ->
            viewNotFoundPage


viewNotFoundPage : Html FrontendMsg
viewNotFoundPage =
    div [ Attr.class "text-center p-4" ]
        [ text "404 - Page Not Found" ]
