module View exposing (..)


import Html exposing (Html, div, text, img, ul, li, nav, a)
import Html.Attributes exposing (class, src, classList, style, href)
import Html.Events exposing (onClick, onWithOptions)
import Json.Decode
import Model exposing (Track, Page, NavigationItem, Page)


viewGlobalPlayer : msg -> msg -> Maybe Track -> Bool -> Html msg
viewGlobalPlayer tooglePlayback next track playing =
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
                        , onClick (tooglePlayback)
                        ]
                        [ text "Play" ]
                    , div
                        [ class "next-button"
                        , onClick next
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


viewNavigation : (String -> msg) -> List NavigationItem -> List (Page a) -> Page a -> Maybe a -> Html msg
viewNavigation changePage navigationItems pages currentPage currentPlaylist =
    let
        currentPlaylistPage =
            pages
                |> List.filter ((/=) Nothing << .playlist)
                |> List.filter ((==) currentPlaylist << .playlist)
                |> List.head
    in
        navigationItems
            |> List.map (viewNavigationItem changePage currentPage currentPlaylistPage)
            |> ul []
            |> List.repeat 1
            |> nav [ class "navigation" ]


viewNavigationItem : (String -> msg) -> Page a -> Maybe (Page a) -> NavigationItem -> Html msg
viewNavigationItem changePage currentPage currentPlaylistPage navigationItem =
    li
        [ onWithOptions
            "click"
            { stopPropagation = False
            , preventDefault = True
            }
            (Json.Decode.succeed (changePage navigationItem.href))
        ]
        [ a
            ( classList
                [ ( "active", navigationItem.href == currentPage.url )
                , ( "playing", Just navigationItem.href == Maybe.map .url currentPlaylistPage )
                ]
            :: [ href navigationItem.href ]
            )
            [ text navigationItem.displayName ]
        ]

