module Feed.Model exposing (..)


import Date exposing (Date)
import Dict exposing (Dict)
import Player exposing (Player)
import Time exposing (Time)
import Model exposing (Track, TrackId)


type alias Model =
    { tracks : Dict TrackId Track
    , playlists : List Playlist
    , playing : Bool
    , currentPage : Page
    , lastKeyPressed : Maybe Char
    , currentTime : Maybe Time
    , player : Player PlaylistId TrackId
    , pages : List Page
    , navigation : List NavigationItem
    , soundcloudClientId : String
    }


type alias NavigationItem =
    { displayName : String
    , href : String
    }

type alias Page =
    { url : String
    , playlist : Maybe PlaylistId
    }


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
    = Feed
    | SavedTracks
    | PublishedTracks
    | Blacklist
    | CustomQueue


currentPlaylist : Model -> Maybe Playlist
currentPlaylist model =
    List.filter ((==) (Player.currentPlaylist model.player) << Just << .id) model.playlists
        |> List.head


currentTrack : Model -> Maybe Track
currentTrack model =
    Player.currentTrack model.player
        `Maybe.andThen` (flip Dict.get) model.tracks
