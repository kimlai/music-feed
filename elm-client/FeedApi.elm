module FeedApi exposing(..)

import Dict exposing (Dict)
import Playlist exposing (Track, TrackId)
import Http
import Json.Decode
import Json.Decode exposing ((:=))
import Json.Decode.Extra exposing ((|:))
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
        , body = ( blacklistBody trackId )
        }
        |> Http.fromJson ( Json.Decode.succeed "ok" )



blacklistBody : TrackId -> Http.Body
blacklistBody trackId =
    Json.Encode.object
        [ ( "soundcloudTrackId", Json.Encode.int trackId ) ]
        |> Json.Encode.encode 0
        |> Http.string
