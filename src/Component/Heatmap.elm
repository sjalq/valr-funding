module Component.Heatmap exposing (viewHeatmap)

import Browser.Dom exposing (Viewport)
import Dict exposing (Dict)
import Dict.Extra as Dict
import Html exposing (Html)
import Html.Attributes as Attr
import List.Extra as List
import Supplemental
import Svg exposing (..)
import Svg.Attributes exposing (..)
import Time exposing (Posix)
import Types exposing (..)



{-
   Draw a fundingrate heatmap in SVG
-}


viewHeatmap : Maybe Viewport -> Dict String (List FundingRate) -> Html msg
viewHeatmap viewport rates =
    let
        symbols =
            Dict.keys rates
                |> List.repeat 5
                |> List.concat

        maxRates =
            Dict.values rates
                |> List.map List.length
                |> List.maximum
                |> Maybe.withDefault 0
    in
    case viewport of
        Just viewport_ ->
            let
                -- Calculate available width considering container padding
                availableWidth =
                    viewport_.viewport.width * 0.8

                -- Calculate block width based on available space and number of rates
                blockWidth =
                    Basics.min 20 (availableWidth / toFloat maxRates)

                -- Calculate total height needed with no gaps
                rowHeight =
                    20

                totalHeight =
                    toFloat (List.length symbols) * rowHeight
            in
            svg
                [ width (String.fromFloat availableWidth)
                , height (String.fromFloat totalHeight)
                , viewBox ("0 0 " ++ String.fromFloat availableWidth ++ " " ++ String.fromFloat totalHeight)
                ]
                (List.indexedMap
                    (\index symbol ->
                        g [ transform ("translate(0," ++ String.fromFloat (toFloat index * rowHeight) ++ ")") ]
                            [ text_ [ x "10", y "15", alignmentBaseline "middle" ] [ text symbol ]
                            , g [ transform "translate(150, 0)" ]
                                [ heatRow blockWidth (Dict.get symbol rates |> Maybe.withDefault [] |> List.reverse) ]
                            ]
                    )
                    symbols
                )

        Nothing ->
            svg [] []


type alias ColorStop =
    { threshold : Float
    , red : Float
    , green : Float
    , blue : Float
    }


heatRow : Float -> List FundingRate -> Svg msg
heatRow blockWidth rates =
    let
        rateToColor : Float -> { color : String }
        rateToColor rate =
            let
                colorStops =
                    [ ColorStop -150 0 0 255 -- Deep blue
                    , ColorStop -75 128 0 255 -- Deep purple
                    , ColorStop 0 0 255 0 -- Green
                    , ColorStop 75 255 255 0 -- Yellow
                    , ColorStop 150 255 128 0 -- Orange
                    , ColorStop 300 255 0 0 -- Red
                    , ColorStop 500 255 255 255 -- White
                    ]

                interpolateColor : Float -> ColorStop -> ColorStop -> { red : Float, green : Float, blue : Float }
                interpolateColor value lower upper =
                    let
                        t =
                            (value - lower.threshold) / (upper.threshold - lower.threshold)
                    in
                    { red = lower.red + t * (upper.red - lower.red)
                    , green = lower.green + t * (upper.green - lower.green)
                    , blue = lower.blue + t * (upper.blue - lower.blue)
                    }

                findColors value stops =
                    case stops of
                        lower :: upper :: rest ->
                            if value <= upper.threshold then
                                interpolateColor value lower upper

                            else
                                findColors value (upper :: rest)

                        [ last ] ->
                            { red = last.red
                            , green = last.green
                            , blue = last.blue
                            }

                        [] ->
                            { red = 255, green = 255, blue = 255 }

                color =
                    findColors rate colorStops
            in
            { color =
                "rgb("
                    ++ String.fromInt (round color.red)
                    ++ ", "
                    ++ String.fromInt (round color.green)
                    ++ ", "
                    ++ String.fromInt (round color.blue)
                    ++ ")"
            }

        annualize rate =
            ((1 + rate) ^ (24 * 365.25) - 1) * 100

        toFloat_ rate =
            String.toFloat rate.fundingRate |> Maybe.withDefault 0

        minWidth =
            4

        ( groupedRates, adjustedBlockWidth ) =
            if blockWidth < minWidth then
                let
                    chunkSize =
                        ceiling (minWidth / blockWidth)

                    chunks =
                        rates
                            |> List.greedyGroupsOf chunkSize
                            |> List.map
                                (\chunk ->
                                    { rate =
                                        chunk
                                            |> List.map toFloat_
                                            |> List.foldl (+) 0
                                            |> (\sum -> sum / toFloat (List.length chunk))
                                            |> annualize
                                    , earliestTime =
                                        chunk
                                            |> List.head
                                            |> Maybe.map .fundingTime
                                            |> Maybe.withDefault ""
                                    }
                                )

                    newBlockWidth =
                        blockWidth * toFloat chunkSize
                in
                ( chunks, newBlockWidth )

            else
                ( rates
                    |> List.map
                        (\r ->
                            { rate = toFloat_ r |> annualize
                            , earliestTime = r.fundingTime
                            }
                        )
                , blockWidth
                )
    in
    g []
        (groupedRates
            |> List.indexedMap
                (\i data ->
                    let
                        colorInfo =
                            rateToColor data.rate
                    in
                    rect
                        [ x (String.fromFloat (20 + (toFloat i * adjustedBlockWidth)))
                        , y "5"
                        , width (String.fromFloat (adjustedBlockWidth + 0.1))
                        , height "20"
                        , fill colorInfo.color
                        , shapeRendering "crispEdges"
                        , strokeWidth "0"
                        ]
                        [ Svg.title []
                            [ text (Supplemental.formatPercent data.rate ++ " at " ++ data.earliestTime) ]
                        ]
                )
        )
