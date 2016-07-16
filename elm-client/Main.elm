port module Main exposing(..)

import Dict exposing (Dict)
import Html exposing (Html, a, nav, li, ul, text, div, img)
import Html.App as Html
import Html.Attributes exposing (class, href, src, style)
import Html.Events exposing (onClick, onWithOptions)
import Http
import FeedApi
import Playlist exposing (Track, TrackId)
import Task
import Keyboard
import Char
import Json.Decode
import Navigation
import Time exposing (Time)


main : Program Never
main =
    Navigation.program urlParser
        { init = init
        , view = view
        , update = update
        , urlUpdate = urlUpdate
        , subscriptions = subscriptions
        }



-- URL PARSERS


urlParser : Navigation.Parser Page
urlParser =
    Navigation.makeParser
        (\location ->
            case location.pathname of
                "/feed" ->
                    Feed
                "/saved-tracks" ->
                    SavedTracks
                "/published-tracks" ->
                    PublishedTracks
                _ ->
                    Feed
        )


urlUpdate : Page -> Model -> ( Model, Cmd Msg )
urlUpdate page model =
    ( { model | currentPage = page }
    , Cmd.none
    )



-- MODEL


type alias Model =
    { tracks : Dict TrackId Track
    , feed : Playlist.Model
    , savedTracks : Playlist.Model
    , publishedTracks : Playlist.Model
    , queue : List TrackId
    , playing : Bool
    , currentTrack : Maybe TrackId
    , currentPage : Page
    , lastKeyPressed : Maybe Char
    , currentTime : Maybe Time
    }


type PlaylistId
    = Feed
    | SavedTracks
    | PublishedTracks


type alias Page = PlaylistId


init : Page -> ( Model, Cmd Msg )
init page =
    ( { tracks = Dict.empty
      , feed = Playlist.initialModel "/feed"
      , savedTracks = Playlist.initialModel "/saved-tracks"
      , publishedTracks = Playlist.initialModel "/published-tracks"
      , queue = []
      , playing = False
      , currentTrack = Nothing
      , currentPage = page
      , lastKeyPressed = Nothing
      , currentTime = Nothing
      }
    , Cmd.batch
        [ Cmd.map ( PlaylistMsg Feed ) ( Playlist.initialCmd "/feed" )
        , Cmd.map ( PlaylistMsg SavedTracks ) ( Playlist.initialCmd "/saved_tracks" )
        , Cmd.map ( PlaylistMsg PublishedTracks ) ( Playlist.initialCmd "/published_tracks" )
        , Time.now |> Task.perform ( \_ -> UpdateCurrentTimeFail ) UpdateCurrentTime
        ]
    )



-- UPDATE


type Msg
    = PlaylistMsg PlaylistId Playlist.Msg
    | PlaylistEvent PlaylistId Playlist.Event
    | TogglePlayback
    | Next
    | TrackProgress ( TrackId, Float, Float )
    | FastForward
    | Rewind
    | MoveToPlaylist PlaylistId TrackId
    | MoveToPlaylistFail Http.Error
    | MoveToPlaylistSuccess
    | Blacklist TrackId
    | BlacklistFail Http.Error
    | BlacklistSuccess
    | ChangePage String
    | KeyPressed Keyboard.KeyCode
    | UpdateCurrentTime Time
    | UpdateCurrentTimeFail


port playTrack : { id : Int, streamUrl : String, currentTime : Float } -> Cmd msg
port resume : Maybe TrackId -> Cmd msg
port pause : Maybe TrackId -> Cmd msg
port changeCurrentTime : Int -> Cmd msg
port scroll : Int -> Cmd msg


