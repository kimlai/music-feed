module Api exposing (..)


import Http
import Json.Decode
import Json.Decode exposing ((:=))
import Json.Decode.Extra exposing ((|:))
import Json.Encode
import Model exposing (Track)
import Task exposing (Task)


fetchPlaylist : String -> Json.Decode.Decoder Track -> Task Http.Error ( List Track, String )
fetchPlaylist url trackDecoder =
    Http.get (decodePlaylist trackDecoder) url


decodePlaylist : Json.Decode.Decoder Track -> Json.Decode.Decoder ( List Track, String )
decodePlaylist trackDecoder =
    Json.Decode.object2 (,)
        ("tracks" := Json.Decode.list trackDecoder)
        ("next_href" := Json.Decode.string)


decodeTrack : Json.Decode.Decoder Track
decodeTrack =
    Json.Decode.succeed Track
        |: ("id" := Json.Decode.int)
        |: ("artist" := Json.Decode.string)
        |: ("cover" := Json.Decode.Extra.withDefault "/images/placeholder.jpg" Json.Decode.string)
        |: ("title" := Json.Decode.string)
        |: (Json.Decode.at [ "soundcloud", "stream_url" ] Json.Decode.string)
        |: ("source" := Json.Decode.string)
        |: ("created_at" := Json.Decode.Extra.date)
        |: Json.Decode.succeed 0
        |: Json.Decode.succeed 0
        |: Json.Decode.succeed False


addTrack : String -> Int -> Task Http.Error String
addTrack addTrackUrl trackId =
    Http.send
        Http.defaultSettings
        { verb = "POST"
        , headers = [ ( "Content-Type", "application/json" ) ]
        , url = addTrackUrl
        , body = (addTrackBody trackId)
        }
        |> Http.fromJson (Json.Decode.succeed "ok")


addTrackBody : Int -> Http.Body
addTrackBody trackId =
    Json.Encode.object
        [ ( "soundcloudTrackId", Json.Encode.int trackId ) ]
        |> Json.Encode.encode 0
        |> Http.string
