module Radio.Model exposing (..)


import Date exposing (Date)
import Player exposing (Player)
import Radio.LoginForm exposing (LoginForm)
import Radio.SignupForm exposing (SignupForm)
import Time exposing (Time)
import Model exposing (NavigationItem)
import Track exposing (Track, TrackId)
import Tracklist exposing (Tracklist)


type alias Model =
    { tracks : Tracklist
    , radio : Playlist
    , showRadioPlaylist : Bool
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
    , redirectToAfterLogin : Page
    }


type alias ConnectedUser =
    { username : String
    , email : String
    }


type alias Playlist =
    { id: PlaylistId
    , status : PlaylistStatus
    , nextLink : Maybe String
    }


type PlaylistStatus
    = NotRequested
    | Fetching
    | Fetched


emptyPlaylist : PlaylistId -> String -> Playlist
emptyPlaylist id fetchUrl =
    { id = id
    , status = NotRequested
    , nextLink = Just fetchUrl
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
        |> Maybe.andThen ((flip Tracklist.get) model.tracks)
