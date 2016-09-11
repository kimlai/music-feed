module Model exposing (..)


import Date exposing (Date)
import Dict exposing (Dict)
import PlaylistStructure
import Time exposing (Time)


type alias Model =
    { tracks : Dict TrackId Track
    , playlists : List Playlist
    , queue : List TrackId
    , customQueue : List TrackId
    , playing : Bool
    , currentPlaylistId : Maybe PlaylistId
    , currentTrackId : Maybe TrackId
    , currentPage : Page
    , lastKeyPressed : Maybe Char
    , currentTime : Maybe Time
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
    , items : PlaylistStructure.Playlist TrackId
    }


emptyPlaylist : PlaylistId -> String -> String -> Playlist
emptyPlaylist id fetchUrl addTrackUrl =
    { id = id
    , loading = True
    , nextLink = fetchUrl
    , addTrackUrl = addTrackUrl
    , items = PlaylistStructure.empty
    }


type PlaylistId
    = Feed
    | SavedTracks
    | PublishedTracks
    | Blacklist


currentPlaylist : Model -> Maybe Playlist
currentPlaylist model =
    List.filter ((==) model.currentPlaylistId << Just << .id) model.playlists
        |> List.head


currentTrack : Model -> Maybe Track
currentTrack model =
    model.currentTrackId
        `Maybe.andThen` (flip Dict.get) model.tracks
