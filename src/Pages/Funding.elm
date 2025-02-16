module Pages.Funding exposing (..)

import Funding exposing (..)
import Html exposing (..)
import Html.Attributes as Attr
import Html.Events exposing (onInput)
import Iso8601
import Supplemental exposing (..)
import Task
import Time
import Types exposing (..)


init : FrontendModel -> ( FrontendModel, Cmd FrontendMsg )
init model =
    let
        latestDateStr =
            model.allFundingRates
                |> List.map .fundingTime
                |> List.maximum
                |> Maybe.andThen (Iso8601.toTime >> Result.toMaybe >> Maybe.map Iso8601.fromTime)
                |> Maybe.withDefault "1970-01-01T00:00:00Z"

        old =
            Time.now
                |> Task.map
                    (\t ->
                        let
                            _ =
                                Debug.log "t" ( Time.posixToMillis t - hour |> Time.millisToPosix |> Iso8601.fromTime, latestDateStr )
                        in
                        (Time.posixToMillis t - hour |> Time.millisToPosix |> Iso8601.fromTime) > latestDateStr
                    )

        annualizedFundingRates =
            model.allFundingRates
                |> Debug.log "allFundingRates"
                |> List.filter (\r -> r.currencyPair == model.symbol)
                |> Funding.compoundRates (model.days * 24)
                |> Debug.log "annualizedFundingRates"

        paginatedFundingRates =
            annualizedFundingRates
                |> List.drop ((model.page - 1) * itemsPerPage)
                |> List.take itemsPerPage
                |> Debug.log "paginatedFundingRates"

        totalPages =
            ceiling (toFloat (List.length annualizedFundingRates) / toFloat itemsPerPage)
                |> Debug.log "totalPages"

        newModel =
            { model
                | annualizedFundingRates = annualizedFundingRates
                , paginatedFundingRates = paginatedFundingRates
                , totalPages = totalPages
            }
    in
    ( newModel, Cmd.batch [ performNow (DirectToBackend (FetchFundingRates model.symbol)) ] )


init2 : FrontendModel -> ( FrontendModel, Cmd FrontendMsg )
init2 model =
    -- if we got the data, calculate the avgs
    -- if we aint got the data, fetch the data, but then trigger whatever triggered this again so we can get the avgs
    if model.allFundingRates /= [] then
        ( model, Cmd.none )

    else
        


itemsPerPage =
    168


view : FrontendModel -> Html FrontendMsg
view model =
    let
        ( days, page ) =
            case model.currentRoute of
                Types.Funding _ days_ page_ ->
                    ( days_, page_ )

                _ ->
                    ( 90, 1 )
    in
    div [ Attr.class "bg-gray-100 min-h-screen" ]
        [ div [ Attr.class "container mx-auto px-4 py-8" ]
            [ h1 [ Attr.class "text-3xl font-bold mb-4" ]
                [ text ("Funding Rate for " ++ model.symbol) ]
            , viewDaysSlider model.fundingDaysSlider days
            , viewRates model days page
            ]
        ]


viewDaysSlider : Int -> Int -> Html FrontendMsg
viewDaysSlider sliderDays actualDays =
    div [ Attr.class "mb-4 flex items-center gap-4" ]
        [ label [ Attr.class "text-gray-700" ]
            [ text "Number of days: "
            , span [ Attr.class "font-bold" ]
                [ text
                    (if sliderDays /= actualDays then
                        String.fromInt sliderDays ++ " (sliding)"

                     else
                        String.fromInt actualDays
                    )
                ]
            ]
        , input
            [ Attr.type_ "range"
            , Attr.min "7"
            , Attr.max "365"
            , Attr.value (String.fromInt sliderDays)
            , Attr.class "w-64"
            , onInput (String.toInt >> Maybe.withDefault 90 >> UpdateFundingDaysSlider)

            --, Html.Events.onMouseUp (ApplyFundingDays sliderDays)
            ]
            []
        ]


viewRates : FrontendModel -> Int -> Int -> Html msg
viewRates model days page =
    let
        totalPages =
            ceiling (toFloat (List.length model.annualizedFundingRates) / toFloat itemsPerPage)

        _ =
            Debug.log "paginatedFundingRates" model.paginatedFundingRates

        _ =
            Debug.log "totalPages" totalPages
    in
    div [ Attr.class "overflow-x-auto" ]
        [ viewRatesTable days model.paginatedFundingRates
        , viewPagination page totalPages model.symbol days
        ]


viewRatesTable : Int -> List AnnualizedRate -> Html msg
viewRatesTable days rates =
    table [ Attr.class "min-w-full bg-white" ]
        [ thead []
            [ tr []
                [ th [ Attr.class "px-4 py-2 border" ] [ text "Time" ]
                , th [ Attr.class "px-4 py-2 border" ] [ text "Current Rate" ]
                , th [ Attr.class "px-4 py-2 border" ] [ text "Current Annualized Rate" ]
                , th [ Attr.class "px-4 py-2 border" ] [ text ("Actual " ++ String.fromInt days ++ "-Day Compound Rate") ]
                , th [ Attr.class "px-4 py-2 border" ] [ text ("Actual " ++ String.fromInt days ++ "-Day Annualized Rate") ]
                ]
            ]
        , tbody []
            (List.map viewRate rates)
        ]


viewRate : AnnualizedRate -> Html msg
viewRate rate =
    let
        rateFromStr =
            String.toFloat rate.fundingRate.fundingRate |> Maybe.withDefault 0

        formatRate rate_ =
            case formatFloat 6 rate_ of
                Float f ->
                    f

                NaN ->
                    "NaN"

                Infinity ->
                    "Infinity"

        immediateAnnualRate =
            rateFromStr * (365 * 24)

        -- Convert hourly rate to annual rate
    in
    tr []
        [ td [ Attr.class "px-4 py-2 border" ] [ text rate.fundingRate.fundingTime ]
        , td [ Attr.class "px-4 py-2 border" ] [ text (formatRate rateFromStr) ]
        , td [ Attr.class "px-4 py-2 border" ] [ text (formatPercent (100 * immediateAnnualRate)) ]
        , td [ Attr.class "px-4 py-2 border" ] [ text (formatRate rate.compoundedRate) ]
        , td [ Attr.class "px-4 py-2 border" ] [ text (formatPercent (100 * rate.compoundedAnnualizedRate)) ]
        ]


viewPagination : Int -> Int -> String -> Int -> Html msg
viewPagination currentPage totalPages symbol days =
    let
        pageLink page =
            a
                [ Attr.href ("/funding?pair=" ++ symbol ++ "&compoundingPeriod=" ++ String.fromInt days ++ "&page=" ++ String.fromInt page)
                , Attr.class <|
                    "px-3 py-2 mx-1 rounded "
                        ++ (if page == currentPage then
                                "bg-blue-500 text-white"

                            else
                                "bg-white text-blue-500 hover:bg-blue-100"
                           )
                ]
                [ text (String.fromInt page) ]

        pages =
            List.range 1 totalPages
    in
    div [ Attr.class "flex justify-center items-center mt-4 space-x-2 flex-wrap" ]
        (List.map pageLink pages)
