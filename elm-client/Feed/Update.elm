module Feed.Update exposing (..)


import Api
import Char
import Dict
import Feed.Model as Model exposing (Model, PlaylistId(..))
import Feed.Ports as Ports
import Http
import Json.Decode
import Json.Decode exposing ((:=))
import Json.Decode.Extra exposing ((|:))
import Json.Encode
import Keyboard
import Model exposing (Track, TrackId)
import Navigation
import Player
import Soundcloud
import Task exposing (Task)
import Time exposing (Time)


type Msg
    = TogglePlayback
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
    | PlayFromCustomQueue Int Track
    | PlayFromPlaylist PlaylistId Int Track
    | AddToCustomQueue TrackId
    | FetchMore PlaylistId
    | FetchFail PlaylistId Http.Error
    | FetchSuccess PlaylistId ( List Track, String )
    | AddTrackFail Http.Error
    | AddTrackSuccess
    | ResolveTrackInfo String
    | ResolveTrackInfoFailure Http.Error
    | ResolveTrackInfoSuccess Track


update : Msg -> Model -> ( Model, Cmd Msg )
update message model =
    case message of
        FetchSuccess playlistId ( tracks, nextLink ) ->
            let
                updatePlaylist playlist =
                    if playlist.id == playlistId then
                        { playlist
                        | nextLink = nextLink
                        , loading = False
                        }
                    else
                        playlist
                updatedPlaylists =
                    List.map updatePlaylist model.playlists
                updatedTracks =
                    tracks
                        |> List.map (\track -> ( track.id, track ))
                        |> Dict.fromList
                        |> Dict.union model.tracks
            in
                ( { model
                  | playlists = updatedPlaylists
                  , tracks = updatedTracks
                  , player = Player.appendTracksToPlaylist playlistId (List.map .id tracks) model.player
                  }
                , Cmd.none
                )

        FetchFail playlistId error ->
            ( model, Cmd.none )

        AddTrackSuccess ->
            ( model, Cmd.none )

        AddTrackFail error ->
            ( model, Cmd.none )

        PlayFromPlaylist playlistId position track ->
            let
                msg =
                    if Player.currentTrack model.player == Just track.id then
                        TogglePlayback
                    else
                        Play
            in
            update
                msg
                { model | player = Player.select playlistId position model.player }

        AddToCustomQueue trackId ->
            ( { model | player = Player.appendTracksToPlaylist CustomQueue [ trackId ] model.player}
            , Cmd.none
            )

        FetchMore playlistId ->
            let
                updatePlaylist playlist =
                    if playlist.id == playlistId then
                        { playlist | loading = True }
                    else
                        playlist
                updatedPlaylists =
                    List.map updatePlaylist model.playlists
                fetchMoreHelp playlist =
                    if playlist.id == playlistId then
                        fetchMore playlist
                    else
                        Cmd.none
            in
                { model | playlists = updatedPlaylists }
                ! List.map fetchMoreHelp model.playlists

        UpdateCurrentTimeFail ->
            ( model, Cmd.none )

        UpdateCurrentTime newTime ->
            ( { model | currentTime = Just newTime }, Cmd.none )


        Play ->
            case Model.currentTrack model of
                Nothing ->
                    ( model, Cmd.none )
                Just track ->
                    ( { model | playing = True }
                    , Ports.playTrack
                        { id = track.id
                        , streamUrl = track.streamUrl
                        , currentTime = track.currentTime
                        }
                    )

        Pause ->
            ( { model | playing = False }
            , Ports.pause (Player.currentTrack model.player)
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
            update
                Play
                { model | player = Player.next model.player }

        PlayFromCustomQueue position track ->
            ( { model
                | playing = True
                , player = Player.select CustomQueue position model.player
              }
            , Ports.playTrack
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
            , Ports.changeCurrentTime 10
            )

        Rewind ->
            ( model
            , Ports.changeCurrentTime -10
            )

        MoveToPlaylist playlistId trackId ->
            let
                player =
                    Player.moveTrack playlistId trackId model.player
                targetPlaylist =
                    model.playlists
                        |> List.filter ((==) playlistId << .id)
                        |> List.head
                cmd =
                    case targetPlaylist of
                        Nothing ->
                            Cmd.none
                        Just playlist ->
                            addTrack playlist.addTrackUrl trackId
            in
                ( { model | player = player }
                , cmd
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

        ResolveTrackInfo url ->
            ( model
            , resolveTrackInfo model.soundcloudClientId url
            )

        ResolveTrackInfoFailure error ->
            ( model
            , Cmd.none
            )

        ResolveTrackInfoSuccess track ->
            let
                model' =
                    { model | tracks = Dict.insert track.id track model.tracks }
                ( model'', command ) =
                    update (MoveToPlaylist PublishedTracks track.id) model'
                ( model''', command' ) =
                    update (ChangePage "published-tracks") model''
            in
                model''' ! [ command, command' ]

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

                                _ ->
                                    ( model, Cmd.none )
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

                                _ ->
                                    ( model, Cmd.none )
                        Nothing ->
                            (model, Cmd.none)

                'm' ->
                    case model.currentPage.playlist of
                        Just id ->
                            update (FetchMore id) model
                        Nothing ->
                            ( model, Cmd.none )

                'b' ->
                    case Player.currentTrack model.player of
                        Nothing ->
                            ( model
                            , Cmd.none
                            )

                        Just trackId ->
                            update (BlacklistTrack trackId) model

                's' ->
                    case Player.currentTrack model.player of
                        Nothing ->
                            ( model
                            , Cmd.none
                            )

                        Just trackId ->
                            update (MoveToPlaylist SavedTracks trackId) model

                'P' ->
                    case Player.currentTrack model.player of
                        Nothing ->
                            ( model
                            , Cmd.none
                            )

                        Just trackId ->
                            update (MoveToPlaylist PublishedTracks trackId) model

                'j' ->
                    ( model
                    , Ports.scroll 120
                    )

                'k' ->
                    ( model
                    , Ports.scroll -120
                    )

                'g' ->
                    if model.lastKeyPressed == Just 'g' then
                        ( { model | lastKeyPressed = Nothing }
                        , Ports.scroll -9999999
                        )
                    else
                        ( { model | lastKeyPressed = Just 'g' }
                        , Cmd.none
                        )

                'G' ->
                    ( model
                    , Ports.scroll 99999999
                    )

                _ ->
                    ( model
                    , Cmd.none
                    )



-- HTTP


fetchMore : Model.Playlist -> Cmd Msg
fetchMore playlist =
    Api.fetchPlaylist playlist.nextLink
        |> Task.perform (FetchFail playlist.id) (FetchSuccess playlist.id)


addTrack : String -> Int -> Cmd Msg
addTrack addTrackUrl trackId =
    Api.addTrack addTrackUrl trackId
        |> Task.perform AddTrackFail (\_ -> AddTrackSuccess)


resolveTrackInfo : String -> String -> Cmd Msg
resolveTrackInfo soundcloudClientId url =
    Soundcloud.resolve soundcloudClientId url
        |> Task.perform ResolveTrackInfoFailure ResolveTrackInfoSuccess