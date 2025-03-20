module Crypto.Price exposing (getPrice, getPriceResult)

import Dict
import Http
import Json.Decode as Decode
import Json.Encode as Encode
import Lamdera exposing (SessionId)
import LamderaRPC exposing (Headers)
import Supplemental exposing (addProxy, handleHttpResponse, httpErrorToString)
import Task exposing (Task)
import Types exposing (..)



-- Fetches both ETH price and ZAR rate, multiplies them and returns result through polling


getPrice : SessionId -> BackendModel -> Headers -> Encode.Value -> ( Result Http.Error Encode.Value, BackendModel, Cmd BackendMsg )
getPrice _ model _ _ =
    let
        token =
            "crypto-price-" ++ String.fromInt (Dict.size model.pollingJobs)

        updatedModel =
            { model | pollingJobs = Dict.insert token Busy model.pollingJobs }

        cmd =
            Task.attempt (GotCryptoPriceResult token) fetchEthPriceInZar

        response =
            Encode.object [ ( "token", Encode.string token ) ]
    in
    ( Ok response, updatedModel, cmd )



-- Fetches ETH price and ZAR rate in a single task chain


fetchEthPriceInZar : Task Http.Error String
fetchEthPriceInZar =
    fetchEthPrice
        |> Task.andThen
            (\ethPrice ->
                fetchZarRate
                    |> Task.map (\zarRate -> ethPrice * zarRate)
                    |> Task.map String.fromFloat
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
                    ( Ok (Encode.object [ ( "status", Encode.string "busy" ), ( "data", Encode.null ) ]), model, Cmd.none )

                Just (Ready (Ok data)) ->
                    ( Ok (Encode.object [ ( "status", Encode.string "ready" ), ( "data", Encode.string data ) ]), model, Cmd.none )

                Just (Ready (Err err)) ->
                    ( Ok (Encode.object [ ( "status", Encode.string "error" ), ( "data", Encode.string err ) ]), model, Cmd.none )

                Nothing ->
                    ( Err (Http.BadBody "Invalid polling token"), model, Cmd.none )

        Err _ ->
            ( Err (Http.BadBody "Missing token in request"), model, Cmd.none )
