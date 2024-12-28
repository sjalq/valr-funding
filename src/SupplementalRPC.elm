module SupplementalRPC exposing (..)

import Http
import Json.Encode as Encode
import Lamdera.Wire3 as Wire3
import LamderaRPC exposing (..)
import Task



{-
   Lamdera RPC helpers
-}


stringifyHttpRequest : HttpRequest -> String
stringifyHttpRequest request =
    let
        encodeBody : HttpBody -> Encode.Value
        encodeBody body =
            case body of
                BodyBytes bytes ->
                    bytes |> Encode.list Encode.int

                BodyJson jsonValue ->
                    jsonValue

                BodyString str ->
                    Encode.string str

        encodedRequest =
            Encode.object
                [ ( "sessionId", Encode.string request.sessionId )
                , ( "endpoint", Encode.string request.endpoint )
                , ( "requestId", Encode.string request.requestId )
                , ( "headers", Encode.dict identity Encode.string request.headers )
                , ( "body", encodeBody request.body )
                ]
    in
    Encode.encode 0 encodedRequest


stringifyRPCResult : RPCResult -> String
stringifyRPCResult result =
    let
        encodeResult : RPCResult -> Encode.Value
        encodeResult r =
            case r of
                ResultBytes bytes ->
                    Encode.object
                        [ ( "type", Encode.string "bytes" )
                        , ( "data", Encode.list Encode.int bytes )
                        ]

                ResultJson jsonValue ->
                    Encode.object
                        [ ( "type", Encode.string "json" )
                        , ( "data", jsonValue )
                        ]

                ResultString str ->
                    Encode.object
                        [ ( "type", Encode.string "string" )
                        , ( "data", Encode.string str )
                        ]

                ResultRaw statusCode statusText headers body ->
                    Encode.object
                        [ ( "type", Encode.string "raw" )
                        , ( "statusCode", Encode.int statusCode )
                        , ( "statusText", Encode.string statusText )
                        , ( "headers", Encode.list encodeHeader headers )
                        , ( "body", encodeHttpBody body )
                        ]
    in
    Encode.encode 0 (encodeResult result)


encodeHeader : HttpHeader -> Encode.Value
encodeHeader ( name, value ) =
    Encode.object
        [ ( "name", Encode.string name )
        , ( "value", Encode.string value )
        ]


encodeHttpBody : HttpBody -> Encode.Value
encodeHttpBody body =
    case body of
        BodyBytes bytes ->
            Encode.object
                [ ( "type", Encode.string "bytes" )
                , ( "data", Encode.list Encode.int bytes )
                ]

        BodyJson jsonValue ->
            Encode.object
                [ ( "type", Encode.string "json" )
                , ( "data", jsonValue )
                ]

        BodyString str ->
            Encode.object
                [ ( "type", Encode.string "string" )
                , ( "data", Encode.string str )
                ]


encodeRPCCallAndResult : LamderaRPC.HttpRequest -> LamderaRPC.RPCResult -> String
encodeRPCCallAndResult args result =
    Encode.encode 0
        (Encode.object
            [ ( "request", stringifyHttpRequest args |> Encode.string )
            , ( "result", stringifyRPCResult result |> Encode.string )
            ]
        )


fetchImportedModel : String -> String -> Wire3.Decoder value -> Task.Task Http.Error value
fetchImportedModel remoteLamderaUrl modelKey decoder =
    Http.task
        { method = "POST"
        , headers =
            [ Http.header "Content-Type" "application/octet-stream"
            , Http.header "x-lamdera-model-key" modelKey
            ]
        , url = remoteLamderaUrl ++ "/_r/getModel/"
        , body = Http.emptyBody
        , resolver =
            Http.bytesResolver <|
                \response ->
                    case response of
                        Http.GoodStatus_ _ body ->
                            case Wire3.bytesDecode decoder body of
                                Just model ->
                                    Ok model

                                Nothing ->
                                    Err (Http.BadBody "Bytes decode failed")

                        Http.BadStatus_ meta _ ->
                            Err (Http.BadStatus meta.statusCode)

                        Http.NetworkError_ ->
                            Err Http.NetworkError

                        Http.Timeout_ ->
                            Err Http.Timeout

                        Http.BadUrl_ url_ ->
                            Err (Http.BadUrl url_)
        , timeout = Nothing
        }
