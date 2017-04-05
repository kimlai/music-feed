module Radio.Model exposing (..)


import Date exposing (Date)
import Dict exposing (Dict)
import Player exposing (Player)
import Radio.LoginForm exposing (LoginForm)
import Radio.SignupForm exposing (SignupForm)
import Time exposing (Time)
import Model exposing (Track, TrackId, NavigationItem)


type alias Model =
    { tracks : Dict TrackId Track
    , radio : Playlist
    , latestTracks : Playlist
    , likes : Playlist
    , playing : Bool
    , currentPage : Page
    , lastKeyPressed : Maybe Char
    , currentTime : Maybe Time
    , player : Player PlaylistId TrackId
    , navigation : List (NavigationItem Page PlaylistId)
    , signupForm : SignupForm
    , loginForm : LoginForm
    , authToken : Maybe String
    , connectedUser : Maybe ConnectedUser
    }


type alias ConnectedUser =
    { username : String
    , email : String
    }


type alias Playlist =
    { id: PlaylistId
    , loading : Bool
    , nextLink : String
    }


emptyPlaylist : PlaylistId -> String -> Playlist
emptyPlaylist id fetchUrl =
    { id = id
    , loading = True
    , nextLink = fetchUrl
    }


type Page
    = RadioPage
    | LatestTracksPage
    | LikesPage
    | Signup
    | PageNotFound
    | Login


type PlaylistId
    = Radio
    | LatestTracks
    | Likes


currentTrack : Model -> Maybe Track
currentTrack model =
    Player.currentTrack model.player
        |> Maybe.andThen ((flip Dict.get) model.tracks)
