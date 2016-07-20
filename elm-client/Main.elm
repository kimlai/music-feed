port module Main exposing (..)

import Dict exposing (Dict)
import Html exposing (Html, a, nav, li, ul, text, div, img)
import Html.App as Html
import Html.Attributes exposing (class, classList, href, src, style)
import Html.Events exposing (onClick, onWithOptions)
import Http
import Playlist exposing (Track, TrackId)
import PlaylistStructure
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
        (\{ pathname } ->
            pages
                |> List.filter ((==) pathname << .url)
                |> List.head
                |> Maybe.withDefault (Page "/" (Just Feed))
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


type alias Page =
    { url : String
    , playlist : Maybe PlaylistId
    }


pages : List Page
pages =
    [ Page "/feed" (Just Feed)
    , Page "/saved-tracks" (Just SavedTracks)
    , Page "/published-tracks" (Just PublishedTracks)
    , Page "/publish-track" Nothing
    ]


init : Page -> ( Model, Cmd Msg )
init page =
    let
        playlists =
            [ Playlist Feed (Playlist.initialModel "/feed" "fake-url")
            , Playlist SavedTracks (Playlist.initialModel "/saved-tracks" "save_track")
            , Playlist PublishedTracks (Playlist.initialModel "/published-tracks" "publish_track")
            , Playlist Blacklist (Playlist.initialModel "/blacklist" "blacklist")
            ]
    in
        ( { tracks = Dict.empty
          , playlists = playlists
          , queue = []
          , customQueue = []
          , playing = False
          , currentPlaylist = Nothing
          , currentPage = page
          , lastKeyPressed = Nothing
          , currentTime = Nothing
          }
        , Cmd.batch
            [ Cmd.map (PlaylistMsg Feed) (Playlist.initialCmd "/feed")
            , Cmd.map (PlaylistMsg SavedTracks) (Playlist.initialCmd "/saved_tracks")
            , Cmd.map (PlaylistMsg PublishedTracks) (Playlist.initialCmd "/published_tracks")
            , Time.now |> Task.perform (\_ -> UpdateCurrentTimeFail) UpdateCurrentTime
            ]
        )



-- UPDATE


type Msg
    = PlaylistMsg PlaylistId Playlist.Msg
    | PlaylistEvent PlaylistId Playlist.Event
    | TogglePlayback
    | Next
    | TrackProgress ( TrackId, Float, Float )
    | Play
    | Pause
    | TrackError TrackId
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
            ( model, Cmd.none )

        UpdateCurrentTime newTime ->
            ( { model | currentTime = Just newTime }, Cmd.none )

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
                        ( { model | tracks = updatedTrackDict }
                        , Cmd.none
                        )

                Playlist.TrackWasClicked previousTrackId ->
                    let
                        model' =
                            { model | currentPlaylist = Just playlistId }
                    in
                        if (currentTrackId model') == previousTrackId then
                            update TogglePlayback model'
                        else
                            update Play model'


                Playlist.TrackWasAddedToCustomQueue trackId ->
                    ( { model | customQueue = List.append model.customQueue [ trackId ] }
                    , Cmd.none
                    )

        Play ->
            case currentTrack model of
                Nothing ->
                    ( model, Cmd.none )
                Just track ->
                    ( { model | playing = True }
                    , playTrack
                        { id = track.id
                        , streamUrl = track.streamUrl
                        , currentTime = track.currentTime
                        }
                    )

        Pause ->
            ( { model | playing = False }
            , pause (currentTrackId model)
            )

        TrackError trackId ->
            let
                newModel =
                    { model
                        | tracks =
                            Dict.update
                                trackId
                                (Maybe.map (\track -> { track | error = True }))
                                model.tracks
                    }

                ( newModel', command ) =
                    update Next newModel
            in
                ( newModel', command )

        TogglePlayback ->
            if model.playing then
                update Pause model
            else
                update Play model

        Next ->
            let
                ( model', command ) =
                    case model.currentPlaylist of
                        Nothing ->
                            ( model, Cmd.none )

                        Just playlistId ->
                            applyMessageToPlaylists Playlist.Next model [ playlistId ]
                ( model'', command') =
                    case currentTrack model' of
                        Nothing ->
                            update Pause model'

                        Just track ->
                            update Play model'
            in
                model'' ! [ command, command' ]

        PlayFromCustomQueue track ->
            ( { model
                | playing = True
                , customQueue = List.filter ((/=) track.id) model.customQueue
              }
            , playTrack
                { id = track.id
                , streamUrl = track.streamUrl
                , currentTime = track.currentTime
                }
            )

        TrackProgress ( trackId, progress, currentTime ) ->
            ( { model
                | tracks =
                    Dict.update
                        trackId
                        (Maybe.map (\track -> { track | progress = progress, currentTime = currentTime }))
                        model.tracks
              }
            , Cmd.none
            )

        ChangePage url ->
            ( model, Navigation.newUrl url )

        FastForward ->
            ( model
            , changeCurrentTime 10
            )

        Rewind ->
            ( model
            , changeCurrentTime -10
            )

        MoveToPlaylist playlistId trackId ->
            let
                ( newModel, command ) =
                    applyMessageToPlaylists
                        (Playlist.RemoveTrack trackId)
                        model
                        (List.filter ((/=) playlistId) (List.map .id model.playlists))

                ( newModel', command' ) =
                    applyMessageToPlaylists
                        (Playlist.AddTrack trackId)
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
                    update (MoveToPlaylist Blacklist trackId) newModel
            in
                ( newModel', Cmd.batch [ command, command' ] )

        KeyPressed keyCode ->
            case (Char.fromCode keyCode) of
                'n' ->
                    update Next model

                'p' ->
                    update TogglePlayback model

                'l' ->
                    update FastForward model

                'h' ->
                    update Rewind model

                'L' ->
                    case model.currentPage.playlist of
                        Just playlistId ->
                            case playlistId of
                                Feed ->
                                    update (ChangePage "/saved-tracks") model

                                SavedTracks ->
                                    update (ChangePage "/published-tracks") model

                                PublishedTracks ->
                                    update (ChangePage "/") model

                                Blacklist ->
                                    update (ChangePage "/") model
                        Nothing ->
                            (model, Cmd.none)

                'H' ->
                    case model.currentPage.playlist of
                        Just playlistId ->
                            case playlistId of
                                Feed ->
                                    update (ChangePage "/published-tracks") model

                                SavedTracks ->
                                    update (ChangePage "/") model

                                PublishedTracks ->
                                    update (ChangePage "/saved-tracks") model

                                Blacklist ->
                                    update (ChangePage "/") model
                        Nothing ->
                            (model, Cmd.none)

                'm' ->
                    case model.currentPage.playlist of
                        Just id ->
                            update (PlaylistMsg id Playlist.FetchMore) model
                        Nothing ->
                            ( model, Cmd.none )

                'b' ->
                    case currentTrackId model of
                        Nothing ->
                            ( model
                            , Cmd.none
                            )

                        Just trackId ->
                            update (BlacklistTrack trackId) model

                's' ->
                    case currentTrackId model of
                        Nothing ->
                            ( model
                            , Cmd.none
                            )

                        Just trackId ->
                            update (MoveToPlaylist SavedTracks trackId) model

                'P' ->
                    case currentTrackId model of
                        Nothing ->
                            ( model
                            , Cmd.none
                            )

                        Just trackId ->
                            update (MoveToPlaylist PublishedTracks trackId) model

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
                        |> List.filter ((/=) playlist.id << .id)
                        |> List.append [ Playlist playlist.id updatedPlaylist ]
            }
    in
        case event of
            Nothing ->
                ( updatedModel
                , Cmd.map (PlaylistMsg playlist.id) command
                )

            Just event ->
                let
                    ( modelAfterEvent, eventCommand ) =
                        update (PlaylistEvent playlist.id event) updatedModel
                in
                    ( modelAfterEvent
                    , Cmd.batch
                        [ Cmd.map (PlaylistMsg playlist.id) command
                        , eventCommand
                        ]
                    )


applyMessageToPlaylists : Playlist.Msg -> Model -> List PlaylistId -> ( Model, Cmd Msg )
applyMessageToPlaylists playlistMsg model playlistIds =
    let
        playlists =
            List.filter
                (\playlist -> List.member playlist.id playlistIds)
                model.playlists
    in
        List.foldr
            (\playlist ( m, c ) ->
                let
                    ( m', c' ) =
                        handlePlaylistMsg playlist playlistMsg m
                in
                    ( m', Cmd.batch [ c, c' ] )
            )
            ( model, Cmd.none )
            playlists



-- SUBSCRIPTIONS


port trackProgress : (( TrackId, Float, Float ) -> msg) -> Sub msg


port trackEnd : (TrackId -> msg) -> Sub msg


port trackError : (TrackId -> msg) -> Sub msg


currentTrack : Model -> Maybe Track
currentTrack model =
    currentTrackId model
        `Maybe.andThen` (flip Dict.get) model.tracks


currentTrackId : Model -> Maybe TrackId
currentTrackId model =
    let
        findPlaylist id =
            List.filter ((==) id << .id) model.playlists
                |> List.head
    in
        model.currentPlaylist
            `Maybe.andThen` findPlaylist
            `Maybe.andThen` (.model >> .items >> Just)
            `Maybe.andThen` PlaylistStructure.currentItem



subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ trackProgress TrackProgress
        , trackEnd (\_ -> Next)
        , trackError TrackError
        , Keyboard.presses KeyPressed
        ]



-- VIEW


view : Model -> Html Msg
view model =
    div
        []
        [ viewGlobalPlayer (currentTrack model) model.playing
        , viewNavigation navigation model.currentPage model.currentPlaylist
        , viewCustomQueue model.tracks model.customQueue
        , div
            [ class "playlist-container" ]
            [ case model.currentPage.playlist of
                Just id ->
                    let
                        currentPagePlaylist =
                            List.filter ((==) id << .id) model.playlists
                                |> List.head
                    in
                        case currentPagePlaylist of
                            Just playlist ->
                                Html.map
                                    (PlaylistMsg playlist.id)
                                    (Playlist.view model.currentTime model.tracks playlist.model)
                            Nothing ->
                                div [] [ text "Well, this is awkward..." ]
                Nothing ->
                    case model.currentPage.url of
                        "/publish-track" ->
                            div [] [ text "Publish Track" ]
                        _ ->
                            div [] [ text "404" ]

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
                        [ classList
                            [ ( "playback-button", True )
                            , ( "playing", playing && not track.error )
                            , ( "error", track.error )
                            ]
                        , onClick (TogglePlayback)
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
                            , style [ ( "width", (toString track.progress) ++ "%" ) ]
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
        |> List.filterMap (\trackId -> Dict.get trackId tracks)
        |> List.map (viewCustomPlaylistItem)
        |> div [ class "custom-queue" ]


viewCustomPlaylistItem : Track -> Html Msg
viewCustomPlaylistItem track =
    div
        [ class "custom-queue-track"
        , onClick (PlayFromCustomQueue track)
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
    }


navigation : List NavigationItem
navigation =
    [ NavigationItem "Feed" "/"
    , NavigationItem "saved tracks" "/saved-tracks"
    , NavigationItem "published tracks" "/published-tracks"
    , NavigationItem "+" "/publish-track"
    ]


viewNavigation : List NavigationItem -> Page -> Maybe PlaylistId -> Html Msg
viewNavigation navigationItems currentPage currentPlaylist =
    let
        currentPlaylistPage =
            pages
                |> List.filter ((==) currentPlaylist << .playlist)
                |> List.head
    in
        navigationItems
            |> List.map (viewNavigationItem currentPage currentPlaylistPage)
            |> ul []
            |> List.repeat 1
            |> nav [ class "navigation" ]


viewNavigationItem : Page -> Maybe Page -> NavigationItem -> Html Msg
viewNavigationItem currentPage currentPlaylistPage navigationItem =
    li
        [ onWithOptions
            "click"
            { stopPropagation = False
            , preventDefault = True
            }
            (Json.Decode.succeed (ChangePage navigationItem.href))
        ]
        [ a
            ( classList
                [ ( "active", navigationItem.href == currentPage.url )
                , ( "paying", Just navigationItem.href == Maybe.map .url currentPlaylistPage )
                ]
            :: [ href navigationItem.href ]
            )
            [ text navigationItem.displayName ]
        ]
