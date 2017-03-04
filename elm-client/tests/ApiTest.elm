module ApiTest exposing (..)

import Api
import Date
import Expect
import Json.Decode
import Model exposing (StreamingInfo(..))
import String
import Test exposing (..)


all : Test
all =
    describe "Decoding Tracks"
        [ test "Soundcloud tracks" <|
            \() ->
                Json.Decode.decodeString
                    Api.decodeTrack
                    """
                    { "cover":"https://i1.sndcdn.com/artworks-000179793600-5aot2t-large.jpg"
                    , "title":"Zerolex"
                    , "artist":"LeMellotron"
                    , "source":"http://soundcloud.com/lemellotron/zerolex-family-tree"
                    , "created_at":"2016/08/31 14:59:31 +0000"
                    , "soundcloud":
                        { "id":280751017
                        , "stream_url":"https://api.soundcloud.com/tracks/280751017/stream"
                        }
                    , "saved_at":"2016-09-11T14:31:20.465Z"
                    , "id":"280751017"
                    }
                    """
                    |> Result.toMaybe
                    |> Expect.equal
                        (Just { id = "280751017"
                        , artist = "LeMellotron"
                        , artwork_url = "https://i1.sndcdn.com/artworks-000179793600-5aot2t-large.jpg"
                        , title = "Zerolex"
                        , streamingInfo = Soundcloud "https://api.soundcloud.com/tracks/280751017/stream"
                        , sourceUrl = "http://soundcloud.com/lemellotron/zerolex-family-tree"
                        , createdAt = Date.fromTime 1472655571000
                        , progress = 0
                        , currentTime = 0
                        , error = False
                        })

        , test "Youtube tracks" <|
            \() ->
                Json.Decode.decodeString
                    Api.decodeTrack
                    """
                    { "cover":"https://i1.sndcdn.com/artworks-000179793600-5aot2t-large.jpg"
                    , "title":"Zerolex"
                    , "artist":"LeMellotron"
                    , "source":"http://soundcloud.com/lemellotron/zerolex-family-tree"
                    , "created_at":"2016/08/31 14:59:31 +0000"
                    , "youtube":
                        { "id":"fakeYoutubeId" }
                    , "saved_at":"2016-09-11T14:31:20.465Z"
                    , "id":"280751017"
                    }
                    """
                    |> Result.toMaybe
                    |> Expect.equal
                        (Just { id = "280751017"
                        , artist = "LeMellotron"
                        , artwork_url = "https://i1.sndcdn.com/artworks-000179793600-5aot2t-large.jpg"
                        , title = "Zerolex"
                        , streamingInfo = Youtube "fakeYoutubeId"
                        , sourceUrl = "http://soundcloud.com/lemellotron/zerolex-family-tree"
                        , createdAt = Date.fromTime 1472655571000
                        , progress = 0
                        , currentTime = 0
                        , error = False
                        })
        ]
