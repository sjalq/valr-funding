module RPC exposing (..)

import Dict
import Env
import Http
import Json.Encode as Encode
import Lamdera exposing (SessionId)
import Lamdera.Wire3
import LamderaRPC exposing (..)
import Supplemental exposing (..)
import SupplementalRPC exposing (..)
import Types exposing (..)


lamdera_handleEndpoints :
    a
    -> LamderaRPC.HttpRequest
    -> BackendModel
    -> ( LamderaRPC.RPCResult, BackendModel, Cmd BackendMsg )
lamdera_handleEndpoints rawReq args model =
    let
        ( result, newModel, cmds ) =
            case args.endpoint of
                "getModel" ->
                    LamderaRPC.handleEndpointBytes (getModel args) (Lamdera.Wire3.succeedDecode ()) Types.w3_encode_BackendModel args model

                "getLogs" ->
                    LamderaRPC.handleEndpointJson getLogs args model

                _ ->
                    let
                        rpcFailure =
                            LamderaRPC.failWith LamderaRPC.StatusBadRequest <| "Unknown endpoint " ++ args.endpoint
                    in
                    ( rpcFailure, model, performNow (Log (encodeRPCCallAndResult args rpcFailure)) )
    in
    case args.endpoint of
        "getModel" ->
            ( result, newModel, cmds )

        "getLogs" ->
            ( result, newModel, cmds )

        _ ->
            ( result, newModel, cmds ) |> rpcLog (encodeRPCCallAndResult args result)


getModel : HttpRequest -> SessionId -> BackendModel -> Dict.Dict String String -> input -> ( Result Http.Error BackendModel, BackendModel, Cmd msg )
getModel _ _ model headers _ =
    case headers |> Dict.get "x-lamdera-model-key" of
        Just modelKey ->
            if Env.modelKey == modelKey then
                ( model |> Ok, model, Cmd.none )

            else
                ( Http.BadStatus 401 |> Err, model, Cmd.none )

        Nothing ->
            ( Http.BadStatus 401 |> Err, model, Cmd.none )


getLogs _ model headers _ =
    case headers |> Dict.get "x-lamdera-model-key" of
        Just modelKey ->
            if Env.modelKey == modelKey then
                ( Encode.list Encode.string model.logs |> Ok, model, Cmd.none )

            else
                ( Http.BadStatus 401 |> Err, model, Cmd.none )

        Nothing ->
            ( Http.BadStatus 401 |> Err, model, Cmd.none )


rpcLog =
    Supplemental.rpcLog NoOpBackendMsg
