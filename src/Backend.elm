module Backend exposing (..)

import Dict
import Dict.Extra as Dict
import Env
import Http exposing (..)
import Iso8601
import Json.Decode as D
import Lamdera
import List.Extra as List
import Process
import Supplemental exposing (..)
import Task exposing (Task)
import Time
import Types exposing (..)


type alias Model =
    BackendModel


app =
    Lamdera.backend
        { init = init
        , update = update
        , updateFromFrontend = updateFromFrontend
        , subscriptions = subscriptions
        }


subscriptions : Model -> Sub BackendMsg
subscriptions model =
    Sub.batch
        [--Time.every (6 * 1000) BE_FetchFundingRates
        ]


init : ( Model, Cmd BackendMsg )
init =
    ( { logs = []
      , rates = []
      , symbols =
            [ "USDTZARPERP"
            , "XRPUSDTPERP"
            , "DOGEUSDTPERP"
            , "SOLUSDTPERP"
            , "AVAXUSDTPERP"
            , "APTUSDTPERP"
            , "OPUSDTPERP"
            , "SUIUSDTPERP"
            , "WIFUSDTPERP"
            , "STXUSDTPERP"
            , "1MPEPEUSDTPERP"
            , "1MSHIBUSDTPERP"
            , "TONUSDTPERP"
            , "1MBONKUSDTPERP"
            , "AVAILUSDTPERP"
            , "ORDERUSDTPERP"
            , "BTCZARPERP"
            , "BTCUSDTPERP"
            , "BTCUSDCPERP"
            , "ETHUSDTPERP"
            , "ETHZARPERP"
            , "ETHUSDCPERP"
            ]
      }
    , Cmd.none
    )


hardCodedSymbols =
    [ "USDTZARPERP"
    , "XRPUSDTPERP"
    , "DOGEUSDTPERP"
    , "SOLUSDTPERP"
    , "AVAXUSDTPERP"
    , "APTUSDTPERP"
    , "OPUSDTPERP"
    , "SUIUSDTPERP"
    , "WIFUSDTPERP"
    , "STXUSDTPERP"
    , "1MPEPEUSDTPERP"
    , "1MSHIBUSDTPERP"
    , "TONUSDTPERP"
    , "1MBONKUSDTPERP"
    , "AVAILUSDTPERP"
    , "ORDERUSDTPERP"
    , "BTCZARPERP"
    , "BTCUSDTPERP"
    , "BTCUSDCPERP"
    , "ETHUSDTPERP"
    , "ETHZARPERP"
    , "ETHUSDCPERP"
    ]


update : BackendMsg -> Model -> ( Model, Cmd BackendMsg )
update msg model =
    case msg of
        NoOpBackendMsg ->
            ( model, Cmd.none )

        DirectToFrontend connectionId msg_ ->
            ( model, Lamdera.sendToFrontend connectionId msg_ )

        Log logMsg ->
            ( model, Cmd.none )
                |> log logMsg

        -------
        BE_GotFundingRates now result ->
            case result of
                Ok ( remainingSymbols, rates ) ->
                    let
                        newModel =
                            appendRates model rates
                    in
                    ( newModel
                    , case remainingSymbols of
                        [] ->
                            -- if there are no more remaining symbols, wait one hour and start fresh.
                            Process.sleep (1 * hour)
                                |> Task.andThen (\_ -> getFundingRates newModel model.symbols now)
                                |> Task.attempt (BE_GotFundingRates now)

                        _ ->
                            getFundingRates newModel remainingSymbols now |> Task.attempt (BE_GotFundingRates now)
                    )
                        |> log ("Got funding rates for " ++ (rates |> List.head |> Maybe.map .currencyPair |> Maybe.withDefault "no rates"))

                Err wrong ->
                    ( model, Cmd.none )
                        |> log ("Error fetching funding rates: " ++ (wrong |> Supplemental.httpErrorToString))

        BE_FetchFundingRates now ->
            ( model, getFundingRates model model.symbols now |> Task.attempt (BE_GotFundingRates now) )


updateFromFrontend : BrowserCookie -> ConnectionId -> ToBackend -> Model -> ( Model, Cmd BackendMsg )
updateFromFrontend browserCookie connectionId msg model =
    case msg of
        NoOpToBackend ->
            ( model, Cmd.none )

        Admin_FetchLogs ->
            ( model, Lamdera.sendToFrontend connectionId (Admin_Logs_ToFrontend model.logs) )

        Admin_ClearLogs ->
            let
                newModel =
                    { model | logs = [] }
            in
            ( newModel, Lamdera.sendToFrontend connectionId (Admin_Logs_ToFrontend newModel.logs) )

        Admin_CheckPasswordBackend password ->
            ( model
            , if password == Env.modelKey then
                Lamdera.sendToFrontend connectionId (Admin_LoginResponse True)

              else
                Lamdera.sendToFrontend connectionId (Admin_LoginResponse False)
            )

        FetchFundingRates symbol ->
            let
                rates =
                    model.rates
                        |> List.filter (\r -> r.currencyPair == symbol)

                result =
                    compoundRates (180 * 24) rates
            in
            ( model
            , Lamdera.sendToFrontend connectionId (FE_GotFundingRates result)
            )

        Admin_TriggerFundingRatesFetch ->
            ( model
            , Task.perform BE_FetchFundingRates Time.now
            )
                |> log "Admin triggered funding rates fetch"