update : Msg -> Model -> ( Model, Cmd Msg )
update message model =
    case message of
        UpdateCurrentTimeFail ->
            ( model
            , Cmd.none
            )
        UpdateCurrentTime newTime ->
            ( { model | currentTime = Just newTime }
            , Cmd.none
            )
        PlaylistMsg playlistId playlistMsg ->
            applyMessageToPlaylists playlistMsg model [ playlistId ]
        PlaylistEvent playlistId event ->
            case event of
                Playlist.NewTracksWereFetched ( tracks, nextLink ) ->
                    let
                        updatedTrackDict =
                            tracks
                                |> List.map (\track -> ( track.id, track ))
                                |> Dict.fromList
                                |> Dict.union model.tracks
                    in
                    ( { model
                        | tracks = updatedTrackDict
                        , queue = List.append model.queue ( List.map .id tracks )
                      }
                    , Cmd.none
                    )
                Playlist.TrackWasClicked position track ->
                    let
                        playlistTracks =
                            case playlistId of
                                Feed ->
                                    model.feed.trackIds
                                SavedTracks ->
                                    model.savedTracks.trackIds
                                PublishedTracks ->
                                    model.publishedTracks.trackIds
                    in
                        if model.currentTrack == Just track.id then
                            update TogglePlayback model
                        else
                            ( { model
                                | currentTrack = Just track.id
                                , playing = True
                                , queue = List.drop ( position + 1 ) playlistTracks
                              }
                              , playTrack
                                  { id = track.id
                                  , streamUrl = track.streamUrl
                                  , currentTime = track.currentTime
                                  }
                            )
        TogglePlayback ->
            ( { model | playing = not model.playing }
            , if model.playing then
                pause model.currentTrack
              else
                resume model.currentTrack
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
                        pause model.currentTrack
                    Just trackId ->
                        case Dict.get trackId model.tracks of
                            Nothing ->
                                Cmd.none
                            Just track ->
                              playTrack
                                  { id = track.id
                                  , streamUrl = track.streamUrl
                                  , currentTime = track.currentTime
                                  }
                )
        FastForward ->
            ( model
            , changeCurrentTime 10
            )
        Rewind ->
            ( model
            , changeCurrentTime -10
            )
        TrackProgress ( trackId, progress, currentTime ) ->
            ( { model
                | tracks =
                    Dict.update
                        trackId
                        ( Maybe.map ( \track -> { track | progress = progress, currentTime = currentTime } ) )
                        model.tracks
              }
            , Cmd.none
            )
        Blacklist trackId ->
            let
                ( newModel, commands ) =
                    if model.currentTrack == Just trackId then
                        update Next model
                    else
                        ( model
                        , Cmd.none
                        )
                ( newModel', commands' ) =
                    applyMessageToPlaylists
                        ( Playlist.RemoveTrack trackId )
                        newModel
                        [ Feed, SavedTracks, PublishedTracks ]
            in
                ( { newModel'
                    | queue = List.filter ((/=) trackId) newModel.queue
                  }
                , Cmd.batch [ commands, commands', blacklist trackId ]
                )
        BlacklistFail error ->
            ( model
            , Cmd.none
            )
        BlacklistSuccess ->
            ( model
            , Cmd.none
            )
        MoveToPlaylist playlistId trackId ->
            let
                ( newModel, command ) =
                    applyMessageToPlaylists
                        ( Playlist.RemoveTrack trackId )
                        model
                        ( List.filter ( (/=) playlistId ) [ Feed, SavedTracks, PublishedTracks ] )
                ( newModel', command' ) =
                    applyMessageToPlaylists
                        ( Playlist.AddTrack trackId )
                        newModel
                        [ playlistId ]
            in
                ( newModel'
                , Cmd.batch [ command, command', moveToPlaylist playlistId trackId ]
                )
        MoveToPlaylistFail error ->
            ( model
            , Cmd.none
            )
        MoveToPlaylistSuccess ->
            ( model
            , Cmd.none
            )
        ChangePage url ->
            ( model
            , Navigation.newUrl url
            )
        KeyPressed keyCode ->
            case ( Char.fromCode keyCode ) of
                'n' ->
                    update Next model
                'p' ->
                    update TogglePlayback model
                'l' ->
                    update FastForward model
                'h' ->
                    update Rewind model
                'L' ->
                    case model.currentPage of
                        Feed ->
                            update ( ChangePage "/saved-tracks" ) model
                        SavedTracks ->
                            update ( ChangePage "/published-tracks" ) model
                        PublishedTracks ->
                            update ( ChangePage "/" ) model
                'H' ->
                    case model.currentPage of
                        Feed ->
                            update ( ChangePage "/published-tracks" ) model
                        SavedTracks ->
                            update ( ChangePage "/" ) model
                        PublishedTracks ->
                            update ( ChangePage "/saved-tracks" ) model
                'm' ->
                    update ( PlaylistMsg model.currentPage Playlist.FetchMore ) model
                'b' ->
                    case model.currentTrack of
                        Nothing ->
                            ( model
                            , Cmd.none
                            )
                        Just trackId ->
                            update ( Blacklist trackId ) model
                's' ->
                    case model.currentTrack of
                        Nothing ->
                            ( model
                            , Cmd.none
                            )
                        Just trackId ->
                            update ( MoveToPlaylist SavedTracks trackId ) model
                'P' ->
                    case model.currentTrack of
                        Nothing ->
                            ( model
                            , Cmd.none
                            )
                        Just trackId ->
                            update ( MoveToPlaylist PublishedTracks trackId ) model
                'j' ->
                    ( model
                    , scroll 120
                    )
                'k' ->
                    ( model
                    , scroll -120
                    )
                'g' ->
                    if model.lastKeyPressed == Just 'g' then
                        ( { model | lastKeyPressed = Nothing }
                        , scroll -9999999
                        )
                    else
                        ( { model | lastKeyPressed = Just 'g' }
                        , Cmd.none
                        )
                'G' ->
                    ( model
                    , scroll 99999999
                    )
                _ ->
                    ( model
                    , Cmd.none
                    )


handlePlaylistMsg : PlaylistId -> Playlist.Msg -> Model -> ( Model, Cmd Msg )
handlePlaylistMsg playlistId playlistMsg model =
    let
        ( updatedPlaylist, command, event ) =
            case playlistId of
                Feed ->
                    Playlist.update playlistMsg model.feed
                SavedTracks ->
                    Playlist.update playlistMsg model.savedTracks
                PublishedTracks ->
                    Playlist.update playlistMsg model.publishedTracks
        updatedModel =
            case playlistId of
                Feed ->
                    { model | feed = updatedPlaylist }
                SavedTracks ->
                    { model | savedTracks = updatedPlaylist }
                PublishedTracks ->
                    { model | publishedTracks = updatedPlaylist }
    in
        case event of
            Nothing ->
                ( updatedModel
                , Cmd.map ( PlaylistMsg playlistId ) command
                )
            Just event ->
                let
                    ( modelAfterEvent, eventCommand )  =
                        update ( PlaylistEvent playlistId event ) updatedModel
                in
                    ( modelAfterEvent
                    , Cmd.batch
                        [ Cmd.map ( PlaylistMsg playlistId ) command
                        , eventCommand
                        ]
                    )


applyMessageToPlaylists : Playlist.Msg -> Model -> List PlaylistId -> ( Model, Cmd Msg )
applyMessageToPlaylists  playlistMsg model playlistIds =
    List.foldr
        ( \playlistId (m, c) ->
            let
                ( m', c' ) =
                    handlePlaylistMsg playlistId  playlistMsg m
            in
                ( m', Cmd.batch [c, c'] )
        )
        ( model, Cmd.none )
        playlistIds



-- SUBSCRIPTIONS


port trackProgress : ( ( TrackId, Float, Float ) -> msg ) -> Sub msg
port trackEnd : ( TrackId -> msg ) -> Sub msg


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ trackProgress TrackProgress
        , trackEnd ( \_ -> Next )
        , Keyboard.presses KeyPressed
        ]


