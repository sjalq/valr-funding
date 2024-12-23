module Pages.Heatmap exposing (..)

import Component.Heatmap exposing (viewHeatmap)
import Dict exposing (Dict)
import Dict.Extra as Dict
import Html exposing (..)
import Html.Attributes as Attr
import Supplemental exposing (..)
import Types exposing (..)


init : FrontendModel -> ( FrontendModel, Cmd FrontendMsg )
init model =
    ( model
    , Cmd.batch
        [ performNow (DirectToBackend FetchAllFundingRates)
        ]
    )


view : FrontendModel -> Html FrontendMsg
view model =
    div [ Attr.class "bg-gray-100 min-h-screen" ]
        [ div [ Attr.class "container mx-auto px-4 py-8" ]
            [ h1 [ Attr.class "text-3xl font-bold mb-4" ]
                [ text "Funding Rate Heatmap" ]
            , viewHeatmap model.viewport (fundingToDict model.allFundingRates)
            ]
        ]


fundingToDict : List FundingRate -> Dict String (List FundingRate)
fundingToDict rates =
    Dict.groupBy .currencyPair rates
        |> Debug.log "Rates"
