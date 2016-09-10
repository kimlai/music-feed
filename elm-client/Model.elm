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
    , currentPlaylist : Maybe PlaylistId
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


currentTrack : Model -> Maybe Track
currentTrack model =
    currentTrackId model
        `Maybe.andThen` (flip Dict.get) model.tracks


currentTrackId : Model -> Maybe TrackId
currentTrackId model =
    let
        findPlaylist id =
            List.filter ((==) id << .id) model.playlists
                |> List.head
    in
        model.currentPlaylist
            `Maybe.andThen` findPlaylist
            `Maybe.andThen` (.items >> Just)
            `Maybe.andThen` PlaylistStructure.currentItem