-- VIEW


view : Model -> Html Msg
view model =
    let
        currentTrack =
            model.currentTrack
                `Maybe.andThen`
                ( \trackId -> Dict.get trackId model.tracks )
    in
        div
            []
            [ viewGlobalPlayer currentTrack model.playing
            , viewNavigation navigation model.currentPage
            , div
                [ class "playlist-container" ]
                [ case model.currentPage of
                    Feed ->
                        Html.map
                            ( PlaylistMsg Feed )
                            ( Playlist.view model.currentTime model.tracks model.feed )
                    SavedTracks ->
                        Html.map
                            ( PlaylistMsg SavedTracks )
                            ( Playlist.view model.currentTime model.tracks model.savedTracks )
                    PublishedTracks ->
                        Html.map
                            ( PlaylistMsg PublishedTracks )
                            ( Playlist.view model.currentTime model.tracks model.publishedTracks )
                ]
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


type alias NavigationItem =
    { displayName : String
    , href : String
    , page : Page
    }


navigation : List NavigationItem
navigation =
    [ NavigationItem "feed" "/" Feed
    , NavigationItem "saved tracks" "/saved-tracks" SavedTracks
    , NavigationItem "published tracks" "/published-tracks" PublishedTracks
    ]



viewNavigation : List NavigationItem -> Page -> Html Msg
viewNavigation navigationItems currentPage =
    navigationItems
        |> List.map ( viewNavigationItem currentPage )
        |> ul []
        |> List.repeat 1
        |> nav [ class "navigation" ]


viewNavigationItem : Page -> NavigationItem -> Html Msg
viewNavigationItem currentPage navigationItem =
    let
        linkAttributes =
            if navigationItem.page == currentPage then
                [ class "active" ]
            else
                []
    in
        li
            [ onWithOptions
                "click"
                { stopPropagation = False
                , preventDefault = True
                }
                ( Json.Decode.succeed ( ChangePage navigationItem.href ) )
            ]
            [ a
                ( List.append linkAttributes [ href navigationItem.href ] )
                [ text navigationItem.displayName ]
            ]



-- HTTP


blacklist : TrackId -> Cmd Msg
blacklist trackId =
    FeedApi.blacklist trackId
        |> Task.perform BlacklistFail ( \_ -> BlacklistSuccess )


moveToPlaylist : PlaylistId -> TrackId -> Cmd Msg
moveToPlaylist playlistId trackId =
    case playlistId of
        Feed ->
            Cmd.none
        SavedTracks ->
            FeedApi.save trackId
                |> Task.perform MoveToPlaylistFail ( \_ -> MoveToPlaylistSuccess )
        PublishedTracks ->
            FeedApi.publish trackId
                |> Task.perform MoveToPlaylistFail ( \_ -> MoveToPlaylistSuccess )
