module FeedApi exposing(..)

import Dict exposing (Dict)
import Feed exposing (Track, TrackId)
import Http
import Json.Decode
import Json.Decode exposing ((:=))
import Json.Decode.Extra exposing ((|:))
import Json.Encode
import Task exposing (Task)


type alias FetchFeedPayload =
    { tracks : List Track
    , nextLink : String
    }



-- HTTP


fetch : Maybe String -> Task Http.Error FetchFeedPayload
fetch nextLink =
    Http.get decodeFeed ( Maybe.withDefault "/feed" nextLink )


decodeFeed : Json.Decode.Decoder FetchFeedPayload
decodeFeed =
    Json.Decode.succeed FetchFeedPayload
        |: ( "tracks" := Json.Decode.list decodeTrack )
        |: ( "next_href" := Json.Decode.string )


decodeTrack : Json.Decode.Decoder Track
decodeTrack =
    Json.Decode.succeed Track
        |: ("id" := Json.Decode.int)
        |: (Json.Decode.at [ "user", "username" ] Json.Decode.string)
        |: ("artwork_url" := Json.Decode.Extra.withDefault "/images/placeholder.jpg" Json.Decode.string)
        |: ("title" := Json.Decode.string)
        |: ("stream_url" := Json.Decode.string)
        |: Json.Decode.succeed 0
        |: Json.Decode.succeed 0


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
