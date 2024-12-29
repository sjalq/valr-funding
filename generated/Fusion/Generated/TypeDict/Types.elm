module Fusion.Generated.TypeDict.Types exposing ( typeDict, type_BackendModel )

{-|
@docs typeDict, type_BackendModel
-}


import Dict
import Fusion


typeDict : Dict.Dict String ( Fusion.Type, List a )
typeDict =
    Dict.fromList [ ( "BackendModel", ( type_BackendModel, [] ) ) ]


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
        ]