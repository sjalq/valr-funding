module Fusion.Generated.TypeDict exposing ( typeDict )

{-|
@docs typeDict
-}


import Dict
import Fusion
import Fusion.Generated.TypeDict.Types


typeDict :
    Dict.Dict (List String) (Dict.Dict String ( Fusion.Type, List String ))
typeDict =
    Dict.fromList
        [ ( [ "TypeDict", "Types" ], Fusion.Generated.TypeDict.Types.typeDict )
        ]