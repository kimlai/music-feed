module Soundcloud exposing (..)


import Api exposing (decodeTrack)
import Http
import Json.Decode
import Json.Decode exposing (field)
import Json.Decode.Extra exposing ((|:))
import Model exposing (Track, StreamingInfo(..))
import Task exposing (Task)


resolve : String -> String -> Http.Request Track
resolve clientId url =
    Http.get
        ("https://api.soundcloud.com/resolve?url=" ++ url ++ "&client_id=" ++ clientId)
        decodeTrack


decodeTrack : Json.Decode.Decoder Track
decodeTrack =
    Json.Decode.succeed Track
        |: ((field "id" Json.Decode.int) |> Json.Decode.map toString)
        |: (Json.Decode.at [ "user", "username" ] Json.Decode.string)
        |: (field "artwork_url" (Json.Decode.Extra.withDefault "/images/placeholder.jpg" Json.Decode.string))
        |: (field "title" Json.Decode.string)
        |: ((field "stream_url" Json.Decode.string)
            |> Json.Decode.andThen (\url -> Json.Decode.succeed (Soundcloud url)))
        |: (field "permalink_url" Json.Decode.string)
        |: (field "created_at" Json.Decode.Extra.date)
        |: Json.Decode.succeed False
        |: Json.Decode.succeed 0
        |: Json.Decode.succeed 0
        |: Json.Decode.succeed False
