module Playlist exposing (..)


import Date exposing (Date)
import Dict exposing (Dict)
import Html exposing (Html, text, div, img)
import Html.Attributes exposing (class, href, src, style)
import Html.Events exposing (onClick, onWithOptions)
import Http
import Json.Decode
import Json.Decode exposing ((:=))
import Json.Decode.Extra exposing ((|:))
import Json.Encode
import Task exposing (Task)
import Time exposing (Time)


type alias Track =
    { id : TrackId
    , artist : String
    , artwork_url : String
    , title : String
    , streamUrl : String
    , createdAt : Date
    , progress : Float
    , currentTime : Float
    }


type alias TrackId = Int


type alias Model =
    { trackIds : List TrackId
    , loading : Bool
    , nextLink : String
    , addTrackUrl : String
    }


initialModel : String -> String -> Model
initialModel initialUrl addTrackUrl =
    { trackIds = []
    , loading = True
    , nextLink = initialUrl
    , addTrackUrl = addTrackUrl
    }


initialCmd : String -> Cmd Msg
initialCmd initialUrl =
    fetchMore initialUrl

-- UPDATE


type Msg
    = FetchSuccess ( List Track, String )
    | FetchFail Http.Error
    | FetchMore
    | OnTrackClicked Int Track
    | RemoveTrack TrackId
    | AddTrack TrackId
    | AddTrackFail Http.Error
    | AddTrackSuccess
    | OnAddTrackToCustomQueueClicked TrackId


type Event
    = NewTracksWereFetched ( List Track, String )
    | TrackWasClicked Int Track
    | TrackWasAddedToCustomQueue TrackId


update : Msg -> Model -> ( Model, Cmd Msg, Maybe Event )
update message model =
    case message of
        FetchSuccess ( tracks, nextLink ) ->
            ( { model
                | trackIds = List.append model.trackIds ( List.map .id tracks )
                , nextLink = nextLink
                , loading = False
              }
            , Cmd.none
            , Just ( NewTracksWereFetched ( tracks, nextLink ) )
            )
        FetchFail error ->
            ( { model | loading = False }
            , Cmd.none
            , Nothing
            )
        FetchMore ->
            ( { model | loading = True }
            , fetchMore model.nextLink
            , Nothing
            )
        RemoveTrack trackId ->
            ( { model | trackIds = List.filter ((/=) trackId) model.trackIds }
            , Cmd.none
            , Nothing
            )
        AddTrack trackId ->
            ( { model | trackIds = trackId :: model.trackIds }
            , addTrack model.addTrackUrl trackId
            , Nothing
            )
        AddTrackFail error ->
            ( model
            , Cmd.none
            , Nothing
            )
        AddTrackSuccess ->
            ( model
            , Cmd.none
            , Nothing
            )
        OnTrackClicked position track ->
            ( model
            , Cmd.none
            , Just ( TrackWasClicked position track )
            )
        OnAddTrackToCustomQueueClicked trackId ->
            ( model
            , Cmd.none
            , Just ( TrackWasAddedToCustomQueue trackId )
            )



-- VIEW


view : Maybe Time -> Dict TrackId Track -> Model -> Html Msg
view currentTime tracks model =
    let
        feedTracks =
            List.filterMap ( \trackId -> Dict.get trackId tracks ) model.trackIds
        tracksView =
            List.indexedMap ( viewTrack currentTime ) feedTracks
    in
        if model.loading == True then
            List.repeat 10 viewTrackPlaceHolder
                |> List.append tracksView
                |> div []
        else
            [ viewMoreButton ]
                |> List.append tracksView
                |> div []


