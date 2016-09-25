module YoutubeTest exposing (..)

import Expect
import Test exposing (..)
import Youtube


all : Test
all =
    describe "Youtube"
        [ test "extract youtube id from url" <|
            \() ->
                Youtube.extractYoutubeIdFromUrl "https://www.youtube.com/watch?v=-mlg-fFJZGA"
                    |> Expect.equal (Just "-mlg-fFJZGA")
        ]
