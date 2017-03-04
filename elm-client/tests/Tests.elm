module Tests exposing (..)

import ApiTest
import ViewTest
import YoutubeTest
import Test exposing (..)
import Expect
import Fuzz exposing (list, int, tuple, string)
import String


all : Test
all =
    concat
        [ ApiTest.all
        , ViewTest.all
        , YoutubeTest.all
        ]
