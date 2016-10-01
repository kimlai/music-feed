module Api exposing (..)


import Http
import Json.Decode
import Json.Decode exposing ((:=))
import Json.Decode.Extra exposing ((|:))
import Json.Encode
import Model exposing (Track, StreamingInfo(..), TrackId)
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
        |: ("id" := Json.Decode.string)
        |: ("artist" := Json.Decode.string)
        |: ("cover" := Json.Decode.Extra.withDefault "/images/placeholder.jpg" Json.Decode.string)
        |: ("title" := Json.Decode.string)
        |: decodeStreamingInfo
        |: ("source" := Json.Decode.string)
        |: ("created_at" := Json.Decode.Extra.date)
        |: Json.Decode.succeed 0
        |: Json.Decode.succeed 0
        |: Json.Decode.succeed False


decodeStreamingInfo : Json.Decode.Decoder StreamingInfo
decodeStreamingInfo =
    Json.Decode.oneOf [ decodeSoundcloudStreamingInfo, decodeYoutubeStreamingInfo ]


decodeSoundcloudStreamingInfo : Json.Decode.Decoder StreamingInfo
decodeSoundcloudStreamingInfo =
    (Json.Decode.at [ "soundcloud", "stream_url" ] Json.Decode.string)
    `Json.Decode.andThen` \url -> Json.Decode.succeed (Soundcloud url)


decodeYoutubeStreamingInfo : Json.Decode.Decoder StreamingInfo
decodeYoutubeStreamingInfo =
    (Json.Decode.at [ "youtube", "id" ] Json.Decode.string)
    `Json.Decode.andThen` \id -> Json.Decode.succeed (Youtube id)


addTrack : String -> TrackId -> Task Http.Error String
addTrack addTrackUrl trackId =
    Http.send
        Http.defaultSettings
        { verb = "POST"
        , headers = [ ( "Content-Type", "application/json" ) ]
        , url = addTrackUrl
        , body = (addTrackBody trackId)
        }
        |> Http.fromJson (Json.Decode.succeed "ok")


addTrackBody : TrackId -> Http.Body
addTrackBody trackId =
    Json.Encode.object
        [ ( "soundcloudTrackId", Json.Encode.string trackId ) ]
        |> Json.Encode.encode 0
        |> Http.string


publishTrack : Track -> Task Http.Error Track
publishTrack track =
    Http.send
        Http.defaultSettings
        { verb = "POST"
        , headers = [ ( "Content-Type", "application/json" ) ]
        , url = "/feed/publish_custom_track"
        , body = (publishTrackBody track)
        }
        |> Http.fromJson decodeTrack


publishTrackBody : Track -> Http.Body
publishTrackBody track =
    let
        streamInfo =
            case track.streamingInfo of
                Soundcloud url ->
                    [ ( "soundcloud" , Json.Encode.object [ ( "stream_url", Json.Encode.string url ) ] ) ]
                Youtube youtubeId ->
                    [ ( "youtube" , Json.Encode.object [ ( "id", Json.Encode.string youtubeId ) ] ) ]
    in
            [ ( "artist", Json.Encode.string track.artist )
            , ( "title", Json.Encode.string track.title )
            , ( "source", Json.Encode.string track.sourceUrl )
            , ( "cover", Json.Encode.string track.artwork_url )
            ]
            |> (++) streamInfo
            |> Json.Encode.object
            |> Json.Encode.encode 0
            |> Http.string


reportDeadTrack : TrackId -> Task Http.Error String
reportDeadTrack trackId =
    Http.send
        Http.defaultSettings
        { verb = "POST"
        , headers = [ ( "Content-Type", "application/json" ) ]
        , url = "/report-dead-track"
        , body = (reportDeadTrackBody trackId)
        }
        |> Http.fromJson (Json.Decode.succeed "ok")


reportDeadTrackBody : TrackId -> Http.Body
reportDeadTrackBody trackId =
    [ ( "trackId", Json.Encode.string trackId ) ]
    |> Json.Encode.object
    |> Json.Encode.encode 0
    |> Http.string
