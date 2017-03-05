port module Radio.Main exposing (..)

import Api
import Dict exposing (Dict)
import Json.Decode
import Keyboard
import Model exposing (Page)
import Navigation exposing (Location)
import Player
import PlayerEngine
import Radio.Model exposing (Model, PlaylistId(..), Page(..))
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
            case location.pathname of
                "/" -> RadioPage
                "/latest" -> LatestTracksPage
                _ -> PageNotFound
        model =
            { tracks = Dict.empty
            , playlists = playlists
            , playing = False
            , currentPage = page
            , lastKeyPressed = Nothing
            , currentTime = Nothing
            , player = Player.initialize [ Radio, LatestTracks, CustomQueue ]
            , navigation = navigation
            }
        decodedRadioPayload =
            Json.Decode.decodeString (Api.decodePlaylist Api.decodeTrack) radioPlaylistJsonString
                |> Result.withDefault ( [], "/playlist" )
        ( model_, command ) =
            Update.update (FetchedMore Radio (Ok decodedRadioPayload)) model
        ( model__, command_ ) =
            if page == RadioPage then
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


navigation : List (Model.NavigationItem Radio.Model.Page PlaylistId)
navigation =
    [ Model.NavigationItem "Radio" "/" RadioPage (Just Radio)
    , Model.NavigationItem "Latest Tracks" "/latest" LatestTracksPage (Just LatestTracks)
    ]
