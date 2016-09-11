port module Main exposing (..)

import Dict exposing (Dict)
import Keyboard
import Model exposing (Model, PlaylistId(..))
import Navigation
import Ports
import Task
import Time exposing (Time)
import Update exposing (Msg(..))
import View
import Player


main : Program Never
main =
    Navigation.program urlParser
        { init = init
        , view = View.view
        , update = Update.update
        , urlUpdate = urlUpdate
        , subscriptions = subscriptions
        }



-- URL PARSERS


urlParser : Navigation.Parser Model.Page
urlParser =
    Navigation.makeParser
        (\{ pathname } ->
            pages
                |> List.filter ((==) pathname << .url)
                |> List.head
                |> Maybe.withDefault (Model.Page "/" (Just Feed))
        )


urlUpdate : Model.Page -> Model -> ( Model, Cmd Update.Msg )
urlUpdate page model =
    ( { model | currentPage = page }
    , Cmd.none
    )



init : Model.Page -> ( Model, Cmd Msg )
init page =
    ( { tracks = Dict.empty
      , playlists = playlists
      , queue = []
      , customQueue = []
      , playing = False
      , currentPage = page
      , lastKeyPressed = Nothing
      , currentTime = Nothing
      , player = Player.initialize [ Feed, SavedTracks, PublishedTracks, Blacklist, CustomQueue ]
      , pages = pages
      , navigation = navigation
      }
    , Cmd.batch
        (List.append
            (List.map Update.fetchMore playlists)
            [Time.now |> Task.perform (\_ -> UpdateCurrentTimeFail) UpdateCurrentTime]
        )
    )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Ports.trackProgress TrackProgress
        , Ports.trackEnd (\_ -> Next)
        , Ports.trackError TrackError
        , Keyboard.presses KeyPressed
        ]


playlists : List Model.Playlist
playlists =
    [ Model.emptyPlaylist Feed "/feed" "fake-url"
    , Model.emptyPlaylist SavedTracks "/saved_tracks" "save_track"
    , Model.emptyPlaylist PublishedTracks "/published_tracks" "publish_track"
    , Model.emptyPlaylist Blacklist "/blacklist" "blacklist"
    ]


pages : List Model.Page
pages =
    [ Model.Page "/" (Just Feed)
    , Model.Page "/saved-tracks" (Just SavedTracks)
    , Model.Page "/published-tracks" (Just PublishedTracks)
    , Model.Page "/publish-track" Nothing
    ]


navigation : List Model.NavigationItem
navigation =
    [ Model.NavigationItem "Feed" "/"
    , Model.NavigationItem "saved tracks" "/saved-tracks"
    , Model.NavigationItem "published tracks" "/published-tracks"
    , Model.NavigationItem "+" "/publish-track"
    ]
