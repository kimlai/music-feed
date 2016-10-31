module Radio.View exposing (..)

import Date exposing (Date)
import Dict exposing (Dict)
import Html exposing (Html, a, nav, li, ul, text, div, img, label, input, p, button)
import Html.Attributes exposing (class, classList, href, src, style, target)
import Json.Decode
import Html.Events exposing (onClick, onWithOptions, onInput)
import Model exposing (Track, TrackId, StreamingInfo(..))
import Radio.Model as Model exposing (Model, Playlist, PlaylistId(..))
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
            ChangePage
            model.navigation
            model.pages
            model.currentPage
            (Player.currentPlaylist model.player)
        , div
            []
            [ case model.currentPage.url of
                "/" ->
                    let
                        currentRadioTrack =
                            Player.currentTrackOfPlaylist Radio model.player
                                `Maybe.andThen` (flip Dict.get) model.tracks
                    in
                        viewRadioTrack currentRadioTrack (Player.currentPlaylist model.player)
                "/latest" ->
                    let
                        latestTracksPlaylist =
                            List.filter ((==) LatestTracks << .id) model.playlists
                                |> List.head
                    in
                        case latestTracksPlaylist of
                            Just playlist ->
                                viewLatestTracks
                                    (Player.currentTrack model.player)
                                    model.currentTime
                                    model.tracks
                                    playlist
                                    (Player.playlistContent LatestTracks model.player)
                            Nothing ->
                                div [] [ text "Well, this is awkward..." ]
                "/sign-up" ->
                    viewSignup model.signup
                _ ->
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


viewCustomQueue : Dict TrackId Track -> List TrackId -> Html Msg
viewCustomQueue tracks queue =
    queue
        |> List.filterMap (\trackId -> Dict.get trackId tracks)
        |> List.indexedMap (viewCustomPlaylistItem)
        |> div [ class "custom-queue" ]


viewCustomPlaylistItem : Int -> Track -> Html Msg
viewCustomPlaylistItem position track =
    div
        [ class "custom-queue-track"
        , onClick (PlayFromCustomQueue position track)
        ]
        [ img [ src track.artwork_url ] []
        , div
            [ class "track-info" ]
            [ div [] [ text track.artist ]
            , div [] [ text track.title ]
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


viewSignup : Model.SignupModel -> Html Msg
viewSignup signupModel =
    div
        [ class "signup" ]
        [ p [] [ text "Create an account to save the tracks you like" ]
        , label [] [ text "Username"]
        , input
            [ onInput (SignupUpdateUsername)]
            []
        , label [] [ text "Email"]
        , input
            [ onInput (SignupUpdateEmail)]
            []
        , label [] [ text "Password"]
        , input
            [ onInput (SignupUpdatePassword)]
            []
        , button
            [ onClick SignupSubmit ]
            [ text "Submit" ]
        ]
