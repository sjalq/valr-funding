module Crypto.Price exposing (getPrice, getPriceResult)

import Dict
import Env
import Http
import Json.Decode as Decode
import Json.Encode as Encode
import Lamdera exposing (SessionId)
import LamderaRPC exposing (Headers)
import Process
import Supplemental exposing (addProxy, handleHttpResponse, httpErrorToString, sendSlackMessage)
import Task exposing (Task)
import Time
import Types exposing (..)



-- Fetches both ETH price and ZAR rate, multiplies them and returns result through polling


getPrice : SessionId -> BackendModel -> Headers -> Encode.Value -> ( Result Http.Error Encode.Value, BackendModel, Cmd BackendMsg )
getPrice _ model _ _ =
    let
        token =
            "crypto-price-" ++ String.fromInt (Dict.size model.pollingJobs)

        updatedModel =
            { model | pollingJobs = Dict.insert token Busy model.pollingJobs }

        -- Main task to calculate ETH price in ZAR
        mainCmd =
            Task.attempt (GotCryptoPriceResult token) fetchEthPriceInZar
            
        -- Secondary task to get the current timestamp
        timeCmd =
            Time.now
                |> Task.map Time.posixToMillis
                |> Task.attempt (handleTimeResult token)
                
        response =
            Encode.object [ ( "token", Encode.string token ) ]
    in
    ( Ok response, updatedModel, Cmd.batch [mainCmd, timeCmd] )


-- Handler for the time result
handleTimeResult : PollingToken -> Result x Int -> BackendMsg
handleTimeResult token result =
    case result of
        Ok timestamp ->
            GotJobTime token timestamp
            
        Err _ ->
            -- If time fetch fails, just ignore
            NoOpBackendMsg


-- Fetches ETH price and ZAR rate in a single task chain with logging
fetchEthPriceInZar : Task Http.Error String
fetchEthPriceInZar =
    let
        logStep : String -> Task x a -> Task x a
        logStep message task =
            sendSlackMessage Env.slackApiToken Env.slackChannel message
                |> Task.map (\_ -> ())
                |> Task.onError (\_ -> Task.succeed ())
                |> Task.andThen (\_ -> task)
    in
    logStep "Starting to fetch ETH price" fetchEthPrice
        |> Task.andThen
            (\ethPrice ->
                logStep ("ETH price fetched: " ++ String.fromFloat ethPrice ++ " USD")
                    (Task.succeed ethPrice)
            )
        |> Task.andThen
            (\ethPrice ->
                logStep "Starting 1-minute delay between API calls"
                    (Process.sleep 60000 |> Task.map (\_ -> ethPrice))
            )
        |> Task.andThen
            (\ethPrice ->
                logStep "Delay finished, fetching ZAR rate"
                    (fetchZarRate |> Task.map (\zarRate -> { ethPrice = ethPrice, zarRate = zarRate }))
            )
        |> Task.andThen
            (\{ ethPrice, zarRate } ->
                let
                    result = ethPrice * zarRate
                in
                logStep ("ZAR rate fetched: " ++ String.fromFloat zarRate ++ ", final price: " ++ String.fromFloat result ++ " ZAR")
                    (Task.succeed (String.fromFloat result))
            )


-- Fetches ETH price from Coingecko API
fetchEthPrice : Task Http.Error Float
fetchEthPrice =
    Http.task
        { method = "GET"
        , headers = []
        , url = addProxy "https://api.coingecko.com/api/v3/simple/price?ids=ethereum&vs_currencies=usd"
        , body = Http.emptyBody
        , resolver =
            Http.stringResolver <|
                handleHttpResponse
                    (Decode.decodeString (Decode.field "ethereum" (Decode.field "usd" Decode.float))
                        >> Result.mapError (\_ -> Http.BadBody "Failed to decode ETH price")
                    )
        , timeout = Just 10000
        }


-- Fetches ZAR/USD rate from Exchange Rates API
fetchZarRate : Task Http.Error Float
fetchZarRate =
    Http.task
        { method = "GET"
        , headers = []
        , url = addProxy "https://open.er-api.com/v6/latest/USD"
        , body = Http.emptyBody
        , resolver =
            Http.stringResolver <|
                handleHttpResponse
                    (Decode.decodeString (Decode.field "rates" (Decode.field "ZAR" Decode.float))
                        >> Result.mapError (\_ -> Http.BadBody "Failed to decode ZAR rate")
                    )
        , timeout = Just 10000
        }


-- Polls for crypto price status
getPriceResult : SessionId -> BackendModel -> Headers -> Encode.Value -> ( Result Http.Error Encode.Value, BackendModel, Cmd BackendMsg )
getPriceResult _ model _ json =
    case Decode.decodeValue (Decode.field "token" Decode.string) json of
        Ok token ->
            case Dict.get token model.pollingJobs of
                Just Busy ->
                    ( Ok (Encode.object [ ( "status", Encode.string "busy" ) ]), model, Cmd.none )
                
                Just (BusyWithTime timestamp) ->
                    ( Ok (Encode.object 
                          [ ( "status", Encode.string "busy" )
                          , ( "time", Encode.int timestamp )
                          ]), model, Cmd.none )

                Just (Ready (Ok data)) ->
                    ( Ok (Encode.object [ ( "status", Encode.string "ready" ), ( "data", Encode.string data ) ]), model, Cmd.none )

                Just (Ready (Err err)) ->
                    ( Ok (Encode.object [ ( "status", Encode.string "error" ), ( "data", Encode.string err ) ]), model, Cmd.none )

                Nothing ->
                    ( Err (Http.BadBody "Invalid polling token"), model, Cmd.none )

        Err _ ->
            ( Err (Http.BadBody "Missing token in request"), model, Cmd.none )
