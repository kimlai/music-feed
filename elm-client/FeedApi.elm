module FeedApi exposing(..)

import Playlist exposing (Track, TrackId)
import Http
import Json.Decode
import Json.Decode exposing ((:=))
import Json.Encode
import Task exposing (Task)



-- HTTP


blacklist : TrackId -> Task Http.Error String
blacklist trackId =
    Http.send
        Http.defaultSettings
        { verb = "POST"
        , headers = [ ( "Content-Type", "application/json" ) ]
        , url = "/blacklist"
        , body = ( body trackId )
        }
        |> Http.fromJson ( Json.Decode.succeed "ok" )


save : TrackId -> Task Http.Error String
save trackId =
    Http.send
        Http.defaultSettings
        { verb = "POST"
        , headers = [ ( "Content-Type", "application/json" ) ]
        , url = "/save_track"
        , body = ( body trackId )
        }
        |> Http.fromJson ( Json.Decode.succeed "ok" )


body trackId =
    Json.Encode.object
        [ ( "soundcloudTrackId", Json.Encode.int trackId ) ]
        |> Json.Encode.encode 0
        |> Http.string
