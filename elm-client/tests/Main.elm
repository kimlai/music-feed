port module Main exposing (..)

import ApiTest
import YoutubeTest
import Test exposing (concat)
import Test.Runner.Node exposing (run)
import Json.Encode exposing (Value)


main : Program Value
main =
    run emit
        ( concat
            [ ApiTest.all
            , YoutubeTest.all
            ]
        )


port emit : ( String, Value ) -> Cmd msg
