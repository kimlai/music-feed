port module Main exposing (..)

import ApiTest
import Test.Runner.Node exposing (run)
import Json.Encode exposing (Value)


main : Program Value
main =
    run emit ApiTest.all


port emit : ( String, Value ) -> Cmd msg
