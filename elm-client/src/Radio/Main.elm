port module Radio.Main exposing (..)

import Api
import Json.Decode exposing (field)
import Http
import Keyboard
import Model
import Navigation exposing (Location)
import Player
import PlayerEngine
import Radio.Model exposing (Model, PlaylistId(..), Page(..))
import Radio.LoginForm as LoginForm
import Radio.Router
import Radio.SignupForm as SignupForm
import Radio.Update as Update exposing (Msg(..))
import Update exposing (andThen, addCmd)
import Radio.View as View
import Task
import Time exposing (Time)
import Tracklist


main : Program String Model Msg
main =
    Navigation.programWithFlags
        (\location -> NavigateTo (route location))
        { init = init
        , view = View.view
        , update = Update.update
        , subscriptions = subscriptions
        }


route : Location -> Page
route location =
    Radio.Router.urlToPage location.pathname


init : String -> Location -> ( Radio.Model.Model, Cmd Msg )
init initialPayloadJsonString location =
    let
        initialPayloadDecoder =
            (field "authToken" (Json.Decode.nullable Json.Decode.string))
        authToken =
            Json.Decode.decodeString initialPayloadDecoder initialPayloadJsonString
                 |> Result.withDefault Nothing
        model =
            { tracks = Tracklist.empty
            , radio = Radio.Model.emptyPlaylist Radio "/api/playlist"
            , showRadioPlaylist = False
            , latestTracks = Radio.Model.emptyPlaylist LatestTracks "/api/latest-tracks"
            , likes = Radio.Model.emptyPlaylist Likes "/api/likes"
            , playing = False
            , currentPage = route location
            , lastKeyPressed = Nothing
            , currentTime = Nothing
            , player = Player.initialize [ Radio, LatestTracks, Likes ]
            , navigation = navigation
            , signupForm = SignupForm.empty
            , loginForm = LoginForm.empty
            , authToken = authToken
            , connectedUser = Nothing
            , redirectToAfterLogin = RadioPage
            }
        navigateToLocation =
            Update.update (NavigateTo (route location))
        initializeRadio =
            Http.send (FetchedMore Radio (RadioPage == route location)) (Api.fetchPlaylist authToken "/api/playlist" Api.decodeTrack)
        fetchLatestTracks =
            Update.update (FetchMore LatestTracks False)
        attemptLogin =
            authToken
                |> Maybe.map (\token -> (Http.send WhoAmI (Api.whoAmI token)))
                |> Maybe.withDefault Cmd.none
        setCurrentTime =
            Task.perform UpdateCurrentTime Time.now
    in
        model
            |> navigateToLocation
            |> andThen fetchLatestTracks
            |> addCmd initializeRadio
            |> addCmd setCurrentTime
            |> addCmd attemptLogin



-- SUBSCRIPTIONS

subscriptions : Radio.Model.Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ PlayerEngine.trackProgress TrackProgress
        , PlayerEngine.trackEnd (\_ -> Next)
        , PlayerEngine.trackError TrackError
        , Keyboard.presses KeyPressed
        ]


navigation : List (Model.NavigationItem Radio.Model.Page PlaylistId)
navigation =
    [ Model.NavigationItem "Radio" "/" RadioPage (Just Radio)
    , Model.NavigationItem "Latest Tracks" "/latest" LatestTracksPage (Just LatestTracks)
    , Model.NavigationItem "Your Likes" "/likes" LikesPage (Just Likes)
    ]
