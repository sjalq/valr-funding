module Fusion.Generated.Types exposing
    ( build_BackendModel, build_FundingRate, patch_BackendModel, patch_FundingRate, patcher_BackendModel, patcher_FundingRate
    , toValue_BackendModel, toValue_FundingRate
    )

{-|
@docs build_BackendModel, build_FundingRate, patch_BackendModel, patch_FundingRate, patcher_BackendModel, patcher_FundingRate
@docs toValue_BackendModel, toValue_FundingRate
-}


import Dict
import Fusion
import Fusion.Patch
import Types


build_BackendModel :
    Fusion.Value -> Result Fusion.Patch.Error Types.BackendModel
build_BackendModel value =
    Fusion.Patch.build_Record
        (\build_RecordUnpack ->
             Result.map3
                 (\logs rates symbols ->
                      { logs = logs, rates = rates, symbols = symbols }
                 )
                 (Result.andThen
                      (Fusion.Patch.build_List Fusion.Patch.patcher_String)
                      (build_RecordUnpack "logs")
                 )
                 (Result.andThen
                      (Fusion.Patch.build_List patcher_FundingRate)
                      (build_RecordUnpack "rates")
                 )
                 (Result.andThen
                      (Fusion.Patch.build_List Fusion.Patch.patcher_String)
                      (build_RecordUnpack "symbols")
                 )
        )
        value


build_FundingRate : Fusion.Value -> Result Fusion.Patch.Error Types.FundingRate
build_FundingRate value =
    Fusion.Patch.build_Record
        (\build_RecordUnpack ->
             Result.map3
                 (\currencyPair fundingRate fundingTime ->
                      { currencyPair = currencyPair
                      , fundingRate = fundingRate
                      , fundingTime = fundingTime
                      }
                 )
                 (Result.andThen
                      Fusion.Patch.build_String
                      (build_RecordUnpack "currencyPair")
                 )
                 (Result.andThen
                      Fusion.Patch.build_String
                      (build_RecordUnpack "fundingRate")
                 )
                 (Result.andThen
                      Fusion.Patch.build_String
                      (build_RecordUnpack "fundingTime")
                 )
        )
        value


patch_BackendModel :
    { force : Bool }
    -> Fusion.Patch.Patch
    -> Types.BackendModel
    -> Result Fusion.Patch.Error Types.BackendModel
patch_BackendModel options patch value =
    Fusion.Patch.patch_Record
        (\fieldName fieldPatch acc ->
             case fieldName of
                 "logs" ->
                     Result.map
                         (\logs -> { acc | logs = logs })
                         (Fusion.Patch.patch_List
                              Fusion.Patch.patcher_String
                              options
                              fieldPatch
                              acc.logs
                         )

                 "rates" ->
                     Result.map
                         (\rates -> { acc | rates = rates })
                         (Fusion.Patch.patch_List
                              patcher_FundingRate
                              options
                              fieldPatch
                              acc.rates
                         )

                 "symbols" ->
                     Result.map
                         (\symbols -> { acc | symbols = symbols })
                         (Fusion.Patch.patch_List
                              Fusion.Patch.patcher_String
                              options
                              fieldPatch
                              acc.symbols
                         )

                 _ ->
                     Result.Err (Fusion.Patch.UnexpectedField fieldName)
        )
        patch
        value


patch_FundingRate :
    { force : Bool }
    -> Fusion.Patch.Patch
    -> Types.FundingRate
    -> Result Fusion.Patch.Error Types.FundingRate
patch_FundingRate options patch value =
    Fusion.Patch.patch_Record
        (\fieldName fieldPatch acc ->
             case fieldName of
                 "currencyPair" ->
                     Result.map
                         (\currencyPair -> { acc | currencyPair = currencyPair }
                         )
                         (Fusion.Patch.patch_String
                              options
                              fieldPatch
                              acc.currencyPair
                         )

                 "fundingRate" ->
                     Result.map
                         (\fundingRate -> { acc | fundingRate = fundingRate })
                         (Fusion.Patch.patch_String
                              options
                              fieldPatch
                              acc.fundingRate
                         )

                 "fundingTime" ->
                     Result.map
                         (\fundingTime -> { acc | fundingTime = fundingTime })
                         (Fusion.Patch.patch_String
                              options
                              fieldPatch
                              acc.fundingTime
                         )

                 _ ->
                     Result.Err (Fusion.Patch.UnexpectedField fieldName)
        )
        patch
        value


patcher_BackendModel : Fusion.Patch.Patcher Types.BackendModel
patcher_BackendModel =
    { patch = patch_BackendModel
    , build = build_BackendModel
    , toValue = toValue_BackendModel
    }


patcher_FundingRate : Fusion.Patch.Patcher Types.FundingRate
patcher_FundingRate =
    { patch = patch_FundingRate
    , build = build_FundingRate
    , toValue = toValue_FundingRate
    }


toValue_BackendModel : Types.BackendModel -> Fusion.Value
toValue_BackendModel value =
    Fusion.VRecord
        (Dict.fromList
             [ ( "logs"
               , Fusion.Patch.toValue_List
                     Fusion.Patch.patcher_String
                     value.logs
               )
             , ( "rates"
               , Fusion.Patch.toValue_List patcher_FundingRate value.rates
               )
             , ( "symbols"
               , Fusion.Patch.toValue_List
                     Fusion.Patch.patcher_String
                     value.symbols
               )
             ]
        )


toValue_FundingRate : Types.FundingRate -> Fusion.Value
toValue_FundingRate value =
    Fusion.VRecord
        (Dict.fromList
             [ ( "currencyPair", Fusion.VString value.currencyPair )
             , ( "fundingRate", Fusion.VString value.fundingRate )
             , ( "fundingTime", Fusion.VString value.fundingTime )
             ]
        )