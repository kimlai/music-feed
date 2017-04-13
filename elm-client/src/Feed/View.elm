module Feed.View exposing (..)

import Date exposing (Date)
import Dict exposing (Dict)
import Feed.Model as Model exposing (Model, Playlist, PlaylistId(..), Page(..))
import Feed.Update exposing (Msg(..))
import Html exposing (Html, a, nav, li, ul, text, div, img, input, label, form, button)
import Html.Attributes exposing (class, classList, href, src, style, value, id, type_)
import Html.Events exposing (onClick, onWithOptions, onInput)
import Json.Decode
import Player
import Time exposing (Time)
import TimeAgo exposing (timeAgo)
import Track exposing (Track, TrackId)
import Tracklist exposing (Tracklist)
import View


view : Model -> Html Msg
view model =
    let
        getPlaylist id =
            List.filter ((==) id << .id) model.playlists
                |> List.head
    in
    div
        []
        [ View.viewGlobalPlayer
            TogglePlayback
            Next
            Next
            SeekTo
            (MoveToPlaylist SavedTracks)
            (MoveToPlaylist Blacklist)
            (Model.currentTrack model)
            model.playing
        , View.viewNavigation
            FollowLink
            model.navigation
            model.currentPage
            (Player.currentPlaylist model.player)
        , viewCustomQueue model.tracks (Player.playlistContent CustomQueue model.player)
        , div
            [ class "playlist-container" ]
            [ case model.currentPage of
                FeedPage ->
                    case getPlaylist Feed of
                        Just playlist ->
                            viewPlaylist
                                model.currentTime
                                model.tracks playlist
                                (Player.playlistContent Feed model.player)
                        Nothing ->
                            div [] [ text "Well, this is awkward..." ]
                SavedTracksPage ->
                    case getPlaylist SavedTracks of
                        Just playlist ->
                            viewPlaylist
                                model.currentTime
                                model.tracks playlist
                                (Player.playlistContent SavedTracks model.player)
                        Nothing ->
                            div [] [ text "Well, this is awkward..." ]
                PublishedTracksPage ->
                    case getPlaylist PublishedTracks of
                        Just playlist ->
                            viewPlaylist
                                model.currentTime
                                model.tracks playlist
                                (Player.playlistContent PublishedTracks model.player)
                        Nothing ->
                            div [] [ text "Well, this is awkward..." ]
                PublishNewTrackPage ->
                    viewPublishTrack model.youtubeTrackPublication
                PageNotFound ->
                    div [] [ text "404" ]

            ]
        ]


viewCustomQueue : Tracklist -> List TrackId -> Html Msg
viewCustomQueue tracks queue =
    tracks
        |> Tracklist.getTracks queue
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


viewPlaylist : Maybe Time -> Tracklist -> Playlist -> List TrackId -> Html Msg
viewPlaylist currentTime tracks playlist playlistContent=
    let
        playlistTracks =
            Tracklist.getTracks playlistContent tracks

        tracksView =
            List.indexedMap (viewTrack currentTime playlist.id) playlistTracks
    in
        if playlist.loading == True then
            List.repeat 10 viewTrackPlaceHolder
                |> List.append tracksView
                |> div []
        else
            [ (viewMoreButton playlist.id) ]
                |> List.append tracksView
                |> div []


viewTrack : Maybe Time -> PlaylistId -> Int -> Track -> Html Msg
viewTrack currentTime playlistId position track =
    div
        [ classList
            [ ("track", True)
            , ("error", track.error)
            ]
        , onClick (PlayFromPlaylist playlistId position track)
        ]
        [ div
            [ class "track-info-container" ]
            [ img [ src track.artwork_url ]
                []
            , div
                []
                [ div
                    [ class "track-info" ]
                    [ div [] [ text track.artist ]
                    , div [] [ text track.title ]
                    ]
                , div
                    [ class "actions" ]
                    [ div
                        [ onWithOptions
                            "click"
                            { stopPropagation = True
                            , preventDefault = True
                            }
                            (Json.Decode.succeed (AddToCustomQueue track.id))
                        ]
                        [ text "Add to queue" ]
                    ]
                ]
            , div
                [ class "time-ago" ]
                [ text (timeAgo currentTime track.createdAt) ]
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
        ]


viewTrackPlaceHolder : Html Msg
viewTrackPlaceHolder =
    div
        [ class "track" ]
        [ div
            [ class "track-info-container" ]
            [ img [ src "/images/placeholder.jpg" ] [] ]
        , div
            [ class "progress-bar" ]
            [ div [ class "outer" ] [] ]
        ]


viewMoreButton : PlaylistId -> Html Msg
viewMoreButton playlistId =
    div
        [ class "more-button"
        , onClick (FetchMore playlistId)
        ]
        [ text "More" ]


viewPublishTrack : Maybe Track -> Html Msg
viewPublishTrack newTrack =
    div
        []
        [ div
            []
            [ label [] [ text "Soundcloud" ]
            , input [ onInput PublishFromSoundcloudUrl ] []
            ]
        , div
            []
            [ label [] [ text "Youtube" ]
            , input [ onInput ParseYoutubeUrl ] []
            ]
        , viewNewTrackForm newTrack
        ]


viewNewTrackForm : Maybe Track -> Html Msg
viewNewTrackForm newTrack =
    case newTrack of
        Nothing ->
            text ""
        Just track ->
            div
                [ class "new-track-form" ]
                [ div
                    []
                    [ label [] [ text "Artist" ]
                    , input
                        [ value track.artist
                        , onInput UpdateNewTrackArtist
                        ]
                        []
                    ]
                , div
                    []
                    [ label [] [ text "Title" ]
                    , input
                        [ value track.title
                        , onInput UpdateNewTrackTitle
                        ]
                        []
                    ]
                , form
                    [ id "cover-upload" ]
                    [ input [ type_ "file" ] []
                    , div
                        [ onClick UploadImage ]
                        [ text "Upload" ]
                , div
                    [ onClick (PublishYoutubeTrack track) ]
                    [ text "Publish" ]
                ]
            ]
