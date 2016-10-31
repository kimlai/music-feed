port module Radio.Main exposing (..)

import Api
import Dict exposing (Dict)
import Json.Decode
import Keyboard
import Model exposing (Page)
import Navigation
import Player
import PlayerEngine
import Radio.Model exposing (PlaylistId(..))
import Radio.Update as Update exposing (Msg(..))
import Radio.View as View
import Task
import Time exposing (Time)


main : Program { token : Maybe String, radioPlaylistJsonString : String }
main =
    Navigation.programWithFlags urlParser
        { init = init
        , view = View.view
        , update = Update.update
        , urlUpdate = urlUpdate
        , subscriptions = subscriptions
        }



-- URL PARSERS


urlParser : Navigation.Parser (Page Radio.Model.PlaylistId)
urlParser =
    Navigation.makeParser
        (\{ pathname } ->
            pages
                |> List.filter ((==) pathname << .url)
                |> List.head
                |> Maybe.withDefault (Page "/" (Just Radio))
        )


urlUpdate : (Page Radio.Model.PlaylistId) -> Radio.Model.Model -> ( Radio.Model.Model, Cmd Msg )
urlUpdate page model =
    ( { model | currentPage = page }
    , Cmd.none
    )


init : { token: Maybe String, radioPlaylistJsonString: String } -> Page Radio.Model.PlaylistId -> ( Radio.Model.Model, Cmd Msg )
init { token, radioPlaylistJsonString } page =
    let
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
            , signup = { username = "", email = "", password = "" }
            , token = token
            , currentUser = Nothing
            }
        decodedRadioPayload =
            Json.Decode.decodeString (Api.decodePlaylist Api.decodeTrack) radioPlaylistJsonString
                |> Result.withDefault ( [], "/playlist" )
        ( model', command ) =
            Update.update (FetchSuccess Radio decodedRadioPayload) model
        ( model'', command' ) =
            if page.playlist == Just Radio then
                Update.update (PlayFromPlaylist Radio 0) model'
            else
                ( model', command )
        ( model''', command'' ) =
            Update.update (FetchMore LatestTracks) model''
        whoAmICmd =
            case token of
                Nothing ->
                    Cmd.none
                Just token ->
                    Update.whoAmI token

    in
        model''' !
            [ command
            , command'
            , command''
            , Time.now |> Task.perform (\_ -> UpdateCurrentTimeFail) UpdateCurrentTime
            , whoAmICmd
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
    , Model.Page "/sign-up" Nothing
    ]


navigation : List Model.NavigationItem
navigation =
    [ Model.NavigationItem "Radio" "/"
    , Model.NavigationItem "Latest Tracks" "/latest"
    ]
