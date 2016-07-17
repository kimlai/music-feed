port module Main exposing(..)

import Dict exposing (Dict)
import Html exposing (Html, a, nav, li, ul, text, div, img)
import Html.App as Html
import Html.Attributes exposing (class, classList, href, src, style)
import Html.Events exposing (onClick, onWithOptions)
import Http
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
    , playlists : List Playlist
    , queue : List TrackId
    , customQueue : List TrackId
    , playing : Bool
    , currentTrack : Maybe TrackId
    , currentPlaylist : Maybe PlaylistId
    , currentPage : Page
    , lastKeyPressed : Maybe Char
    , currentTime : Maybe Time
    }


type alias Playlist =
    { id : PlaylistId
    , model : Playlist.Model
    }


type PlaylistId
    = Feed
    | SavedTracks
    | PublishedTracks
    | Blacklist


type alias Page = PlaylistId


init : Page -> ( Model, Cmd Msg )
init page =
    let
        playlists =
            [ Playlist Feed ( Playlist.initialModel "/feed" "fake-url" )
            , Playlist SavedTracks ( Playlist.initialModel "/saved-tracks" "save_track" )
            , Playlist PublishedTracks ( Playlist.initialModel "/published-tracks" "publish_track" )
            , Playlist Blacklist ( Playlist.initialModel "/blacklist" "blacklist" )
            ]
    in
    ( { tracks = Dict.empty
      , playlists = playlists
      , queue = []
      , customQueue = []
      , playing = False
      , currentTrack = Nothing
      , currentPlaylist = Nothing
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
    | BlacklistTrack TrackId
    | ChangePage String
    | KeyPressed Keyboard.KeyCode
    | UpdateCurrentTime Time
    | UpdateCurrentTimeFail
    | PlayFromCustomQueue Track


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
                        updatedQueue =
                            if ( model.currentPage == playlistId ) then
                                model.queue
                            else
                                List.append model.queue ( List.map .id tracks )
                    in
                    ( { model
                        | tracks = updatedTrackDict
                        , queue = updatedQueue
                      }
                    , Cmd.none
                    )
                Playlist.TrackWasClicked position track ->
                    let
                        playlistTracks =
                            model.playlists
                                |> List.filter ( (==) playlistId << .id )
                                |> List.head
                                |> Maybe.map ( .trackIds << .model )
                                |> Maybe.withDefault []
                        newModel =
                            { model | currentPlaylist = Just playlistId }
                    in
                        if model.currentTrack == Just track.id then
                            update TogglePlayback newModel
                        else
                            ( { newModel
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
                Playlist.TrackWasAddedToCustomQueue trackId ->
                    ( { model | customQueue = List.append model.customQueue [trackId] }
                    , Cmd.none
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
                nextTrackInCustomQueue =
                    List.head model.customQueue
                nextTrackInQueue =
                    List.head model.queue
                model' =
                    case nextTrackInCustomQueue of
                        Just trackId ->
                            { model
                            | currentTrack = Just trackId
                            , customQueue = List.drop 1 model.customQueue
                            }
                        Nothing ->
                            { model
                            | currentTrack = nextTrackInQueue
                            , queue = List.drop 1 model.queue
                            }
            in
                ( model'
                , case model'.currentTrack of
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
        PlayFromCustomQueue track ->
            ( { model
                | playing = True
                , currentTrack = Just track.id
                , customQueue = List.filter ((/=) track.id) model.customQueue
              }
            , playTrack
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
        MoveToPlaylist playlistId trackId ->
            let
                ( newModel, command ) =
                    applyMessageToPlaylists
                        ( Playlist.RemoveTrack trackId )
                        model
                        ( List.filter ( (/=) playlistId ) ( List.map .id model.playlists ) )
                ( newModel', command' ) =
                    applyMessageToPlaylists
                        ( Playlist.AddTrack trackId )
                        newModel
                        [ playlistId ]
            in
                ( newModel'
                , Cmd.batch [ command, command' ]
                )
        MoveToPlaylistFail error ->
            ( model
            , Cmd.none
            )
        MoveToPlaylistSuccess ->
            ( model
            , Cmd.none
            )
        BlacklistTrack trackId ->
            let
                ( newModel, command ) =
                    update Next model
                ( newModel', command' ) =
                    update ( MoveToPlaylist Blacklist trackId ) newModel

            in
                ( newModel', Cmd.batch [ command, command' ] )
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
                        Blacklist ->
                            update ( ChangePage "/" ) model
                'H' ->
                    case model.currentPage of
                        Feed ->
                            update ( ChangePage "/published-tracks" ) model
                        SavedTracks ->
                            update ( ChangePage "/" ) model
                        PublishedTracks ->
                            update ( ChangePage "/saved-tracks" ) model
                        Blacklist ->
                            update ( ChangePage "/" ) model
                'm' ->
                    update ( PlaylistMsg model.currentPage Playlist.FetchMore ) model
                'b' ->
                    case model.currentTrack of
                        Nothing ->
                            ( model
                            , Cmd.none
                            )
                        Just trackId ->
                            update ( BlacklistTrack trackId ) model
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


handlePlaylistMsg : Playlist -> Playlist.Msg -> Model -> ( Model, Cmd Msg )
handlePlaylistMsg playlist playlistMsg model =
    let
        ( updatedPlaylist, command, event ) =
            Playlist.update playlistMsg playlist.model
        updatedModel =
            { model
                | playlists =
                    model.playlists
                        |> List.filter ( (/=) playlist.id << .id )
                        |> List.append [ Playlist playlist.id updatedPlaylist ]
            }
    in
        case event of
            Nothing ->
                ( updatedModel
                , Cmd.map ( PlaylistMsg playlist.id ) command
                )
            Just event ->
                let
                    ( modelAfterEvent, eventCommand )  =
                        update ( PlaylistEvent playlist.id event ) updatedModel
                in
                    ( modelAfterEvent
                    , Cmd.batch
                        [ Cmd.map ( PlaylistMsg playlist.id ) command
                        , eventCommand
                        ]
                    )


applyMessageToPlaylists : Playlist.Msg -> Model -> List PlaylistId -> ( Model, Cmd Msg )
applyMessageToPlaylists playlistMsg model playlistIds =
    let
        playlists =
            List.filter
                ( \playlist -> List.member playlist.id playlistIds )
            model.playlists
    in
    List.foldr
        ( \playlist (m, c) ->
            let
                ( m', c' ) =
                    handlePlaylistMsg playlist playlistMsg m
            in
                ( m', Cmd.batch [c, c'] )
        )
        ( model, Cmd.none )
        playlists



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
        currentPagePlaylist =
            List.filter ( (==) model.currentPage << .id ) model.playlists
                |> List.head
    in
        div
            []
            [ viewGlobalPlayer currentTrack model.playing
            , viewNavigation navigation model.currentPage model.currentPlaylist
            , viewCustomQueue model.tracks model.customQueue
            , div
                [ class "playlist-container" ]
                [ case currentPagePlaylist of
                    Nothing ->
                        div [] [ text "Well, this is awkward..." ]
                    Just playlist ->
                        Html.map
                            ( PlaylistMsg playlist.id )
                            ( Playlist.view model.currentTime model.tracks playlist.model )
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


viewCustomQueue : Dict TrackId Track -> List TrackId -> Html Msg
viewCustomQueue tracks queue =
    queue
        |> List.filterMap (\trackId ->  Dict.get trackId tracks )
        |> List.map ( viewCustomPlaylistItem )
        |> div [ class "custom-queue" ]


viewCustomPlaylistItem : Track -> Html Msg
viewCustomPlaylistItem track =
    div [ class "custom-queue-track"
        , onClick ( PlayFromCustomQueue track )
        ]
        [ img [ src track.artwork_url ] []
        , div
            [ class "track-info" ]
            [ div [] [ text track.artist ]
            , div [] [ text track.title ]
            ]
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



viewNavigation : List NavigationItem -> Page -> Maybe PlaylistId -> Html Msg
viewNavigation navigationItems currentPage currentPlaylist =
    navigationItems
        |> List.map ( viewNavigationItem currentPage currentPlaylist )
        |> ul []
        |> List.repeat 1
        |> nav [ class "navigation" ]


viewNavigationItem : Page -> Maybe PlaylistId -> NavigationItem -> Html Msg
viewNavigationItem currentPage currentPlaylist navigationItem =
    let
        classes =
            classList
                [ ( "active", navigationItem.page == currentPage )
                , ( "playing", Just navigationItem.page == currentPlaylist )
                ]
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
                ( classes :: [ href navigationItem.href ] )
                [ text navigationItem.displayName ]
            ]
