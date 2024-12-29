module Fusion.Generated.Types exposing ( build_BackendModel, patch_BackendModel, patcher_BackendModel, toValue_BackendModel )

{-|
@docs build_BackendModel, patch_BackendModel, patcher_BackendModel, toValue_BackendModel
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
             Result.map
                 (\logs -> { logs = logs })
                 (Result.andThen
                      (Fusion.Patch.build_List Fusion.Patch.patcher_String)
                      (build_RecordUnpack "logs")
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


toValue_BackendModel : Types.BackendModel -> Fusion.Value
toValue_BackendModel value =
    Fusion.VRecord
        (Dict.fromList
             [ ( "logs"
               , Fusion.Patch.toValue_List
                     Fusion.Patch.patcher_String
                     value.logs
               )
             ]
        )