port module Feed.Main exposing (..)

import Dict exposing (Dict)
import Feed.Model exposing (Model, PlaylistId(..), Page(..))
import Feed.Ports as Ports
import Feed.Update as Update exposing (Msg(..))
import Feed.View as View
import Keyboard
import Model
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
            case location.pathname of
                "/feed" -> FeedPage
                "/feed/saved-tracks" -> SavedTracksPage
                "/feed/published-tracks" -> PublishedTracksPage
                "/feed/publish-track" -> PublishNewTrackPage
                _ -> PageNotFound
    in
        ( { tracks = Dict.empty
          , playlists = playlists
          , playing = False
          , currentPage = page
          , lastKeyPressed = Nothing
          , currentTime = Nothing
          , player = Player.initialize [ Feed, SavedTracks, PublishedTracks, Blacklist, CustomQueue ]
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


playlists : List Feed.Model.Playlist
playlists =
    [ Feed.Model.emptyPlaylist Feed "/feed/feed" "fake-url"
    , Feed.Model.emptyPlaylist SavedTracks "/feed/saved_tracks" "/feed/save_track"
    , Feed.Model.emptyPlaylist PublishedTracks "/feed/published_tracks" "/feed/publish_track"
    , Feed.Model.emptyPlaylist Blacklist "/feed/blacklist" "/feed/blacklist"
    ]


navigation : List (Model.NavigationItem Page PlaylistId)
navigation =
    [ Model.NavigationItem "Feed" "/feed" FeedPage (Just Feed)
    , Model.NavigationItem "saved tracks" "/feed/saved-tracks" SavedTracksPage (Just SavedTracks)
    , Model.NavigationItem "published tracks" "/feed/published-tracks" PublishedTracksPage (Just PublishedTracks)
    , Model.NavigationItem "+" "/feed/publish-track" PublishNewTrackPage Nothing
    ]
