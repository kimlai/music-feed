module Radio.Update exposing (..)


import Api
import Char
import Dict
import Http exposing (Error(..))
import Json.Decode
import Keyboard
import Model exposing (Track, TrackId, StreamingInfo(..))
import Navigation
import Player
import PlayerEngine
import Radio.Model as Model exposing (Model, PlaylistId(..), Page(..), ConnectedUser, PlaylistStatus(..))
import Radio.Ports as Ports
import Radio.Router
import Radio.SignupForm as SignupForm exposing (Field(..))
import Radio.LoginForm as LoginForm
import Task exposing (Task)
import Time exposing (Time)
import Update


type Msg
    = TogglePlayback
    | Next
    | TrackProgress ( TrackId, Float, Float )
    | Play
    | Pause
    | TrackError TrackId
    | FastForward
    | Rewind
    | FollowLink String
    | NavigateTo Page
    | KeyPressed Keyboard.KeyCode
    | UpdateCurrentTime Time
    | PlayFromPlaylist PlaylistId Int
    | FetchMore PlaylistId
    | FetchedMore PlaylistId (Result Http.Error ( List Track, Maybe String ))
    | FetchedRadio (Result Http.Error ( List Track, Maybe String ))
    | ReportedDeadTrack (Result Http.Error String)
    | ResumeRadio
    | SeekTo Float
    | SignupUpdateEmail String
    | SignupBlurredField Field
    | SignupEmailAvailability (Result Http.Error ( ( String, Bool ), ( String, Bool ) ))
    | SignupUpdateUsername String
    | SignupUpdatePassword String
    | SignupSubmit
    | SignupSubmitted (Result Http.Error String)
    | LoginUpdateEmailOrUsername String
    | LoginUpdatePassword String
    | LoginBlurredField LoginForm.Field
    | LoginSubmit
    | LoginSubmitted (Result Http.Error String)
    | WhoAmI (Result Http.Error ConnectedUser)
    | AddLike TrackId
    | AddedLike (Result Http.Error String)
    | RemoveLike TrackId
    | RemovedLike (Result Http.Error String)


