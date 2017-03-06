module Radio.Update exposing (..)


import Api
import Char
import Dict
import Http
import Keyboard
import Model exposing (Track, TrackId, StreamingInfo(..))
import Player
import PlayerEngine
import Radio.Model as Model exposing (Model, PlaylistId(..), Page(..))
import Radio.Ports as Ports
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
    | ChangePage String
    | KeyPressed Keyboard.KeyCode
    | UpdateCurrentTime Time
    | PlayFromPlaylist PlaylistId Int
    | FetchMore PlaylistId
    | FetchedMore PlaylistId (Result Http.Error ( List Track, String ))
    | ReportedDeadTrack (Result Http.Error String)
    | ResumeRadio
    | SeekTo Float


update : Msg -> Model -> ( Model, Cmd Msg )
update message model =
    case message of
        FetchedMore playlistId (Ok ( tracks, nextLink )) ->
            let
                updatePlaylist playlist =
                    { playlist | nextLink = nextLink
                    , loading = False
                    }
                updatedTracks =
                    tracks
                        |> List.map (\track -> ( track.id, track ))
                        |> Dict.fromList
                        |> Dict.union model.tracks
                updatedModel =
                    { model
                    | tracks = updatedTracks
                    , player = Player.appendTracksToPlaylist playlistId (List.map .id tracks) model.player
                    }
            in
                case playlistId of
                    Radio ->
                        ( { updatedModel | radio = updatePlaylist model.radio }
                        , Cmd.none
                        )
                    LatestTracks ->
                        ( { updatedModel | latestTracks = updatePlaylist model.latestTracks }
                        , Cmd.none
                        )

        FetchedMore playlistId (Err error)->
            ( model, Cmd.none )

        PlayFromPlaylist playlistId position ->
            let
                player =
                    Player.select playlistId position model.player
                msg =
                    if Player.currentTrack player == Player.currentTrack model.player then
                        TogglePlayback
                    else
                        Play
            in
            update
                msg
                { model | player = player}

        FetchMore playlistId ->
            let
                markAsLoading playlist =
                    { playlist | loading = True }
            in
                case playlistId of
                    Radio ->
                        ( { model | radio = markAsLoading model.radio }
                        , fetchMore model.radio
                        )
                    LatestTracks ->
                        ( { model | latestTracks = markAsLoading model.latestTracks }
                        , fetchMore model.latestTracks
                        )

        UpdateCurrentTime newTime ->
            ( { model | currentTime = Just newTime }, Cmd.none )

        Play ->
            case Model.currentTrack model of
                Nothing ->
                    ( model, Cmd.none )
                Just track ->
                    ( { model | playing = True }
                    , PlayerEngine.play track
                    )

        Pause ->
            ( { model | playing = False }
            , PlayerEngine.pause (Player.currentTrack model.player)
            )

        ResumeRadio ->
            update Play { model | player = Player.selectPlaylist Radio model.player }

        TrackError trackId ->
            let
                newModel =
                    { model | tracks =
                        Dict.update
                            trackId
                            (Maybe.map (\track -> { track | error = True }))
                            model.tracks
                    }

                ( newModelWithNext, command ) =
                    update Next newModel
            in
                newModelWithNext ! [ command, reportDeadTrack trackId ]

        ReportedDeadTrack _ ->
            ( model, Cmd.none)

        TogglePlayback ->
            if model.playing then
                update Pause model
            else
                update Play model

        Next ->
            update
                Play
                { model | player = Player.next model.player }

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
            let
                newPage =
                    case url of
                        "/" -> RadioPage
                        "/latest" -> LatestTracksPage
                        _ -> PageNotFound
            in
                ( { model | currentPage = newPage }
                , Cmd.none
                )

        SeekTo positionInPercentage ->
            ( model
            , PlayerEngine.seekToPercentage (Model.currentTrack model) positionInPercentage
            )

        FastForward ->
            ( model
            , PlayerEngine.changeCurrentTime (Model.currentTrack model) 10
            )

        Rewind ->
            ( model
            , PlayerEngine.changeCurrentTime (Model.currentTrack model) -10
            )

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
    Http.send (FetchedMore playlist.id) (Api.fetchPlaylist playlist.nextLink Api.decodeTrack)


reportDeadTrack : TrackId -> Cmd Msg
reportDeadTrack trackId =
    Http.send ReportedDeadTrack (Api.reportDeadTrack trackId)