viewTrack : Maybe Time -> Int -> Track -> Html Msg
viewTrack currentTime position track =
    div
        [ class "track"
        , onClick ( OnTrackClicked position track )
        ]
        [ div
            [ class "track-info-container" ]
            [ img [ src track.artwork_url ]
                []
            , div
                []
                [ div
                    [ class "track-info" ]
                    [ div [] [ text track.artist ]
                    , div [] [ text track.title ]
                    ]
                , div
                    [ class "actions" ]
                    [ div
                        [ onWithOptions
                            "click"
                            { stopPropagation = True
                            , preventDefault = True
                            }
                            ( Json.Decode.succeed (OnAddTrackToCustomQueueClicked track.id ) )
                        ]
                        [ text "Add to queue" ]
                    ]
                ]
            , div
                [ class "time-ago" ]
                [ text ( timeAgo currentTime track.createdAt ) ]
            ]
        , div
            [ class "progress-bar" ]
            [ div
                [ class "outer" ]
                [ div
                    [ class "inner"
                    , style [ ("width", ( toString track.progress ) ++ "%" ) ]
                    ]
                    []
                ]
            ]
        ]


timeAgo : Maybe Time -> Date -> String
timeAgo currentTime date =
    case currentTime of
        Nothing ->
            ""
        Just time ->
            let
                timeAgo = time - Date.toTime date
                day = 24 * Time.hour
                week = 7 * day
                month = 30 * day
                year = 365 * day
                inUnitAgo value ( unitName, unit ) =
                    let
                        valueInUnit =
                            value / unit |> floor
                        pluralize value string =
                            if value > 1 then
                                string ++ "s"
                            else
                                string ++ ""
                    in
                    if valueInUnit == 0 then
                        Nothing
                    else
                        Just ( toString valueInUnit ++ " " ++ ( pluralize valueInUnit unitName ) ++ " ago" )
            in
                Maybe.oneOf
                    ( List.map
                        ( inUnitAgo timeAgo )
                        [ ( "year", year )
                        , ( "month", month )
                        , ( "week", week )
                        , ( "day", day )
                        , ( "hour", Time.hour )
                        , ( "minute" , Time.minute )
                        ]
                    )
                    |> Maybe.withDefault "more than a week ago"


viewTrackPlaceHolder : Html Msg
viewTrackPlaceHolder =
    div
        [ class "track" ]
        [ div
            [ class "track-info-container" ]
            [ img [ src "/images/placeholder.jpg" ] [] ]
        , div
            [ class "progress-bar" ]
            [ div [ class "outer" ] [] ]
        ]


viewMoreButton : Html Msg
viewMoreButton =
    div
        [ class "more-button"
        , onClick FetchMore
        ]
        [ text "More" ]




-- HTTP


fetchMore : String -> Cmd Msg
fetchMore nextLink =
    Http.get decodeFeed nextLink
        |> Task.perform FetchFail FetchSuccess


decodeFeed : Json.Decode.Decoder ( List Track, String )
decodeFeed =
    Json.Decode.object2 (,)
        ( "tracks" := Json.Decode.list decodeTrack )
        ( "next_href" := Json.Decode.string )


decodeTrack : Json.Decode.Decoder Track
decodeTrack =
    Json.Decode.succeed Track
        |: ("id" := Json.Decode.int)
        |: (Json.Decode.at [ "user", "username" ] Json.Decode.string)
        |: ("artwork_url" := Json.Decode.Extra.withDefault "/images/placeholder.jpg" Json.Decode.string)
        |: ("title" := Json.Decode.string)
        |: ("stream_url" := Json.Decode.string)
        |: ("created_at" := Json.Decode.Extra.date)
        |: Json.Decode.succeed 0
        |: Json.Decode.succeed 0


addTrack : String -> Int -> Cmd Msg
addTrack addTrackUrl trackId =
    Http.send
        Http.defaultSettings
        { verb = "POST"
        , headers = [ ( "Content-Type", "application/json" ) ]
        , url = addTrackUrl
        , body = ( addTrackBody trackId )
        }
        |> Http.fromJson ( Json.Decode.succeed "ok" )
        |> Task.perform AddTrackFail ( \_ -> AddTrackSuccess )


addTrackBody : Int -> Http.Body
addTrackBody trackId =
    Json.Encode.object
        [ ( "soundcloudTrackId", Json.Encode.int trackId ) ]
        |> Json.Encode.encode 0
        |> Http.string
