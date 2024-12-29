module GenerationUtils exposing (testGenerationForType)

import Codegen.CodegenResult as CodegenResult
import Codegen.Generate as Generate
import Codegen.Parser
import Dict
import Elm
import Elm.ToString
import Expect
import String.Multiline
import Test exposing (Test, test)


testGenerationForType : String -> String -> List String -> Test
testGenerationForType label input outputs =
    test label <|
        \_ ->
            case
                Codegen.Parser.parseFile { package = False, fullPath = "<test>" }
                    ("module " ++ fakeModule ++ " exposing (..)\n" ++ String.Multiline.here input)
            of
                Err e ->
                    Expect.fail e.description

                Ok parsedFile ->
                    case Dict.toList parsedFile of
                        [ ( name, _ ) ] ->
                            case Generate.generate { debug = True, generateStubs = True } (Dict.singleton [ fakeModule ] parsedFile) ( [ fakeModule ], Generate.Custom name ) of
                                CodegenResult.CodegenErr e ->
                                    Expect.fail e.body

                                CodegenResult.CodegenLoadFile missing ->
                                    Expect.fail <| "Unexpected missing file: " ++ String.join "." missing

                                CodegenResult.CodegenOk content ->
                                    let
                                        actual : List String
                                        actual =
                                            content.declarations
                                                |> Dict.values
                                                |> List.concatMap Dict.values
                                                |> List.map declarationToString

                                        expected : List String
                                        expected =
                                            List.map String.Multiline.here outputs

                                        check : List String -> List String -> Expect.Expectation
                                        check actualQueue expectedQueue =
                                            case ( actualQueue, expectedQueue ) of
                                                ( [], [] ) ->
                                                    Expect.pass

                                                ( actualHead :: actualTail, expectedHead :: expectedTail ) ->
                                                    if equalsModuloWs actualHead expectedHead then
                                                        check actualTail expectedTail

                                                    else
                                                        actualHead |> Expect.equal expectedHead

                                                ( [], _ ) ->
                                                    Expect.fail "Less items than expected"

                                                ( _, [] ) ->
                                                    Expect.fail "More items than expected"
                                    in
                                    check actual expected

                        _ ->
                            Expect.fail "Use a single type as input"


equalsModuloWs : String -> String -> Bool
equalsModuloWs actual expected =
    List.map String.trim (String.split "\n" actual)
        == List.map String.trim (String.split "\n" expected)


declarationToString : Elm.Declaration -> String
declarationToString declaration =
    (Elm.ToString.declaration declaration).body


fakeModule : String
fakeModule =
    "FakeModule"
