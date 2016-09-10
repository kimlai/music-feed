module View exposing (..)

import Date exposing (Date)
import Dict exposing (Dict)
import Html exposing (Html, a, nav, li, ul, text, div, img)
import Html.Attributes exposing (class, classList, href, src, style)
import Json.Decode
import Html.Events exposing (onClick, onWithOptions)
import Model exposing (Model, Track, TrackId, Playlist, PlaylistId, NavigationItem)
import PlaylistStructure
import Time exposing (Time)
import Update exposing (Msg(..))


view : Model -> Html Msg
view model =
    div
        []
        [ viewGlobalPlayer (Model.currentTrack model) model.playing
        , viewNavigation Model.navigation model.currentPage model.currentPlaylist
        , viewCustomQueue model.tracks model.customQueue
        , div
            [ class "playlist-container" ]
            [ case model.currentPage.playlist of
                Just id ->
                    let
                        currentPagePlaylist =
                            List.filter ((==) id << .id) model.playlists
                                |> List.head
                    in
                        case currentPagePlaylist of
                            Just playlist ->
                                viewPlaylist model.currentTime model.tracks playlist
                            Nothing ->
                                div [] [ text "Well, this is awkward..." ]
                Nothing ->
                    case model.currentPage.url of
                        "/publish-track" ->
                            div [] [ text "Publish Track" ]
                        _ ->
                            div [] [ text "404" ]

            ]
        ]


viewGlobalPlayer : Maybe Track -> Bool -> Html Msg
viewGlobalPlayer track playing =
    case track of
        Nothing ->
            div
                [ class "global-player" ]
                [ div
                    [ class "controls" ]
                    [ div
                        [ class "playback-button" ]
                        [ text "Play" ]
                    , div
                        [ class "next-button" ]
                        [ text "Next" ]
                    ]
                , img [ src "images/placeholder.jpg" ] []
                , div
                    [ class "track-info" ]
                    []
                , div
                    [ class "progress-bar" ]
                    [ div [ class "outer" ] []
                    ]
                , div
                    [ class "actions" ]
                    []
                ]

        Just track ->
            div
                [ class "global-player" ]
                [ div
                    [ class "controls" ]
                    [ div
                        [ classList
                            [ ( "playback-button", True )
                            , ( "playing", playing && not track.error )
                            , ( "error", track.error )
                            ]
                        , onClick (TogglePlayback)
                        ]
                        [ text "Play" ]
                    , div
                        [ class "next-button"
                        , onClick Next
                        ]
                        [ text "Next" ]
                    ]
                , img
                    [ src track.artwork_url ]
                    []
                , div
                    [ class "track-info" ]
                    [ div [ class "artist" ] [ text track.artist ]
                    , div [ class "title" ] [ text track.title ]
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
                , div
                    [ class "actions" ]
                    []
                ]


viewCustomQueue : Dict TrackId Track -> List TrackId -> Html Msg
viewCustomQueue tracks queue =
    queue
        |> List.filterMap (\trackId -> Dict.get trackId tracks)
        |> List.map (viewCustomPlaylistItem)
        |> div [ class "custom-queue" ]


viewCustomPlaylistItem : Track -> Html Msg
viewCustomPlaylistItem track =
    div
        [ class "custom-queue-track"
        , onClick (PlayFromCustomQueue track)
        ]
        [ img [ src track.artwork_url ] []
        , div
            [ class "track-info" ]
            [ div [] [ text track.artist ]
            , div [] [ text track.title ]
            ]
        ]


viewNavigation : List NavigationItem -> Model.Page -> Maybe Model.PlaylistId -> Html Msg
viewNavigation navigationItems currentPage currentPlaylist =
    let
        currentPlaylistPage =
            Model.pages
                |> List.filter ((==) currentPlaylist << .playlist)
                |> List.head
    in
        navigationItems
            |> List.map (viewNavigationItem currentPage currentPlaylistPage)
            |> ul []
            |> List.repeat 1
            |> nav [ class "navigation" ]


viewNavigationItem : Model.Page -> Maybe Model.Page -> NavigationItem -> Html Msg
viewNavigationItem currentPage currentPlaylistPage navigationItem =
    li
        [ onWithOptions
            "click"
            { stopPropagation = False
            , preventDefault = True
            }
            (Json.Decode.succeed (ChangePage navigationItem.href))
        ]
        [ a
            ( classList
                [ ( "active", navigationItem.href == currentPage.url )
                , ( "paying", Just navigationItem.href == Maybe.map .url currentPlaylistPage )
                ]
            :: [ href navigationItem.href ]
            )
            [ text navigationItem.displayName ]
        ]



viewPlaylist : Maybe Time -> Dict TrackId Track -> Playlist -> Html Msg
viewPlaylist currentTime tracks playlist =
    let
        playlistTracks =
            playlist.items
                |> PlaylistStructure.toList
                |> List.filterMap (\trackId -> Dict.get trackId tracks)

        tracksView =
            List.indexedMap (viewTrack currentTime) playlistTracks
    in
        if playlist.loading == True then
            List.repeat 10 viewTrackPlaceHolder
                |> List.append tracksView
                |> div []
        else
            [ (viewMoreButton playlist.id) ]
                |> List.append tracksView
                |> div []


viewTrack : Maybe Time -> Int -> Track -> Html Msg
viewTrack currentTime position track =
    div
        [ classList
            [ ("track", True)
            , ("error", track.error)
            ]
        , onClick (OnTrackClicked position track)
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
                            (Json.Decode.succeed (OnAddTrackToCustomQueueClicked track.id))
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


timeAgo : Maybe Time -> Date -> String
timeAgo currentTime date =
    case currentTime of
        Nothing ->
            ""

        Just time ->
            let
                timeAgo =
                    time - Date.toTime date

                day =
                    24 * Time.hour

                week =
                    7 * day

                month =
                    30 * day

                year =
                    365 * day

                inUnitAgo value ( unitName, unit ) =
                    let
                        valueInUnit =
                            value / unit |> floor

                        pluralize value string =
                            if value > 1 then
                                string ++ "s"
                            else
                                string ++ ""
                    in
                        if valueInUnit == 0 then
                            Nothing
                        else
                            Just (toString valueInUnit ++ " " ++ (pluralize valueInUnit unitName) ++ " ago")
            in
                Maybe.oneOf
                    (List.map
                        (inUnitAgo timeAgo)
                        [ ( "year", year )
                        , ( "month", month )
                        , ( "week", week )
                        , ( "day", day )
                        , ( "hour", Time.hour )
                        , ( "minute", Time.minute )
                        ]
                    )
                    |> Maybe.withDefault "Just now"
