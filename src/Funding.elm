module Funding exposing (..)

import Types exposing (..)


compoundRates : Int -> List FundingRate -> List AnnualizedRate
compoundRates records rates =
    let
        compoundRate allRates fromIndex toIndex =
            let
                rl =
                    allRates
                        |> List.drop fromIndex
                        |> List.take toIndex
            in
            rl
                |> List.map (.fundingRate >> String.toFloat >> Maybe.withDefault 0)
                |> List.foldl (\rate acc -> (1 + rate) * acc) 1
                |> (\x -> x - 1)

        sortedRates =
            rates
                |> List.sortBy .fundingTime
                |> List.reverse
    in
    sortedRates
        |> List.indexedMap
            (\i r ->
                let
                    rate =
                        String.toFloat r.fundingRate |> Maybe.withDefault 0

                    compoundedRate =
                        compoundRate sortedRates i (i + records)
                in
                { fundingRate = r
                , annualizedRate = annualizedRate records rate
                , compoundedRate = compoundedRate
                , compoundedAnnualizedRate = annualizedRate records compoundedRate
                }
            )


annualizedRate : Int -> Float -> Float
annualizedRate period rate =
    (1 + rate) ^ ((365 * 24) / toFloat period) - 1
