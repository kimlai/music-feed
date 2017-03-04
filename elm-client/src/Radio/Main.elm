port module Radio.Main exposing (..)

import Api
import Dict exposing (Dict)
import Json.Decode
import Keyboard
import Model exposing (Page)
import Navigation exposing (Location)
import Player
import PlayerEngine
import Radio.Model exposing (Model, PlaylistId(..))
import Radio.Update as Update exposing (Msg(..))
import Radio.View as View
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



init : String -> Location -> ( Radio.Model.Model, Cmd Msg )
init radioPlaylistJsonString location =
    let
        page =
            pages
                |> List.filter ((==) location.pathname << .url)
                |> List.head
                |> Maybe.withDefault (Page "/" (Just Radio))
        model =
            { tracks = Dict.empty
            , playlists = playlists
            , playing = False
            , currentPage = page
            , lastKeyPressed = Nothing
            , currentTime = Nothing
            , player = Player.initialize [ Radio, LatestTracks, CustomQueue ]
            , pages = pages
            , navigation = navigation
            }
        decodedRadioPayload =
            Json.Decode.decodeString (Api.decodePlaylist Api.decodeTrack) radioPlaylistJsonString
                |> Result.withDefault ( [], "/playlist" )
        ( model_, command ) =
            Update.update (FetchedMore Radio (Ok decodedRadioPayload)) model
        ( model__, command_ ) =
            if page.playlist == Just Radio then
                Update.update (PlayFromPlaylist Radio 0) model_
            else
                ( model_, command )
        ( model___, command__ ) =
            Update.update (FetchMore LatestTracks) model__
    in
        model___ !
            [ command
            , command_
            , command__
            , Time.now |> Task.perform UpdateCurrentTime
            ]



-- SUBSCRIPTIONS

subscriptions : Radio.Model.Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ PlayerEngine.trackProgress TrackProgress
        , PlayerEngine.trackEnd (\_ -> Next)
        , PlayerEngine.trackError TrackError
        , Keyboard.presses KeyPressed
        ]


playlists : List Radio.Model.Playlist
playlists =
    [ Radio.Model.emptyPlaylist Radio "/api/playlist" "fake-url"
    , Radio.Model.emptyPlaylist LatestTracks "/api/latest-tracks" "fake-url"
    ]


pages : List (Page Radio.Model.PlaylistId)
pages =
    [ Model.Page "/" (Just Radio)
    , Model.Page "/latest" (Just LatestTracks)
    ]


navigation : List Model.NavigationItem
navigation =
    [ Model.NavigationItem "Radio" "/"
    , Model.NavigationItem "Latest Tracks" "/latest"
    ]
