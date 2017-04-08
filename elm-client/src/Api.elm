module Api exposing (..)


import Http
import Json.Decode exposing (field)
import Json.Decode.Extra exposing ((|:))
import Json.Encode
import Radio.Model exposing (ConnectedUser)
import Radio.SignupForm exposing (Field(..))
import Radio.LoginForm as LoginForm
import Task exposing (Task)
import Track exposing (Track, TrackId, StreamingInfo(..))


fetchPlaylist : Maybe String -> String -> Json.Decode.Decoder Track -> Http.Request ( List Track, Maybe String )
fetchPlaylist authToken url trackDecoder =
    let
        headers =
            authToken
                |> Maybe.map (\authToken -> [ Http.header "Authorization" ("Bearer " ++ authToken) ])
                |> Maybe.withDefault []
    in
        Http.request
            { method = "GET"
            , headers = headers
            , url = url
            , body = Http.emptyBody
            , expect = Http.expectJson (decodePlaylist trackDecoder)
            , timeout = Nothing
            , withCredentials = False
            }


fetchFeedPlaylist : String -> Json.Decode.Decoder Track -> Http.Request ( List Track, Maybe String )
fetchFeedPlaylist url trackDecoder =
        Http.get url (decodePlaylist trackDecoder)


decodePlaylist : Json.Decode.Decoder Track -> Json.Decode.Decoder ( List Track, Maybe String )
decodePlaylist trackDecoder =
    Json.Decode.map2 (,)
        (field "tracks" (Json.Decode.list trackDecoder))
        (field "next_href" (Json.Decode.nullable Json.Decode.string))


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
        |: (field "liked" (Json.Decode.Extra.withDefault False Json.Decode.bool))
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


login : String -> String -> Http.Request String
login usernameOrEmail password =
    Http.post
        "/api/login"
        (loginBody usernameOrEmail password)
        (Json.Decode.field "token" Json.Decode.string)


loginBody : String -> String -> Http.Body
loginBody emailOrUsername password =
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


whoAmI : String -> Http.Request ConnectedUser
whoAmI token =
    Http.request
        { method = "GET"
        , headers = [ Http.header "Authorization" ("Bearer " ++ token) ]
        , url = "/api/me"
        , body = Http.emptyBody
        , expect = Http.expectJson decodeConnectedUser
        , timeout = Nothing
        , withCredentials = False
        }


decodeConnectedUser : Json.Decode.Decoder ConnectedUser
decodeConnectedUser =
    Json.Decode.succeed ConnectedUser
        |: (field "username" Json.Decode.string)
        |: (field "email" Json.Decode.string)


addLike : String -> TrackId -> Http.Request String
addLike token trackId =
    Http.request
        { method = "POST"
        , headers = [ Http.header "Authorization" ("Bearer " ++ token) ]
        , url = "/api/likes"
        , body = addLikeBody trackId
        , expect = Http.expectJson (Json.Decode.succeed "OK")
        , timeout = Nothing
        , withCredentials = False
        }


addLikeBody : String -> Http.Body
addLikeBody trackId =
    [ ( "trackId", Json.Encode.string trackId ) ]
    |> Json.Encode.object
    |> Http.jsonBody


removeLike : String -> TrackId -> Http.Request String
removeLike token trackId =
    Http.request
        { method = "DELETE"
        , headers = [ Http.header "Authorization" ("Bearer " ++ token) ]
        , url = "/api/likes"
        , body = removeLikeBody trackId
        , expect = Http.expectJson (Json.Decode.succeed "OK")
        , timeout = Nothing
        , withCredentials = False
        }


removeLikeBody : String -> Http.Body
removeLikeBody trackId =
    [ ( "trackId", Json.Encode.string trackId ) ]
    |> Json.Encode.object
    |> Http.jsonBody
