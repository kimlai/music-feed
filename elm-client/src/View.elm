module View exposing (..)


import Html exposing (Html, div, text, img, ul, li, nav, a)
import Html.Attributes exposing (class, src, classList, style, href)
import Html.Events exposing (onClick, onWithOptions, on)
import Json.Decode exposing (field)
import Json.Decode.Extra exposing ((|:))
import Model exposing (Track, NavigationItem)


viewGlobalPlayer : msg ->msg -> (Float -> msg) -> Maybe Track -> Bool -> Html msg
viewGlobalPlayer tooglePlayback next seekTo track playing =
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
                , viewProgressBar seekTo track
                , div
                    [ class "actions" ]
                    []
                ]


viewProgressBar : (Float -> msg) -> Track -> Html msg
viewProgressBar seekTo track =
        div
            [ class "progress-bar"
            , on "click" (decodeClickXPosition |> Json.Decode.map seekTo)
            ]
            [ div
                [ class "outer" ]
                [ div
                    [ class "inner"
                    , style [ ( "width", (toString track.progress) ++ "%" ) ]
                    ]
                    []
                ]
            , div
                [ class "drag"
                , on "click" (decodeClickXPosition |> Json.Decode.map seekTo)
                ]
                [ text "" ]
            ]


decodeClickXPosition : Json.Decode.Decoder Float
decodeClickXPosition =
    let
        totalOffset (Element { offsetLeft, offsetParent }) =
            case offsetParent of
                Nothing ->
                    offsetLeft
                Just element ->
                    offsetLeft + (totalOffset element)
    in
        Json.Decode.map2 (/)
            (Json.Decode.map2 (-)
                (Json.Decode.at [ "pageX" ] Json.Decode.float)
                ((Json.Decode.at [ "target" ] decodeElement) |> Json.Decode.map totalOffset)
            )
            (Json.Decode.at [ "target", "offsetWidth" ] Json.Decode.float)
            |> Json.Decode.map ((*) 100)


type Element =
    Element { offsetLeft: Float, offsetParent : Maybe Element }

instanciateElement : Float -> (Maybe Element) -> Element
instanciateElement offsetLeft offsetParent =
    Element
        { offsetLeft = offsetLeft
        , offsetParent = offsetParent
        }


decodeElement : Json.Decode.Decoder Element
decodeElement =
    Json.Decode.succeed instanciateElement
        |: (field "offsetLeft" Json.Decode.float)
        |: (field "offsetParent" (Json.Decode.nullable (Json.Decode.lazy (\_ -> decodeElement))))


viewNavigation : (String -> msg) -> List (NavigationItem page playlist) -> page -> Maybe playlist -> Html msg
viewNavigation followLink navigationItems currentPage currentPlaylist =
    navigationItems
        |> List.map (viewNavigationItem followLink currentPage currentPlaylist)
        |> ul []
        |> List.repeat 1
        |> nav [ class "navigation" ]


viewNavigationItem : (String -> msg) -> page -> Maybe playlist -> NavigationItem page playlist -> Html msg
viewNavigationItem followLink currentPage currentPlaylist navigationItem =
    li
        [ onWithOptions
            "click"
            { stopPropagation = False
            , preventDefault = True
            }
            (Json.Decode.succeed (followLink navigationItem.href))
        ]
        [ a
            ( classList
                [ ( "active", navigationItem.page == currentPage )
                , ( "playing", navigationItem.playlist /= Nothing && navigationItem.playlist == currentPlaylist )
                ]
            :: [ href navigationItem.href ]
            )
            [ text navigationItem.displayName ]
        ]

