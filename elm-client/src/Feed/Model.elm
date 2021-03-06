module Feed.Model exposing (..)


import Date exposing (Date)
import Dict exposing (Dict)
import Player exposing (Player)
import Time exposing (Time)
import Model exposing (NavigationItem)
import Track exposing (Track, TrackId)
import Tracklist exposing (Tracklist)


type alias Model =
    { tracks : Tracklist
    , playlists : List Playlist
    , playing : Bool
    , currentPage : Page
    , lastKeyPressed : Maybe Char
    , currentTime : Maybe Time
    , player : Player PlaylistId TrackId
    , navigation : List (NavigationItem Page PlaylistId)
    , soundcloudClientId : String
    , youtubeTrackPublication : Maybe Track
    }


type alias Playlist =
    { id: PlaylistId
    , loading : Bool
    , nextLink : Maybe String
    , addTrackUrl : String
    }


emptyPlaylist : PlaylistId -> String -> String -> Playlist
emptyPlaylist id fetchUrl addTrackUrl =
    { id = id
    , loading = True
    , nextLink = Just fetchUrl
    , addTrackUrl = addTrackUrl
    }


type Page
    = FeedPage
    | SavedTracksPage
    | PublishedTracksPage
    | PublishNewTrackPage
    | PageNotFound


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
        |> Maybe.andThen ((flip Tracklist.get) model.tracks)