update : Msg -> Model -> ( Model, Cmd Msg )
update message model =
    case message of
        FetchedRadio (Ok ( tracks, nextLink )) ->
            let
                updatePlaylist playlist =
                    { playlist | nextLink = nextLink
                    , status = Fetched
                    }
                updatedTracks =
                    tracks
                        |> List.map (\track -> ( track.id, track ))
                        |> Dict.fromList
                        |> Dict.union model.tracks
                updatedModel =
                    { model
                    | tracks = updatedTracks
                    , player = Player.appendTracksToPlaylist Radio (List.map .id tracks) model.player
                    }
            in
                ( { updatedModel | radio = updatePlaylist model.radio } , Cmd.none)
                    |> Update.when ((==) RadioPage << .currentPage) (update (PlayFromPlaylist Radio 0))

        FetchedRadio (Err error)->
            ( model, Cmd.none )

        FetchedMore playlistId (Ok ( tracks, nextLink )) ->
            let
                updatePlaylist playlist =
                    { playlist | nextLink = nextLink
                    , status = Fetched
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
                    Likes ->
                        ( { updatedModel | likes = updatePlaylist model.likes }
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
                markAsFetching playlist =
                    { playlist | status = Fetching }
                ( playlist, updateModel ) =
                    case playlistId of
                        Radio ->
                            ( model.radio, (\model fn -> { model | radio = fn model.radio }) )
                        LatestTracks ->
                            ( model.latestTracks, (\model fn -> { model | latestTracks = fn model.latestTracks }) )
                        Likes ->
                            ( model.likes, (\model fn -> { model | likes = fn model.likes }) )
            in
                case playlist.nextLink of
                    Nothing ->
                        ( model, Cmd.none )
                    Just url ->
                        ( updateModel model markAsFetching
                        , Http.send (FetchedMore playlistId) (Api.fetchPlaylist model.authToken url Api.decodeTrack)
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

        NavigateTo page ->
            let
                updateModel model =
                    ( { model | currentPage = page }
                    , Cmd.none
                    )
            in
                if page == LikesPage then
                    redirectToSignupIfNoAuthToken
                        model
                        (Just LikesPage)
                        (\model token ->
                            updateModel model
                                |> Update.when ((==) NotRequested << .status << .likes) (update (FetchMore Likes)))
                else
                    updateModel model

        FollowLink url ->
            ( model
            , Navigation.newUrl url
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

        SignupUpdateUsername newUsername ->
            ( { model | signupForm = SignupForm.updateUsername newUsername model.signupForm }
            , if SignupForm.shouldBeValid Username model.signupForm then
                Http.send
                    SignupEmailAvailability
                    (Api.checkEmailAvailabilty model.signupForm.email newUsername)
            else
                Cmd.none
            )

        SignupUpdatePassword newPassword ->
            ( { model | signupForm = SignupForm.updatePassword newPassword model.signupForm }
            , Cmd.none
            )

        SignupUpdateEmail newEmail ->
            ( { model | signupForm = SignupForm.updateEmail newEmail model.signupForm }
            , if SignupForm.shouldBeValid Email model.signupForm then
                Http.send
                    SignupEmailAvailability
                    (Api.checkEmailAvailabilty newEmail model.signupForm.username)
            else
                Cmd.none
            )

        SignupBlurredField field ->
            ( { model | signupForm = SignupForm.startValidating field model.signupForm }
            , case field of
                Username ->
                    Http.send
                        SignupEmailAvailability
                        (Api.checkEmailAvailabilty model.signupForm.email model.signupForm.username)
                Email ->
                    Http.send
                        SignupEmailAvailability
                        (Api.checkEmailAvailabilty model.signupForm.email model.signupForm.username)
                Password ->
                    Cmd.none
            )

        SignupEmailAvailability (Ok availability) ->
            ( { model | signupForm = SignupForm.updateAvailabilities availability model.signupForm }
            , Cmd.none
            )

        SignupEmailAvailability (Err _) ->
            ( model , Cmd.none )

        SignupSubmit ->
            ( { model | signupForm =
                model.signupForm
                    |> SignupForm.startValidating Username
                    |> SignupForm.startValidating Email
                    |> SignupForm.startValidating Password
              }
            , Http.send SignupSubmitted (Api.signup model.signupForm)
            )

        SignupSubmitted (Ok _) ->
            ( { model | authToken = Just "coucou" }
            , Http.send LoginSubmitted (Api.login model.signupForm.username model.signupForm.password)
            )

        SignupSubmitted (Err error) ->
            case Debug.log "error" error of
                BadStatus response ->
                    if response.status.code == 400 then
                        let
                            errors =
                                Json.Decode.decodeString
                                    Api.decodeSignupErrors
                                    response.body
                                    |> Result.withDefault []
                        in
                            ( { model | signupForm = SignupForm.setServerErrors errors model.signupForm }
                            , Cmd.none
                            )
                    else
                        ( model, Cmd.none )
                _ ->
                    ( model , Cmd.none )

        LoginUpdateEmailOrUsername newEmailOrUsername ->
            ( { model | loginForm = LoginForm.updateEmailOrUsername newEmailOrUsername model.loginForm }
            , Cmd.none
            )

        LoginUpdatePassword newPassword ->
            ( { model | loginForm = LoginForm.updatePassword newPassword model.loginForm }
            , Cmd.none
            )

        LoginBlurredField field ->
            ( { model | loginForm = LoginForm.startValidating field model.loginForm }
            , Cmd.none
            )

        LoginSubmit ->
            ( { model | loginForm =
                model.loginForm
                    |> LoginForm.startValidating LoginForm.EmailorUsername
                    |> LoginForm.startValidating LoginForm.Password
              }
            , Http.send LoginSubmitted (Api.login model.loginForm.emailOrUsername model.loginForm.password)
            )

        LoginSubmitted (Ok token) ->
            ( { model | authToken = Just token }
            , Cmd.batch
                [ Http.send WhoAmI (Api.whoAmI token)
                , Ports.storeAuthToken token
                ]
            )
                |> Update.andThen (update (FollowLink (Radio.Router.pageToUrl model.redirectToAfterLogin)))

        LoginSubmitted (Err error) ->
            case error of
                BadStatus response ->
                    if response.status.code == 400 then
                        let
                            errors =
                                Json.Decode.decodeString
                                    Api.decodeLoginErrors
                                    response.body
                                    |> Result.withDefault []
                        in
                            ( { model | loginForm = LoginForm.setServerErrors errors model.loginForm }
                            , Cmd.none
                            )
                    else
                        ( model, Cmd.none )
                _ ->
                    ( model , Cmd.none )

        WhoAmI (Ok user) ->
            ( { model | connectedUser = Just user }
            , Cmd.none
            )

        WhoAmI (Err error) ->
            ( model, Cmd.none )

        AddLike trackId ->
            let
                updateTrack track =
                    { track | liked = True }
                updateModel model =
                    { model
                    | player = Player.prependTrackToPlaylist Likes trackId model.player
                    , tracks = Dict.update trackId (Maybe.map updateTrack) model.tracks
                    }
            in
                redirectToSignupIfNoAuthToken
                    model
                    Nothing
                    (\model token ->
                        ( updateModel model
                        , Http.send AddedLike (Api.addLike token trackId)
                        )
                    )

        AddedLike (Ok _) ->
            ( model, Cmd.none )

        AddedLike (Err error) ->
            redirectToSignupIf401 error Nothing model

        RemoveLike trackId ->
            let
                updateTrack track =
                    { track | liked = False }
                updateModel model =
                    { model
                    | player = Player.removeTrackFromPlaylist Likes trackId model.player
                    , tracks = Dict.update trackId (Maybe.map updateTrack) model.tracks
                    }
            in
                redirectToSignupIfNoAuthToken
                    model
                    Nothing
                    (\model token ->
                        ( updateModel model
                        , Http.send RemovedLike (Api.removeLike token trackId)
                        )
                    )

        RemovedLike (Ok _) ->
            ( model, Cmd.none )

        RemovedLike (Err error) ->
            redirectToSignupIf401 error Nothing model

        KeyPressed keyCode ->
            case model.currentPage of
                Signup ->
                    ( model, Cmd.none )
                Login ->
                    ( model, Cmd.none )
                _ ->
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


reportDeadTrack : TrackId -> Cmd Msg
reportDeadTrack trackId =
    Http.send ReportedDeadTrack (Api.reportDeadTrack trackId)


redirectToSignup : Maybe Page -> Model -> ( Model, Cmd Msg )
redirectToSignup page model =
    ( { model | redirectToAfterLogin = Maybe.withDefault model.currentPage page }
    , Navigation.modifyUrl "/sign-up"
    )


redirectToSignupIfNoAuthToken : Model -> Maybe Page -> (Model -> String -> ( Model, Cmd Msg )) -> ( Model, Cmd Msg )
redirectToSignupIfNoAuthToken model page ifAuthenticated =
    case model.authToken of
        Nothing ->
            redirectToSignup page model
        Just token ->
            ifAuthenticated model token


redirectToSignupIf401 : Http.Error -> Maybe Page -> Model -> ( Model, Cmd Msg )
redirectToSignupIf401 error page =
    case error of
        Http.BadStatus response ->
            if response.status.code == 401 then
                redirectToSignup page
            else
                Update.identity
        _ ->
            Update.identity
