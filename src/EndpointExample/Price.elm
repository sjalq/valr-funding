module EndpointExample.Price exposing (getPrice, getPriceResult)

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


-- Fetches ETH price and ZAR rate in a single task chain with logging, and gets an ETH joke from OpenAI
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
                    finalPrice = ethPrice * zarRate
                in
                logStep ("ZAR rate fetched: " ++ String.fromFloat zarRate ++ ", final price: " ++ String.fromFloat finalPrice ++ " ZAR")
                    (Task.succeed { price = finalPrice, ethPrice = ethPrice, zarRate = zarRate })
            )
        |> Task.andThen
            (\priceData ->
                logStep "Fetching joke about ETH price from OpenAI"
                    (fetchJokeAboutEthPrice priceData.price
                        |> Task.map (\joke -> { price = priceData.price, joke = joke })
                    )
            )
        |> Task.andThen
            (\result ->
                logStep ("Got joke: " ++ result.joke)
                    (Task.succeed result)
            )
        |> Task.map (\result -> 
                Encode.object
                    [ ( "price", Encode.float result.price )
                    , ( "joke", Encode.string result.joke )
                    ]
                    |> Encode.encode 0
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


-- Fetches a joke about ETH price in ZAR from OpenAI
fetchJokeAboutEthPrice : Float -> Task Http.Error String
fetchJokeAboutEthPrice price =
    let
        prompt = "Tell me a short, funny joke about the price of Ethereum being " ++ String.fromFloat price ++ " South African Rand (ZAR). Make it ONE short sentence only."
        
        requestBody =
            Encode.object
                [ ( "model", Encode.string "gpt-3.5-turbo" )
                , ( "messages"
                  , Encode.list 
                        (\msg -> Encode.object msg)
                        [ [ ( "role", Encode.string "system" )
                          , ( "content", Encode.string "You are a helpful assistant that creates short, funny jokes." )
                          ]
                        , [ ( "role", Encode.string "user" )
                          , ( "content", Encode.string prompt )
                          ]
                        ]
                  )
                , ( "max_tokens", Encode.int 100 )
                , ( "temperature", Encode.float 0.7 )
                ]
    in
    if String.isEmpty Env.openAiApiKey then
        Task.succeed "Ethereum price is so high in Rands, even my wallet is crying in two languages!"
    else
        Http.task
            { method = "POST"
            , headers = [ Http.header "Authorization" ("Bearer " ++ Env.openAiApiKey) 
                        , Http.header "Content-Type" "application/json" ]
            , url = addProxy "https://api.openai.com/v1/chat/completions"
            , body = Http.jsonBody requestBody
            , resolver = Http.stringResolver <| handleHttpResponse openAiResponseDecoder
            , timeout = Just 15000
            }


-- Decoder for OpenAI's response
openAiResponseDecoder : String -> Result Http.Error String
openAiResponseDecoder responseBody =
    let
        decoder =
            Decode.field "choices"
                (Decode.index 0
                    (Decode.field "message"
                        (Decode.field "content" Decode.string)
                    )
                )
    in
    case Decode.decodeString decoder responseBody of
        Ok content ->
            Ok (String.trim content)
            
        Err err ->
            Err (Http.BadBody (Decode.errorToString err))


-- Type alias for price with joke
type alias PriceWithJoke =
    { price : Float
    , joke : String
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
                    case Decode.decodeString
                            (Decode.map2 
                                (\price joke -> 
                                    { price = price, joke = joke }
                                )
                                (Decode.field "price" Decode.float)
                                (Decode.field "joke" Decode.string)
                            )
                            data of
                        Ok result ->
                            ( Ok (Encode.object 
                                [ ( "status", Encode.string "ready" )
                                , ( "price", Encode.float result.price )
                                , ( "joke", Encode.string result.joke )
                                ]), 
                              model, 
                              Cmd.none )
                            
                        Err _ ->
                            -- Fallback to original format if parsing fails
                            ( Ok (Encode.object [ ( "status", Encode.string "ready" ), ( "data", Encode.string data ) ]), model, Cmd.none )

                Just (Ready (Err err)) ->
                    ( Ok (Encode.object [ ( "status", Encode.string "error" ), ( "data", Encode.string err ) ]), model, Cmd.none )

                Nothing ->
                    ( Err (Http.BadBody "Invalid polling token"), model, Cmd.none )

        Err _ ->
            ( Err (Http.BadBody "Missing token in request"), model, Cmd.none )
