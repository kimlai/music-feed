port module Feed.Main exposing (..)

import Dict exposing (Dict)
import Feed.Model as Model exposing (Model, PlaylistId(..))
import Feed.Ports as Ports
import Feed.Update as Update exposing (Msg(..))
import Feed.View as View
import Keyboard
import Navigation
import Player
import Task
import Time exposing (Time)


main : Program String
main =
    Navigation.programWithFlags urlParser
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
                |> Maybe.withDefault (Model.Page "/feed" (Just Feed))
        )


urlUpdate : Model.Page -> Model -> ( Model, Cmd Update.Msg )
urlUpdate page model =
    ( { model | currentPage = page }
    , Cmd.none
    )



init : String -> Model.Page -> ( Model, Cmd Msg )
init soundcloudClientId page =
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
