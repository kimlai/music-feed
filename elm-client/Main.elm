port module Main exposing(..)

import Dict exposing (Dict)
import Html exposing (Html, a, nav, li, ul, text, div, img)
import Html.App as Html
import Html.Attributes exposing (class, href, src, style)
import Html.Events exposing (onClick)
import Http
import Json.Decode as Json
import Json.Decode exposing ((:=))
import Json.Decode.Extra exposing ((|:))
import Task


main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


type alias Model =
    { tracks : Dict TrackId Track
    , feed : List TrackId
    , queue : List TrackId
    , nextLink : Maybe String
    , loading : Bool
    , playing : Bool
    , currentTrack : Maybe TrackId
    }


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


type alias FetchFeedPayload =
    { tracks : List Track
    , nextLink : String
    }


init : ( Model, Cmd Msg )
init =
    ( { tracks = Dict.empty
      , feed = []
      , queue = []
      , loading = True
      , playing = False
      , nextLink = Nothing
      , currentTrack = Nothing
      }
    , fetchFeed Nothing
    )



-- UPDATE


type Msg
    = FetchFeedSuccess FetchFeedPayload
    | FetchFeedFail Http.Error
    | FetchMore
    | TogglePlaybackFromFeed Int TrackId
    | TogglePlayback
    | Next
    | PlayTrackSuccess Track
    | TrackProgress ( TrackId, Float, Float )


port playTrack : Track -> Cmd msg
port togglePlayback : Maybe TrackId -> Cmd msg


update : Msg -> Model -> ( Model, Cmd Msg )
update message model =
    case message of
        FetchFeedSuccess payload ->
            let
                updatedTrackDict =
                    payload.tracks
                        |> List.map (\track -> ( track.id, track ))
                        |> Dict.fromList
                        |> Dict.union model.tracks
            in
            ( { model
                | tracks = updatedTrackDict
                , feed = List.append model.feed ( List.map .id payload.tracks )
                , queue = List.append model.queue ( List.map .id payload.tracks )
                , nextLink = Just payload.nextLink
                , loading = False
              }
            , Cmd.none
            )
        FetchFeedFail error ->
            ( { model
                | loading = False
              }
            , Cmd.none
            )
        FetchMore ->
            ( { model
                | loading = True
              }
            , fetchFeed model.nextLink
            )
        TogglePlaybackFromFeed position trackId ->
            if model.currentTrack == Just trackId then
                ( { model | playing = not model.playing }
                , togglePlayback ( Just trackId )
                )
            else
                ( { model
                    | currentTrack = Just trackId
                    , playing = model.currentTrack /= Just trackId || not model.playing
                    , queue = List.drop ( position + 1 ) model.feed
                  }
                , case Dict.get trackId model.tracks of
                    Nothing ->
                        Cmd.none
                    Just track ->
                        playTrack track
                )
        TogglePlayback ->
            ( { model | playing = not model.playing }
            , togglePlayback model.currentTrack
            )
        Next ->
            let
                newCurrentTrack =
                    List.head model.queue
            in
                ( { model
                    | currentTrack = newCurrentTrack
                    , queue = List.drop 1 model.queue
                  }
                , case newCurrentTrack of
                    Nothing ->
                        togglePlayback model.currentTrack
                    Just trackId ->
                        case Dict.get trackId model.tracks of
                            Nothing ->
                                Cmd.none
                            Just track ->
                                playTrack track
                )
        PlayTrackSuccess track ->
            ( model
            , Cmd.none
            )
        TrackProgress ( trackId, progress, currentTime ) ->
            let
                track =
                    Dict.get trackId model.tracks
            in
                case track of
                    Nothing ->
                        ( model
                        , Cmd.none
                        )
                    Just track ->
                        ( { model
                            | tracks =
                                Dict.insert
                                    trackId
                                    { track | progress = progress, currentTime = currentTime }
                                    model.tracks
                          }
                        , Cmd.none
                        )



-- SUBSCRIPTIONS


port trackProgress : ( ( Int, Float, Float ) -> msg ) -> Sub msg


subscriptions : Model -> Sub Msg
subscriptions model =
    trackProgress TrackProgress



-- VIEW


view : Model -> Html Msg
view model =
    let
        currentTrack =
            case model.currentTrack of
                Just trackId ->
                    Dict.get trackId model.tracks
                Nothing ->
                    Nothing
    in
        div
            []
            [ viewGlobalPlayer currentTrack model.playing
            , viewNavigation navigation
            , div
                [ class "playlist-container" ]
                [ viewFeed model ]
            ]


viewGlobalPlayer : Maybe Track -> Bool -> Html Msg
viewGlobalPlayer track playing =
    case track of
        Nothing ->
            div
                [ class "global-player" ]
                [ div
                    [ class "controls" ]
                    [ div
                        [ class "playback-button" ]
                        [ text "Play" ]
                    , div
                        [ class "next-button" ]
                        [ text "Next" ]
                    ]
                , img [ src "images/placeholder.jpg" ] []
                , div
                    [ class "track-info" ]
                    []
                , div
                    [ class "progress-bar" ]
                    [ div [ class "outer" ] []
                    ]
                , div
                    [ class "actions" ]
                    []
                ]
        Just track ->
            div
                [ class "global-player" ]
                [ div
                    [ class "controls" ]
                    [ div
                        [ class ( "playback-button" ++ ( if playing then " playing" else "" ) )
                        , onClick ( TogglePlayback )
                        ]
                        [ text "Play" ]
                    , div
                        [ class "next-button"
                        , onClick Next
                        ]
                        [ text "Next" ]
                    ]
                , img
                    [ src track.artwork_url ]
                    []
                , div
                    [ class "track-info" ]
                    [ div [ class "artist" ] [ text track.artist ]
                    , div [ class "title" ] [ text track.title ]
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
                , div
                    [ class "actions" ]
                    []
                ]


viewFeed : Model -> Html Msg
viewFeed model =
    let
        feedTracks =
            List.filterMap ( \trackId -> Dict.get trackId model.tracks ) model.feed
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
        , onClick ( TogglePlaybackFromFeed position track.id )
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


type alias Navigation =
    { items : List NavigationItem
    , activeItem : NavigationItem
    }


type alias NavigationItem =
    { displayName : String
    , href : String
    }


navigation : Navigation
navigation =
    Navigation
        [ NavigationItem "feed" "/"
        , NavigationItem "saved tracks" "/saved-tracks"
        , NavigationItem "published tracks" "/pubished-tracks"
        ]
        ( NavigationItem "feed" "/" )



viewNavigation : Navigation -> Html Msg
viewNavigation navigation =
    navigation.items
        |> List.map ( viewNavigationItem navigation.activeItem )
        |> ul []
        |> List.repeat 1
        |> nav [ class "navigation" ]


viewNavigationItem : NavigationItem -> NavigationItem -> Html Msg
viewNavigationItem activeNavigationItem navigationItem =
    let
        linkAttributes =
            if navigationItem == activeNavigationItem then
                [ class "active" ]
            else
                []
    in
        li
            []
            [ a
                ( List.append linkAttributes [ href navigationItem.href ] )
                [ text navigationItem.displayName ]
            ]



-- HTTP


fetchFeed : Maybe String -> Cmd Msg
fetchFeed nextLink =
    Http.get decodeFeed ( Maybe.withDefault "/feed" nextLink )
        |> Task.perform FetchFeedFail FetchFeedSuccess


decodeFeed : Json.Decoder FetchFeedPayload
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
