module Radio.Update exposing (..)


import Api
import Char
import Dict
import Http
import Json.Decode
import Json.Decode exposing ((:=))
import Json.Decode.Extra exposing ((|:))
import Json.Encode
import Keyboard
import Model exposing (Track, TrackId, StreamingInfo(..))
import Navigation
import Player
import PlayerEngine
import Radio.Model as Model exposing (Model, PlaylistId(..), Token, User)
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
    | UpdateCurrentTimeFail
    | PlayFromCustomQueue Int Track
    | PlayFromPlaylist PlaylistId Int
    | AddToCustomQueue TrackId
    | FetchMore PlaylistId
    | FetchFail PlaylistId Http.Error
    | FetchSuccess PlaylistId ( List Track, String )
    | ReportDeadTrackFail Http.Error
    | ReportDeadTrackSuccess
    | ResumeRadio
    | SeekTo Float
    | SignupUpdateUsername String
    | SignupUpdateEmail String
    | SignupUpdatePassword String
    | SignupSubmit
    | SignupFail Http.Error
    | SignupSuccess String
    | LoginUpdateUsernameOrEmail String
    | LoginUpdatePassword String
    | LoginSubmit
    | LoginFail Http.Error
    | LoginSuccess Token
    | WhoAmIFail Http.Error
    | WhoAmISuccess User


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
                    , PlayerEngine.play track
                    )

        Pause ->
            ( { model | playing = False }
            , PlayerEngine.pause (Player.currentTrack model.player)
            )

        ResumeRadio ->
            let
                model' =
                    { model | player = Player.selectPlaylist Radio model.player }
            in
                update Play model'

        TrackError trackId ->
            let
                newModel =
                    { model | tracks =
                        Dict.update
                            trackId
                            (Maybe.map (\track -> { track | error = True }))
                            model.tracks
                    }


                ( newModel', command ) =
                    update Next newModel
            in
                newModel' ! [ command, reportDeadTrack trackId ]

        ReportDeadTrackFail error ->
            ( model, Cmd.none)

        ReportDeadTrackSuccess ->
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

        PlayFromCustomQueue position track ->
            ( { model
                | playing = True
                , player = Player.select CustomQueue position model.player
              }
            , PlayerEngine.play track
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

        SignupUpdateUsername username ->
            let
                signup =
                    model.signup
                updatedSignup =
                    { signup | username = username }
            in
                ( { model | signup = updatedSignup }
                , Cmd.none
                )

        SignupUpdateEmail email ->
            let
                signup =
                    model.signup
                updatedSignup =
                    { signup | email = email }
            in
                ( { model | signup = updatedSignup }
                , Cmd.none
                )

        SignupUpdatePassword password ->
            let
                signup =
                    model.signup
                updatedSignup =
                    { signup | password = password }
            in
                ( { model | signup = updatedSignup }
                , Cmd.none
                )

        SignupSubmit ->
            ( model
            , signup model.signup
            )

        SignupFail error ->
            let _ = Debug.log "error" error in
            ( model, Cmd.none )

        SignupSuccess response ->
            ( model
            , login model.signup.username model.signup.password
            )

        LoginUpdateUsernameOrEmail usernameOrEmail ->
            let
                login =
                    model.login
                updatedLogin =
                    { login | usernameOrEmail = usernameOrEmail }
            in
                ( { model | login = updatedLogin }
                , Cmd.none
                )

        LoginUpdatePassword password ->
            let
                login =
                    model.login
                updatedLogin =
                    { login | password = password }
            in
                ( { model | login = updatedLogin }
                , Cmd.none
                )

        LoginSubmit ->
            ( model
            , login model.login.usernameOrEmail model.login.password
            )

        LoginFail error ->
            ( model, Cmd.none )

        LoginSuccess token ->
            { model | token = Just token }
            !
            [ Ports.storeToken token
            , whoAmI token
            ]

        WhoAmIFail error ->
            ( model, Cmd.none )

        WhoAmISuccess user ->
            ( { model | currentUser = Just user }
            , Cmd.none
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

                'm' ->
                    case model.currentPage.playlist of
                        Just id ->
                            update (FetchMore id) model
                        Nothing ->
                            ( model, Cmd.none )

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
    Api.fetchPlaylist playlist.nextLink Api.decodeTrack
        |> Task.perform (FetchFail playlist.id) (FetchSuccess playlist.id)


reportDeadTrack : TrackId -> Cmd Msg
reportDeadTrack trackId =
    Api.reportDeadTrack trackId
        |> Task.perform ReportDeadTrackFail (\_ -> ReportDeadTrackSuccess)


signup : Model.SignupModel -> Cmd Msg
signup signupModel =
    Api.signup signupModel
        |> Task.perform SignupFail SignupSuccess


login : String -> String -> Cmd Msg
login usernameOrEmail password =
    Api.login usernameOrEmail password
        |> Task.perform LoginFail LoginSuccess


whoAmI : Token -> Cmd Msg
whoAmI token =
    Api.me token
        |> Task.perform WhoAmIFail WhoAmISuccess
