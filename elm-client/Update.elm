module Update exposing (..)


import Char
import Dict
import Http
import Json.Decode
import Json.Decode exposing ((:=))
import Json.Decode.Extra exposing ((|:))
import Json.Encode
import Keyboard
import Model exposing (Model, PlaylistId(..), TrackId, Track)
import Navigation
import Ports
import Task exposing (Task)
import Time exposing (Time)
import PlaylistStructure


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
    | PlayFromCustomQueue Track
    | PlayFromPlaylist PlaylistId Int Track
    | OnAddTrackToCustomQueueClicked TrackId
    | FetchMore PlaylistId
    | FetchFail PlaylistId Http.Error
    | FetchSuccess PlaylistId ( List Track, String )
    | AddTrackFail Http.Error
    | AddTrackSuccess


update : Msg -> Model -> ( Model, Cmd Msg )
update message model =
    case message of
        FetchSuccess playlistId ( tracks, nextLink ) ->
            let
                updatePlaylist playlist =
                    if playlist.id == playlistId then
                        { playlist | items = PlaylistStructure.append (List.map .id tracks) playlist.items
                        , nextLink = nextLink
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
                updatePlaylist playlist =
                    if playlist.id == playlistId then
                        { playlist | items = PlaylistStructure.select position playlist.items }
                    else
                        playlist
                updatedPlaylists =
                    List.map updatePlaylist model.playlists
                updatedModel =
                    { model
                    | playlists = updatedPlaylists
                    , currentPlaylistId = Just playlistId
                    , currentTrackId = Just track.id
                    }
            in
                update Play updatedModel

        OnAddTrackToCustomQueueClicked trackId ->
            ( model, Cmd.none )

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
            , Ports.pause (model.currentTrackId)
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
                updatePlaylist playlist =
                    if model.currentPlaylistId == Just playlist.id then
                        { playlist | items = PlaylistStructure.next playlist.items }
                    else playlist
                updatedPlaylists =
                    List.map updatePlaylist model.playlists
                model' =
                    { model | playlists = updatedPlaylists }
                currentTrack =
                    case Model.currentPlaylist model' of
                        Just playlist ->
                            PlaylistStructure.currentItem playlist.items
                        Nothing ->
                            Nothing
            in
                update Play { model' | currentTrackId = currentTrack }

        PlayFromCustomQueue track ->
            ( { model
                | playing = True
                , customQueue = List.filter ((/=) track.id) model.customQueue
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
                updatePlaylist playlist =
                    if playlist.id == playlistId then
                        { playlist | items = PlaylistStructure.prepend trackId playlist.items }
                    else
                        { playlist | items = PlaylistStructure.remove trackId playlist.items }
                updatedPlaylists =
                    List.map updatePlaylist model.playlists
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
                ( { model | playlists = updatedPlaylists }
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
                            update (FetchMore id) model
                        Nothing ->
                            ( model, Cmd.none )

                'b' ->
                    case model.currentTrackId of
                        Nothing ->
                            ( model
                            , Cmd.none
                            )

                        Just trackId ->
                            update (BlacklistTrack trackId) model

                's' ->
                    case model.currentTrackId of
                        Nothing ->
                            ( model
                            , Cmd.none
                            )

                        Just trackId ->
                            update (MoveToPlaylist SavedTracks trackId) model

                'P' ->
                    case model.currentTrackId  of
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
    Http.get decodePlaylist playlist.nextLink
        |> Task.perform (FetchFail playlist.id) (FetchSuccess playlist.id)


decodePlaylist : Json.Decode.Decoder ( List Track, String )
decodePlaylist =
    Json.Decode.object2 (,)
        ("tracks" := Json.Decode.list decodeTrack)
        ("next_href" := Json.Decode.string)


decodeTrack : Json.Decode.Decoder Track
decodeTrack =
    Json.Decode.succeed Track
        |: ("id" := Json.Decode.int)
        |: (Json.Decode.at [ "user", "username" ] Json.Decode.string)
        |: ("artwork_url" := Json.Decode.Extra.withDefault "/images/placeholder.jpg" Json.Decode.string)
        |: ("title" := Json.Decode.string)
        |: ("stream_url" := Json.Decode.string)
        |: ("permalink_url" := Json.Decode.string)
        |: ("created_at" := Json.Decode.Extra.date)
        |: Json.Decode.succeed 0
        |: Json.Decode.succeed 0
        |: Json.Decode.succeed False


addTrack : String -> Int -> Cmd Msg
addTrack addTrackUrl trackId =
    Http.send
        Http.defaultSettings
        { verb = "POST"
        , headers = [ ( "Content-Type", "application/json" ) ]
        , url = addTrackUrl
        , body = (addTrackBody trackId)
        }
        |> Http.fromJson (Json.Decode.succeed "ok")
        |> Task.perform AddTrackFail (\_ -> AddTrackSuccess)


addTrackBody : Int -> Http.Body
addTrackBody trackId =
    Json.Encode.object
        [ ( "soundcloudTrackId", Json.Encode.int trackId ) ]
        |> Json.Encode.encode 0
        |> Http.string
