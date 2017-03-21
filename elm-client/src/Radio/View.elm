module Radio.View exposing (..)

import Date exposing (Date)
import Dict exposing (Dict)
import Html exposing (Html, a, nav, li, ul, text, div, img, input, label, button, h1, span)
import Html.Attributes exposing (class, classList, href, src, style, target, type_, for, placeholder, value, disabled, name)
import Json.Decode
import Html.Events exposing (onClick, onWithOptions, onInput, onBlur, onSubmit)
import Model exposing (Track, TrackId, StreamingInfo(..))
import Radio.Model as Model exposing (Model, Playlist, PlaylistId(..), Page(..))
import Radio.SignupForm as SignupForm exposing (SignupForm, Field(..))
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
        [ View.viewGlobalPlayer TogglePlayback Next SeekTo (Model.currentTrack model) model.playing
        , View.viewNavigation
            FollowLink
            model.navigation
            model.currentPage
            (Player.currentPlaylist model.player)
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
                Signup ->
                    viewSignup model.signupForm
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
            if playlist.loading == True then
                List.repeat 10 viewTrackPlaceHolder
            else
                []

        moreButton =
            if playlist.loading == False then
                viewMoreButton playlist.id
            else
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


viewSignup : SignupForm -> Html Msg
viewSignup form =
    Html.form
        [ class "signup-form"
        , onSubmit SignupSubmit
        ]
        [ h1 [] [ text "Create an account to save tracks" ]
        , div
            []
            [ input
                [ type_ "text"
                , placeholder "Username"
                , name "name"
                , value form.username
                , onInput SignupUpdateUsername
                , onBlur (SignupBlurredField Username)
                ]
                []
            , div
                [ class "error" ]
                [ text (SignupForm.error Username form |> Maybe.withDefault "") ]
            ]
        , div
            []
            [ input
                [ type_ "text"
                , name "email"
                , placeholder "E-mail"
                , value form.email
                , onInput SignupUpdateEmail
                , onBlur (SignupBlurredField Email)
                ]
                []
            , div
                [ class "error" ]
                [ text (SignupForm.error Email form |> Maybe.withDefault "") ]
            ]
        , div
            []
            [ input
                [ type_ "password"
                , placeholder "Password"
                , value form.password
                , onInput SignupUpdatePassword
                , onBlur (SignupBlurredField Password)
                ]
                []
            , div
                [ class "error" ]
                [ text (SignupForm.error Password form |> Maybe.withDefault "") ]
            ]
        , button
            [ type_ "submit"
            , disabled (not (SignupForm.isValid form))
            ]
            [ text "Go!" ]
        ]
