module Pages.Funding exposing (..)

import Html exposing (..)
import Html.Attributes as Attr
import Supplemental exposing (..)
import Types exposing (FrontendModel, FrontendMsg(..), FundingRate, ToBackend(..))


init : FrontendModel -> ( FrontendModel, Cmd FrontendMsg )
init model =
    ( model, Supplemental.performNow (DirectToBackend (FetchFundingRates model.symbol)) )


view : FrontendModel -> Html FrontendMsg
view model =
    div [ Attr.class "bg-gray-100 min-h-screen" ]
        [ div [ Attr.class "container mx-auto px-4 py-8" ]
            [ h1 [ Attr.class "text-3xl font-bold mb-4" ]
                [ text ("Funding Rate for " ++ model.symbol) ]
            , viewRates model
            ]
        ]


viewRates : FrontendModel -> Html msg
viewRates model =
    div [ Attr.class "overflow-x-auto" ]
        [ table [ Attr.class "min-w-full bg-white" ]
            [ thead []
                [ tr []
                    [ th [ Attr.class "px-4 py-2 border" ] [ text "Time" ]
                    , th [ Attr.class "px-4 py-2 border" ] [ text "Rate" ]
                    , th [ Attr.class "px-4 py-2 border" ] [ text "Compounded Rate" ]
                    , th [ Attr.class "px-4 py-2 border" ] [ text "Annualized Rate" ]
                    ]
                ]
            , tbody []
                (List.map viewRate model.fundingRates)
            ]
        ]


viewRate : ( FundingRate, Float ) -> Html msg
viewRate ( rate, compoundedRate ) =
    let
        rateFromStr =
            String.toFloat rate.fundingRate |> Maybe.withDefault 0

        formatRate rate_ =
            case formatFloat 6 rate_ of
                Float f ->
                    f

                NaN ->
                    "NaN"

                Infinity ->
                    "Infinity"

        annualizedRate period =
            (1 + compoundedRate) ^ period - 1
    in
    tr []
        [ td [ Attr.class "px-4 py-2 border" ] [ text rate.fundingTime ]
        , td [ Attr.class "px-4 py-2 border" ] [ text (formatRate rateFromStr) ]
        , td [ Attr.class "px-4 py-2 border" ] [ text (formatRate compoundedRate) ]
        , td [ Attr.class "px-4 py-2 border" ] [ text (formatPercent (100 * annualizedRate 2)) ]
        ]
