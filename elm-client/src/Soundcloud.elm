module Soundcloud exposing (..)


import Api exposing (decodeTrack)
import Http
import Json.Decode
import Json.Decode exposing ((:=))
import Json.Decode.Extra exposing ((|:))
import Model exposing (Track, StreamingInfo(..))
import Task exposing (Task)


resolve : String -> String -> Task Http.Error Track
resolve clientId url =
    Http.get
        decodeTrack
        ("https://api.soundcloud.com/resolve?url=" ++ url ++ "&client_id=" ++ clientId)


decodeTrack : Json.Decode.Decoder Track
decodeTrack =
    Json.Decode.succeed Track
        |: (("id" := Json.Decode.int) |> Json.Decode.map toString)
        |: (Json.Decode.at [ "user", "username" ] Json.Decode.string)
        |: ("artwork_url" := Json.Decode.Extra.withDefault "/images/placeholder.jpg" Json.Decode.string)
        |: ("title" := Json.Decode.string)
        |: (("stream_url" := Json.Decode.string) `Json.Decode.andThen` \url -> Json.Decode.succeed (Soundcloud url))
        |: ("permalink_url" := Json.Decode.string)
        |: ("created_at" := Json.Decode.Extra.date)
        |: Json.Decode.succeed 0
        |: Json.Decode.succeed 0
        |: Json.Decode.succeed False