log =
    Supplemental.log NoOpBackendMsg


valrPublicHttpTask url decoder =
    Process.sleep (6 * second)
        |> Task.andThen
            (\_ ->
                Http.task
                    { method = "GET"
                    , headers = []
                    , url = url |> addProxy
                    , body = Http.emptyBody
                    , resolver = Http.stringResolver (handleJsonResponse decoder)
                    , timeout = Nothing
                    }
            )


addTime : Int -> Time.Posix -> Time.Posix
addTime add time =
    Time.posixToMillis time
        + add
        |> Time.millisToPosix


addTimeStr : Int -> String -> String
addTimeStr add str =
    str
        |> Iso8601.toTime
        |> Result.map (\time -> time |> addTime add)
        |> Result.map Iso8601.fromTime
        |> Result.withDefault str


getFundingRates : Model -> List String -> Time.Posix -> Task Http.Error ( List String, List FundingRate )
getFundingRates model remainingSymbols now =
    let
        decoder =
            D.list
                (D.map3 FundingRate
                    (D.field "currencyPair" D.string)
                    (D.field "fundingRate" D.string)
                    (D.field "fundingTime" D.string)
                )

        ratesUrl symbol startTimeStr endTimeStr =
            "https://api.valr.com/v1/public/futures/funding/history?currencyPair="
                ++ symbol
                ++ "&startTime="
                ++ startTimeStr
                ++ "&endTime="
                ++ endTimeStr
                ++ "&limit=100"

        oneHourAgo =
            now
                |> addTime (hour * -1)

        symbolRates symbol =
            let
                rates =
                    model.rates
                        |> List.filter (\r -> r.currencyPair == symbol)
                        |> List.sortBy .fundingTime

                lastRate =
                    rates |> List.last

                firstRate =
                    rates |> List.head
            in
            case ( firstRate, lastRate ) of
                ( Nothing, Nothing ) ->
                    let
                        startTimeStr =
                            now
                                |> addTime (-100 * hour)
                                |> Iso8601.fromTime

                        endTimeStr =
                            now |> Iso8601.fromTime
                    in
                    valrPublicHttpTask (ratesUrl symbol startTimeStr endTimeStr) decoder
                        |> Task.map
                            (\rates_ ->
                                case rates_ of
                                    [] ->
                                        ( remainingSymbols |> List.remove symbol, [] )

                                    all ->
                                        ( remainingSymbols, all )
                            )

                ( Just first, Just last ) ->
                    let
                        needToFetchNewest =
                            last.fundingTime
                                |> Iso8601.toTime
                                |> Result.map (\time -> Time.posixToMillis time < Time.posixToMillis oneHourAgo)
                                |> Result.withDefault True

                        beforeStartStr =
                            first.fundingTime |> addTimeStr (-100 * hour)
                    in
                    valrPublicHttpTask (ratesUrl symbol beforeStartStr first.fundingTime) decoder
                        |> Task.andThen
                            (\olderRates ->
                                if needToFetchNewest then
                                    valrPublicHttpTask (ratesUrl symbol last.fundingTime (last.fundingTime |> addTimeStr (hour * 100))) decoder

                                else
                                    Task.succeed olderRates
                            )
                        |> Task.andThen
                            (\allRates ->
                                Task.succeed
                                    (case allRates of
                                        [] ->
                                            ( remainingSymbols |> List.remove symbol, [] )

                                        all ->
                                            ( remainingSymbols, all )
                                    )
                            )

                _ ->
                    Task.succeed ( remainingSymbols |> List.remove symbol, [] )
    in
    Process.sleep 100
        |> Task.andThen
            (\_ ->
                remainingSymbols
                    |> List.head
                    |> Maybe.map symbolRates
                    |> Maybe.withDefault (Task.succeed ( remainingSymbols, [] ))
            )


handleJsonResponse : D.Decoder a -> Http.Response String -> Result Http.Error a
handleJsonResponse decoder response =
    case response of
        Http.BadUrl_ url ->
            Err (Http.BadUrl url)

        Http.Timeout_ ->
            Err Http.Timeout

        Http.NetworkError_ ->
            Err Http.NetworkError

        Http.BadStatus_ metadata body ->
            Err (Http.BadStatus metadata.statusCode)

        Http.GoodStatus_ metadata body ->
            case D.decodeString decoder body of
                Ok value ->
                    Ok value

                Err err ->
                    Err (Http.BadBody (D.errorToString err))


appendRates : Model -> List FundingRate -> Model
appendRates model rates =
    let
        _ =
            Debug.log "Triggered" ()

        isNewRate rate =
            not <| List.any (\r -> r.currencyPair == rate.currencyPair && r.fundingTime == rate.fundingTime) model.rates
    in
    { model | rates = model.rates ++ List.filter isNewRate rates }


compoundRates : Int -> List FundingRate -> List ( FundingRate, Float )
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

        result =
            sortedRates
                |> List.indexedMap (\i r -> ( r, compoundRate sortedRates i (i + records) ))
    in
    result
