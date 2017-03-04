port module Feed.Main exposing (..)

import Dict exposing (Dict)
import Feed.Model as Model exposing (Model, PlaylistId(..))
import Feed.Ports as Ports
import Feed.Update as Update exposing (Msg(..))
import Feed.View as View
import Keyboard
import Navigation exposing (Location)
import Player
import PlayerEngine
import Task
import Time exposing (Time)


main : Program String Model Msg
main =
    Navigation.programWithFlags
        (\location -> ChangePage location.pathname)
        { init = init
        , view = View.view
        , update = Update.update
        , subscriptions = subscriptions
        }



init : String -> Location -> ( Model, Cmd Msg )
init soundcloudClientId location =
    let
        page =
            pages
                |> List.filter ((==) location.pathname << .url)
                |> List.head
                |> Maybe.withDefault (Model.Page "/feed" (Just Feed))
    in
        ( { tracks = Dict.empty
          , playlists = playlists
          , playing = False
          , currentPage = page
          , lastKeyPressed = Nothing
          , currentTime = Nothing
          , player = Player.initialize [ Feed, SavedTracks, PublishedTracks, Blacklist, CustomQueue ]
          , pages = pages
          , navigation = navigation
          , soundcloudClientId = soundcloudClientId
          , youtubeTrackPublication = Nothing
        }
        , Cmd.batch
            (List.append
                (List.map Update.fetchMore playlists)
                [Time.now |> Task.perform UpdateCurrentTime]
            )
        )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ PlayerEngine.trackProgress TrackProgress
        , PlayerEngine.trackEnd (\_ -> Next)
        , PlayerEngine.trackError TrackError
        , Ports.imageUploaded ImageUploaded
        , Keyboard.presses KeyPressed
        ]


playlists : List Model.Playlist
playlists =
    [ Model.emptyPlaylist Feed "/feed/feed" "fake-url"
    , Model.emptyPlaylist SavedTracks "/feed/saved_tracks" "/feed/save_track"
    , Model.emptyPlaylist PublishedTracks "/feed/published_tracks" "/feed/publish_track"
    , Model.emptyPlaylist Blacklist "/feed/blacklist" "/feed/blacklist"
    ]


pages : List Model.Page
pages =
    [ Model.Page "/" (Just Feed)
    , Model.Page "/feed/saved-tracks" (Just SavedTracks)
    , Model.Page "/feed/published-tracks" (Just PublishedTracks)
    , Model.Page "/feed/publish-track" Nothing
    ]


navigation : List Model.NavigationItem
navigation =
    [ Model.NavigationItem "Feed" "/feed"
    , Model.NavigationItem "saved tracks" "/feed/saved-tracks"
    , Model.NavigationItem "published tracks" "/feed/published-tracks"
    , Model.NavigationItem "+" "/feed/publish-track"
    ]
