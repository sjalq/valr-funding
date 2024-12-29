module Fusion.Generated.TypeDict.Types exposing ( typeDict, type_BackendModel, type_FundingRate )

{-|
@docs typeDict, type_BackendModel, type_FundingRate
-}


import Dict
import Fusion


typeDict : Dict.Dict String ( Fusion.Type, List a )
typeDict =
    Dict.fromList
        [ ( "FundingRate", ( type_FundingRate, [] ) )
        , ( "BackendModel", ( type_BackendModel, [] ) )
        ]


type_BackendModel : Fusion.Type
type_BackendModel =
    Fusion.TRecord
        [ ( "logs"
          , Fusion.TNamed
                [ "List" ]
                "List"
                [ Fusion.TNamed [ "String" ] "String" [] (Just Fusion.TString) ]
                (Just
                     (Fusion.TList
                          (Fusion.TNamed
                               [ "String" ]
                               "String"
                               []
                               (Just Fusion.TString)
                          )
                     )
                )
          )
        , ( "rates"
          , Fusion.TNamed
                [ "List" ]
                "List"
                [ Fusion.TNamed [ "Types" ] "FundingRate" [] Nothing ]
                (Just
                     (Fusion.TList
                          (Fusion.TNamed [ "Types" ] "FundingRate" [] Nothing)
                     )
                )
          )
        , ( "symbols"
          , Fusion.TNamed
                [ "List" ]
                "List"
                [ Fusion.TNamed [ "String" ] "String" [] (Just Fusion.TString) ]
                (Just
                     (Fusion.TList
                          (Fusion.TNamed
                               [ "String" ]
                               "String"
                               []
                               (Just Fusion.TString)
                          )
                     )
                )
          )
        ]


type_FundingRate : Fusion.Type
type_FundingRate =
    Fusion.TRecord
        [ ( "currencyPair"
          , Fusion.TNamed [ "String" ] "String" [] (Just Fusion.TString)
          )
        , ( "fundingRate"
          , Fusion.TNamed [ "String" ] "String" [] (Just Fusion.TString)
          )
        , ( "fundingTime"
          , Fusion.TNamed [ "String" ] "String" [] (Just Fusion.TString)
          )
        ]