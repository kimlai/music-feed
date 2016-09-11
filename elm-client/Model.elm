module Model exposing (..)


import Date exposing (Date)
import Dict exposing (Dict)
import Player exposing (Player)
import Time exposing (Time)


type alias Model =
    { tracks : Dict TrackId Track
    , playlists : List Playlist
    , queue : List TrackId
    , customQueue : List TrackId
    , playing : Bool
    , currentPage : Page
    , lastKeyPressed : Maybe Char
    , currentTime : Maybe Time
    , player : Player PlaylistId TrackId
    }


type alias NavigationItem =
    { displayName : String
    , href : String
    }


navigation : List NavigationItem
navigation =
    [ NavigationItem "Feed" "/"
    , NavigationItem "saved tracks" "/saved-tracks"
    , NavigationItem "published tracks" "/published-tracks"
    , NavigationItem "+" "/publish-track"
    ]

type alias Page =
    { url : String
    , playlist : Maybe PlaylistId
    }


pages : List Page
pages =
    [ Page "/feed" (Just Feed)
    , Page "/saved-tracks" (Just SavedTracks)
    , Page "/published-tracks" (Just PublishedTracks)
    , Page "/publish-track" Nothing
    ]


type alias Track =
    { id : TrackId
    , artist : String
    , artwork_url : String
    , title : String
    , streamUrl : String
    , sourceUrl : String
    , createdAt : Date
    , progress : Float
    , currentTime : Float
    , error : Bool
    }


type alias TrackId =
    Int


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


currentPlaylist : Model -> Maybe Playlist
currentPlaylist model =
    List.filter ((==) (Player.currentPlaylist model.player) << Just << .id) model.playlists
        |> List.head


currentTrack : Model -> Maybe Track
currentTrack model =
    Player.currentTrack model.player
        `Maybe.andThen` (flip Dict.get) model.tracks
