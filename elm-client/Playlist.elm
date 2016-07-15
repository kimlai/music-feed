module Playlist exposing (..)


import Dict exposing (Dict)
import Html exposing (Html, text, div, img)
import Html.Attributes exposing (class, href, src, style)
import Html.Events exposing (onClick)
import Json.Decode
import Json.Decode exposing ((:=))
import Json.Decode.Extra exposing ((|:))
import Http
import Task exposing (Task)


type alias Track =
    { id : TrackId
    , artist : String
    , artwork_url : String
    , title : String
    , streamUrl : String
    , progress : Float
    , currentTime : Float
    }


type alias TrackId = Int


type alias Model =
    { trackIds : List TrackId
    , loading : Bool
    , nextLink : String
    }


initialModel : String -> Model
initialModel initialUrl =
    { trackIds = []
    , loading = True
    , nextLink = initialUrl
    }


initialCmd : String -> Cmd Msg
initialCmd initialUrl =
    fetchMore initialUrl

-- UPDATE


type Msg
    = FetchFeedSuccess ( List Track, String )
    | FetchFeedFail Http.Error
    | FetchMore
    | TogglePlaybackFromFeed Int Track


type Event
    = NewTracksWereFetched ( List Track, String )
    | TrackWasClicked Int Track


update : Msg -> Model -> ( Model, Cmd Msg, Maybe Event )
update message model =
    case message of
        FetchFeedSuccess ( tracks, nextLink ) ->
            ( { model
                | trackIds = List.append model.trackIds ( List.map .id tracks )
                , nextLink = nextLink
                , loading = False
              }
            , Cmd.none
            , Just ( NewTracksWereFetched ( tracks, nextLink ) )
            )
        FetchFeedFail error ->
            ( { model | loading = False }
            , Cmd.none
            , Nothing
            )
        FetchMore ->
            ( { model | loading = True }
            , fetchMore model.nextLink
            , Nothing
            )
        TogglePlaybackFromFeed position track ->
            ( model
            , Cmd.none
            , Just ( TrackWasClicked position track )
            )


-- VIEW


view : Dict TrackId Track -> Model -> Html Msg
view tracks model =
    let
        feedTracks =
            List.filterMap ( \trackId -> Dict.get trackId tracks ) model.trackIds
        tracksView =
            List.indexedMap viewTrack feedTracks
    in
        if model.loading == True then
            List.repeat 10 viewTrackPlaceHolder
                |> List.append tracksView
                |> div []
        else
            [ viewMoreButton ]
                |> List.append tracksView
                |> div []


viewTrack : Int -> Track -> Html Msg
viewTrack position track =
    div
        [ class "track"
        , onClick ( TogglePlaybackFromFeed position track )
        ]
        [ div
            [ class "track-info-container" ]
            [ img
                [ src track.artwork_url ]
                []
            , div
                [ class "track-info" ]
                [ div [] [ text track.artist ]
                , div [] [ text track.title ]
                ]
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
    fetch nextLink
        |> Task.perform FetchFeedFail FetchFeedSuccess


fetch : String -> Task Http.Error ( List Track, String )
fetch nextLink =
    Http.get decodeFeed nextLink


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
        |: Json.Decode.succeed 0
        |: Json.Decode.succeed 0
