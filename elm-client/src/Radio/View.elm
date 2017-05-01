module Radio.View exposing (..)

import Date exposing (Date)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Extra exposing (link)
import Icons
import Json.Decode
import Radio.Model as Model exposing (Model, Playlist, PlaylistId(..), Page(..), ConnectedUser, PlaylistStatus(..))
import Radio.SignupView as SignupView
import Radio.LoginView as LoginView
import Radio.LikesView as LikesView
import Regex
import Player
import Time exposing (Time)
import TimeAgo exposing (timeAgo)
import Radio.Update exposing (Msg(..))
import Track exposing (Track, TrackId, StreamingInfo(..))
import Tracklist exposing (Tracklist)
import View


view : Model -> Html Msg
view model =
    div
        []
        [ View.viewGlobalPlayer
            FollowLink
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
            [ classList
                [ ("radio-playlist-overlay", True )
                , ( "visible", model.showRadioPlaylist )
                ]
            , onClick ToggleRadioPlaylist
            ]
            [ text "" ]
        , viewRadioPlaylist
                model.showRadioPlaylist
                (Player.currentTrack model.player)
                model.tracks
                (Player.playlistContent Radio model.player)
        , div
            [ class "main" ]
            [ case model.currentPage of
                RadioPage ->
                    let
                        currentRadioTrack =
                            Player.currentTrackOfPlaylist Radio model.player
                                |> Maybe.andThen ((flip Tracklist.get) model.tracks)
                    in
                        div [] [ viewRadioTrack currentRadioTrack (Player.currentPlaylist model.player) ]
                PlayedPage ->
                    viewPlayedTracks model.currentPage model.tracks (List.drop 1 model.played)
                UpNextPage ->
                    let
                        playlist =
                            Player.currentPlaylist model.player
                                |> Maybe.withDefault Radio
                    in
                        viewUpcomingTracks
                            model.currentPage
                            model.tracks
                            playlist
                            (Player.upcoming
                                playlist
                                model.player
                            )
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
            div [] [ text "" ]

        Just track ->
            let
                source =
                    case track.streamingInfo of
                        Soundcloud url ->
                            "Soundcloud"
                        Youtube id ->
                            "Youtube"
                onLikeButtonClicked =
                    if track.liked then
                        RemoveLike track.id
                    else
                        AddLike track.id
            in
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
                        , div [ class "artist" ] [ text ("by " ++ track.artist) ]
                        , div
                            [ class "source" ]
                            [ span [] [ text "on " ]
                            , a
                                [ href track.sourceUrl
                                , target "_blank"
                                ]
                                [ text source ]
                            ]
                        , div
                            [ class "like-dislike-buttons" ]
                            [ div
                                [ classList
                                    [ ( "dislike-button", True )
                                    , ( "disliked", False )
                                    ]
                                , onClick Next
                                ]
                                [ Icons.brokenHeart ]
                            , div
                                [ classList
                                    [ ( "like-button", True )
                                    , ( "liked", track.liked )
                                    ]
                                , onClick onLikeButtonClicked
                                ]
                                [ Icons.heart ]
                            ]
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


viewPlayedTracks : Page -> Tracklist -> List TrackId -> Html Msg
viewPlayedTracks currentPage tracks playedTracks =
    div
        [ class "queues" ]
        [ ul
            [ class "nav" ]
            [ li
                [ classList [ ( "active", currentPage == UpNextPage ) ] ]
                [ link FollowLink "/queue/next" [] [ text "Up Next" ] ]
            , li
                [ classList [ ( "active", currentPage == PlayedPage ) ] ]
                [ link FollowLink "/queue/played" [] [ text "Played" ] ]
            ]
        , if List.isEmpty playedTracks then
            div
                [ class "empty-played-tracks" ]
                [ h2 [] [ text "Empty" ]
                , p [] [ text "No tracks have been played yet" ]
                ]
        else
            table
                [ class "played-tracks" ]
                [ thead
                    []
                    [ th [] []
                    , th [] []
                    , th [] []
                    , th [] [ text "Title" ]
                    , th [] [ text "Artist" ]
                    ]
                , tbody
                    []
                    (Tracklist.getTracks playedTracks tracks |> List.map viewPlayedTrack)
                ]
        ]


viewPlayedTrack : Track -> Html Msg
viewPlayedTrack track =
    let
        onLikeButtonClicked =
            if track.liked then
                RemoveLike track.id
            else
                AddLike track.id
    in
    tr
        []
        [ td
            []
            [ div
                [ class "play"
                , onClick (PlayOutsidePlaylist track.id)
                ]
                [ Icons.play ]
            ]
        , td
            []
            [ div
                [ classList
                    [ ( "like-button", True )
                    , ( "liked", track.liked )
                    ]
                , onClick onLikeButtonClicked
                ]
                [ Icons.heart ]
            ]
        , td
            []
            [ div
                [ class "cover" ]
                [ img
                    [ src (Regex.replace Regex.All (Regex.regex "large") (\_ -> "t200x200") track.artwork_url) ]
                    []
                ]
            ]
        , td [] [ div [ class "title" ] [ text track.title ] ]
        , td [] [ div [ class "artist" ] [ text track.artist ] ]
        ]


viewUpcomingTracks : Page -> Tracklist -> PlaylistId -> List ( Int, TrackId ) -> Html Msg
viewUpcomingTracks currentPage tracks playlistId upcomingTracks =
    div
        [ class "queues" ]
        [ ul
            [ class "nav" ]
            [ li
                [ classList [ ( "active", currentPage == UpNextPage ) ] ]
                [ link FollowLink "/queue/next" [] [ text "Up Next" ] ]
            , li
                [ classList [ ( "active", currentPage == PlayedPage ) ] ]
                [ link FollowLink "/queue/played" [] [ text "Played" ] ]
            ]
        , table
            [ class "played-tracks" ]
            [ thead
                []
                [ th [] []
                , th [] []
                , th [] []
                , th [] [ text "Title" ]
                , th [] [ text "Artist" ]
                ]
            , tbody
                []
                (Tracklist.getTracksWithPosition upcomingTracks tracks |> List.map (viewUpcomingTrack playlistId))
            ]
        ]


viewUpcomingTrack : PlaylistId -> ( Int, Track ) -> Html Msg
viewUpcomingTrack playlistId ( position, track ) =
    let
        onLikeButtonClicked =
            if track.liked then
                RemoveLike track.id
            else
                AddLike track.id
    in
    tr
        []
        [ td
            []
            [ div
                [ class "play"
                , onClick (PlayFromPlaylist playlistId position)
                ]
                [ Icons.play ]
            ]
        , td
            []
            [ div
                [ classList
                    [ ( "like-button", True )
                    , ( "liked", track.liked )
                    ]
                , onClick onLikeButtonClicked
                ]
                [ Icons.heart ]
            ]
        , td
            []
            [ div
                [ class "cover" ]
                [ img
                    [ src (Regex.replace Regex.All (Regex.regex "large") (\_ -> "t200x200") track.artwork_url) ]
                    []
                ]
            ]
        , td [] [ div [ class "title" ] [ text track.title ] ]
        , td [] [ div [ class "artist" ] [ text track.artist ] ]
        ]

viewRadioPlaylist : Bool -> Maybe TrackId -> Tracklist -> List TrackId -> Html Msg
viewRadioPlaylist showRadioPlaylist currentTrackId tracks playlistContent =
    Tracklist.getTracks playlistContent tracks
        |> List.indexedMap (viewRadioPlaylistTrack currentTrackId)
        |> div
            [ classList
                [ ( "radio-playlist", True )
                , ( "visible", showRadioPlaylist )
                ]
            ]


viewRadioPlaylistTrack : Maybe TrackId -> Int -> Track -> Html Msg
viewRadioPlaylistTrack currentTrackId position track =
    div
        [ onClick (PlayFromPlaylist Radio position)
        , classList
            [ ("track-info-container", True)
            , ("error", track.error)
            , ("selected", currentTrackId == Just track.id)
            ]
        ]
        [ div
            [ class "cover" ]
            [ img
                [ src (Regex.replace Regex.All (Regex.regex "large") (\_ -> "t200x200") track.artwork_url) ]
                []
            ]
        , div
            []
            [ div
                [ class "track-info" ]
                [ div [ class "title" ] [ text track.title ]
                , div [ class "artist" ] [ text ("by " ++ track.artist) ]
                ]
            ]
        ]


viewLatestTracks : Maybe TrackId -> Maybe Time -> Tracklist -> Playlist -> List TrackId -> Html Msg
viewLatestTracks currentTrackId currentTime tracks playlist playlistContent=
    let
        playlistTracks =
            Tracklist.getTracks playlistContent tracks

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
        , onClick (FetchMore playlistId False)
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
