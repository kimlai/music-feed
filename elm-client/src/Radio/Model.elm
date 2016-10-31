module Radio.Model exposing (..)


import Date exposing (Date)
import Dict exposing (Dict)
import Player exposing (Player)
import Time exposing (Time)
import Model exposing (Track, TrackId, NavigationItem, Page)


type alias Model =
    { tracks : Dict TrackId Track
    , playlists : List Playlist
    , playing : Bool
    , currentPage : Page PlaylistId
    , lastKeyPressed : Maybe Char
    , currentTime : Maybe Time
    , player : Player PlaylistId TrackId
    , pages : List (Page PlaylistId)
    , navigation : List NavigationItem
    , signup : SignupModel
    , token : Maybe Token
    }


type alias SignupModel =
    { username : String
    , email : String
    , password : String
    }


type alias Token = String


type alias Playlist =
    { id: PlaylistId
    , loading : Bool
    , nextLink : String
    , addTrackUrl : String
    }


emptyPlaylist : PlaylistId -> String -> String -> Playlist
emptyPlaylist id fetchUrl addTrackUrl =
    { id = id
    , loading = True
    , nextLink = fetchUrl
    , addTrackUrl = addTrackUrl
    }


type PlaylistId
    = Radio
    | LatestTracks
    | CustomQueue


currentPlaylist : Model -> Maybe Playlist
currentPlaylist model =
    List.filter ((==) (Player.currentPlaylist model.player) << Just << .id) model.playlists
        |> List.head


currentTrack : Model -> Maybe Track
currentTrack model =
    Player.currentTrack model.player
        `Maybe.andThen` (flip Dict.get) model.tracks
