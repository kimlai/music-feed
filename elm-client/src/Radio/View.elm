module Radio.View exposing (..)

import Date exposing (Date)
import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode
import Model exposing (Track, TrackId, StreamingInfo(..))
import Radio.Model as Model exposing (Model, Playlist, PlaylistId(..), Page(..), ConnectedUser, PlaylistStatus(..))
import Radio.SignupView as SignupView
import Radio.LoginView as LoginView
import Radio.LikesView as LikesView
import Regex
import Player
import Time exposing (Time)
import TimeAgo exposing (timeAgo)
import Radio.Update exposing (Msg(..))
import View


view : Model -> Html Msg
view model =
    div
        []
        [ View.viewGlobalPlayer
            TogglePlayback
            Next
            SeekTo
            AddLike
            RemoveLike
            (Model.currentTrack model)
            model.playing
        , View.viewNavigation
            FollowLink
            model.navigation
            model.currentPage
            (Player.currentPlaylist model.player)
        , viewConnectedUser model.connectedUser
        , div
            [ class "main" ]
            [ case model.currentPage of
                RadioPage ->
                    let
                        currentRadioTrack =
                            Player.currentTrackOfPlaylist Radio model.player
                                |> Maybe.andThen ((flip Dict.get) model.tracks)
                    in
                        viewRadioTrack currentRadioTrack (Player.currentPlaylist model.player)
                LatestTracksPage ->
                    viewLatestTracks
                        (Player.currentTrack model.player)
                        model.currentTime
                        model.tracks
                        model.latestTracks
                        (Player.playlistContent LatestTracks model.player)
                LikesPage ->
                    viewLatestTracks
                        (Player.currentTrack model.player)
                        model.currentTime
                        model.tracks
                        model.likes
                        (Player.playlistContent Likes model.player)
                Signup ->
                    SignupView.view model.signupForm
                Login ->
                    LoginView.view model.loginForm
                PageNotFound ->
                    div [] [ text "404" ]

            ]
        ]


viewRadioTrack : Maybe Track -> Maybe PlaylistId -> Html Msg
viewRadioTrack track currentPlaylist =
    case track of
        Nothing ->
            div [] [ text "..." ]

        Just track ->
            div
                [ class "radio-track" ]
                [ div
                    [ class "radio-cover" ]
                    [ img
                        [ class "cover"
                        , src (Regex.replace Regex.All (Regex.regex "large") (\_ -> "t500x500") track.artwork_url)
                        ]
                        []
                    ]
                , div
                    [ class "track-info-wrapper" ]
                    [ div
                        [ class "track-info" ]
                        [ div [ class "title" ] [ text track.title ]
                        , div [ class "artist" ] [ text track.artist ]
                        , a
                            [ class "source"
                            , href track.sourceUrl
                            , target "_blank"
                            ]
                            [ text "Source" ]
                        , if currentPlaylist /= Just Radio then
                            div
                                [ class "resume-radio"
                                , onClick ResumeRadio
                                ]
                                [ text "Resume Radio" ]
                            else
                                div [] []
                        ]
                    ]
                ]


viewLatestTracks : Maybe TrackId -> Maybe Time -> Dict TrackId Track -> Playlist -> List TrackId -> Html Msg
viewLatestTracks currentTrackId currentTime tracks playlist playlistContent=
    let
        playlistTracks =
            playlistContent
                |> List.filterMap (\trackId -> Dict.get trackId tracks)

        placeholders =
            if playlist.status == Fetching then
                List.repeat 10 viewTrackPlaceHolder
            else
                []

        moreButton =
            case playlist.nextLink of
                Just url ->
                    viewMoreButton playlist.id
                Nothing ->
                    text ""

        tracksView =
            List.indexedMap (viewTrack currentTrackId currentTime playlist.id) playlistTracks
    in
        div
            [ class "latest-tracks" ]
            [ div
                [ class "content" ]
                (List.append tracksView placeholders)
            , moreButton
            ]


viewTrack : Maybe TrackId -> Maybe Time -> PlaylistId -> Int -> Track -> Html Msg
viewTrack currentTrackId currentTime playlistId position track =
    let
        source =
            case track.streamingInfo of
                Soundcloud url ->
                    "Soundcloud"
                Youtube id ->
                    "Youtube"
    in
    div
        [ classList
            [ ("latest-track", True)
            , ("error", track.error)
            , ("selected", currentTrackId == Just track.id)
            ]
        ]
        [ div
            [ class "track-info-container" ]
            [ div
                [ class "cover"
                , onClick (PlayFromPlaylist playlistId position)
                ]
                [ img
                    [ src (Regex.replace Regex.All (Regex.regex "large") (\_ -> "t200x200") track.artwork_url) ]
                    []
                ]
            , View.viewProgressBar SeekTo track
            , div
                []
                [ div
                    [ class "track-info" ]
                    [ div [ class "artist" ] [ text track.artist ]
                    , div [ class "title" ] [ text track.title ]
                    , a
                        [ class "source"
                        , target "_blank"
                        , href track.sourceUrl
                        ]
                        [ text source ]
                    ]
                ]
            ]
        ]


viewTrackPlaceHolder : Html Msg
viewTrackPlaceHolder =
    div
        [ class "latest-track" ]
        [ div
            [ class "track-info-container" ]
            [ div
                [ class "cover" ]
                [ img [ src "/images/placeholder.jpg" ] [] ]
            , div
                [ class "progress-bar" ]
                [ div [ class "outer" ] [] ]
            ]
        ]


viewMoreButton : PlaylistId -> Html Msg
viewMoreButton playlistId =
    div
        [ class "view-more"
        , onClick (FetchMore playlistId)
        ]
        [ text "More" ]


viewConnectedUser : Maybe ConnectedUser -> Html Msg
viewConnectedUser user =
    case user of
        Nothing ->
            text ""
        Just user ->
            div
                [ class "connected-user" ]
                [ text user.username ]
