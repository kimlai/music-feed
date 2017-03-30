module Api exposing (..)


import Http
import Json.Decode exposing (field)
import Json.Decode.Extra exposing ((|:))
import Json.Encode
import Model exposing (Track, StreamingInfo(..), TrackId)
import Radio.SignupForm exposing (Field(..))
import Radio.LoginForm as LoginForm
import Task exposing (Task)


fetchPlaylist : String -> Json.Decode.Decoder Track -> Http.Request ( List Track, String )
fetchPlaylist url trackDecoder =
    Http.get url (decodePlaylist trackDecoder)


decodePlaylist : Json.Decode.Decoder Track -> Json.Decode.Decoder ( List Track, String )
decodePlaylist trackDecoder =
    Json.Decode.map2 (,)
        (field "tracks" (Json.Decode.list trackDecoder))
        (field "next_href" Json.Decode.string)


decodeTrack : Json.Decode.Decoder Track
decodeTrack =
    Json.Decode.succeed Track
        |: (field "id" Json.Decode.string)
        |: (field "artist" Json.Decode.string)
        |: (field "cover" (Json.Decode.Extra.withDefault "/images/placeholder.jpg" Json.Decode.string))
        |: (field "title" Json.Decode.string)
        |: decodeStreamingInfo
        |: (field "source" Json.Decode.string)
        |: (field "created_at" Json.Decode.Extra.date)
        |: Json.Decode.succeed 0
        |: Json.Decode.succeed 0
        |: Json.Decode.succeed False


decodeStreamingInfo : Json.Decode.Decoder StreamingInfo
decodeStreamingInfo =
    Json.Decode.oneOf [ decodeSoundcloudStreamingInfo, decodeYoutubeStreamingInfo ]


decodeSoundcloudStreamingInfo : Json.Decode.Decoder StreamingInfo
decodeSoundcloudStreamingInfo =
    (Json.Decode.at [ "soundcloud", "stream_url" ] Json.Decode.string)
        |> Json.Decode.andThen (\url -> Json.Decode.succeed (Soundcloud url))


decodeYoutubeStreamingInfo : Json.Decode.Decoder StreamingInfo
decodeYoutubeStreamingInfo =
    (Json.Decode.at [ "youtube", "id" ] Json.Decode.string)
        |> Json.Decode.andThen (\id -> Json.Decode.succeed (Youtube id))


addTrack : String -> TrackId -> Http.Request String
addTrack addTrackUrl trackId =
    Http.post
        addTrackUrl
        (addTrackBody trackId)
        (Json.Decode.succeed "ok")


addTrackBody : TrackId -> Http.Body
addTrackBody trackId =
    Json.Encode.object
        [ ( "soundcloudTrackId", Json.Encode.string trackId ) ]
        |> Http.jsonBody


publishTrack : Track -> Http.Request Track
publishTrack track =
    Http.post
        "/feed/publish_custom_track"
        (publishTrackBody track)
        decodeTrack


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
            |> Http.jsonBody


reportDeadTrack : TrackId -> Http.Request String
reportDeadTrack trackId =
    Http.post
        "/report-dead-track"
        (reportDeadTrackBody trackId)
        (Json.Decode.succeed "ok")


reportDeadTrackBody : TrackId -> Http.Body
reportDeadTrackBody trackId =
    [ ( "trackId", Json.Encode.string trackId ) ]
    |> Json.Encode.object
    |> Http.jsonBody


checkEmailAvailabilty : String -> String -> Http.Request ( ( String, Bool ), ( String, Bool ) )
checkEmailAvailabilty email username =
    Http.post
        "/api/email-availability"
        (checkEmailAvailabiltyBody email username)
        (decodeEmailAvailability email username)


checkEmailAvailabiltyBody : String -> String -> Http.Body
checkEmailAvailabiltyBody email username =
    [ ( "email", Json.Encode.string email )
    , ( "username", Json.Encode.string username )
    ]
    |> Json.Encode.object
    |> Http.jsonBody


decodeEmailAvailability : String -> String -> Json.Decode.Decoder ( ( String, Bool ), ( String, Bool ) )
decodeEmailAvailability email username =
    Json.Decode.map2 (,)
        (field "email" Json.Decode.bool
            |> Json.Decode.andThen (\availability -> Json.Decode.succeed ( email, availability ))
        )
        (field "username" Json.Decode.bool
            |> Json.Decode.andThen (\availability -> Json.Decode.succeed ( username, availability ))
        )


signup : { a | email : String, username : String, password : String } -> Http.Request String
signup params =
    Http.post
        "/api/users"
        (signupBody params)
        (Json.Decode.succeed "ok")


signupBody : { a | email : String, username : String, password : String } -> Http.Body
signupBody { email, username, password } =
    [ ( "email", Json.Encode.string email )
    , ( "username", Json.Encode.string username )
    , ( "password", Json.Encode.string password )
    ]
    |> Json.Encode.object
    |> Http.jsonBody


decodeSignupErrors : Json.Decode.Decoder (List ( Field, String ))
decodeSignupErrors =
    Json.Decode.map2 (,)
        (field "field" decodeSignupErrorField)
        (field "error" Json.Decode.string)
    |> Json.Decode.list



decodeSignupErrorField : Json.Decode.Decoder Field
decodeSignupErrorField =
    Json.Decode.string
    |> Json.Decode.andThen
        (\value ->
            case value of
                "email" -> Json.Decode.succeed Email
                "username" -> Json.Decode.succeed Username
                _ -> Json.Decode.fail "Unkown field"
        )


login : { a | emailOrUsername : String, password : String } -> Http.Request String
login params =
    Http.post
        "/api/login"
        (loginBody params)
        (Json.Decode.succeed "ok")


loginBody : { a | emailOrUsername : String, password : String } -> Http.Body
loginBody { emailOrUsername, password } =
    [ ( "usernameOrEmail", Json.Encode.string emailOrUsername )
    , ( "password", Json.Encode.string password )
    ]
    |> Json.Encode.object
    |> Http.jsonBody


decodeLoginErrors : Json.Decode.Decoder (List ( LoginForm.Field, String ))
decodeLoginErrors =
    Json.Decode.map2 (,)
        (field "field" decodeLoginErrorField)
        (field "error" Json.Decode.string)
    |> Json.Decode.list



decodeLoginErrorField : Json.Decode.Decoder LoginForm.Field
decodeLoginErrorField =
    Json.Decode.string
    |> Json.Decode.andThen
        (\value ->
            case value of
                "emailOrUsername" -> Json.Decode.succeed LoginForm.EmailorUsername
                "password" -> Json.Decode.succeed LoginForm.Password
                _ -> Json.Decode.fail "Unkown field"
        )
