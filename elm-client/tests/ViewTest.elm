module ViewTest exposing (..)

import Expect
import Json.Decode
import Test exposing (..)
import View


all : Test
all =
    describe "View"
        [ test "it can decode the X position of a click relatively to the target" <|
            \() ->
                let
                    event =
                        """
                        { "pageX": 40
                        , "target":
                            { "offsetWidth": 10
                            , "offsetLeft": 20
                            , "offsetParent" :
                                { "offsetLeft": 10
                                , "offsetParent": null
                                }
                            }
                        }
                        """
                in
                    Json.Decode.decodeString View.decodeClickXPosition event
                        |> Expect.equal (Ok 100)

        ]
