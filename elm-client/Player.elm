module Player exposing (..)


import Playlist exposing (Playlist)


type Player a b =
    Player
        { playlists : List (Playlist a b)
        , currentPlaylist : Maybe a
        , currentTrack : Maybe b
        }


initialize : List a -> Player a b
initialize playlistIds =
    Player
        { playlists = List.map Playlist.empty playlistIds
        , currentPlaylist = Nothing
        , currentTrack = Nothing
        }


appendTracksToPlaylist : a -> List b -> Player a b -> Player a b
appendTracksToPlaylist playlistId tracks (Player { playlists, currentPlaylist, currentTrack }) =
    let
        updatePlaylist playlist =
            if Playlist.id playlist == playlistId then
                Playlist.append tracks playlist
            else
                playlist
    in
        Player
            { playlists = List.map updatePlaylist playlists
            , currentPlaylist = currentPlaylist
            , currentTrack = currentTrack
            }


select : a -> Int -> Player a b -> Player a b
select playlistId position (Player { playlists, currentPlaylist, currentTrack }) =
    let
        updatePlaylist playlist =
            if Playlist.id playlist == playlistId then
                Playlist.select position playlist
            else
                playlist
        playlists' =
            List.map updatePlaylist playlists
        newCurrentPlaylist =
            playlists'
                |> List.filter ((==) playlistId << Playlist.id)
                |> List.head
        currentTrack' =
            newCurrentPlaylist `Maybe.andThen` Playlist.currentItem
    in
        Player
            { playlists = playlists'
            , currentPlaylist = Just playlistId
            , currentTrack = currentTrack'
            }


next : Player a b -> Player a b
next (Player { playlists, currentPlaylist, currentTrack}) =
    let
        updatePlaylist playlist =
            if Just (Playlist.id playlist) == currentPlaylist
                && (Playlist.currentItem playlist) == currentTrack then
                Playlist.next playlist
            else
                playlist
        playlists' =
            List.map updatePlaylist playlists
        items =
            playlists'
                |> List.filter ((==) currentPlaylist << Just << Playlist.id)
                |> List.head
        currentTrack' =
            items `Maybe.andThen` Playlist.currentItem
    in
        Player
            { playlists = playlists'
            , currentPlaylist = currentPlaylist
            , currentTrack = currentTrack'
            }

moveTrack : a -> b -> Player a b -> Player a b
moveTrack playlistId track (Player { playlists, currentPlaylist, currentTrack }) =
    let
        updatePlaylist playlist =
            if Playlist.id playlist == playlistId then
                Playlist.prepend track playlist
            else
                Playlist.remove track playlist
        playlists' =
            List.map updatePlaylist playlists
    in
        Player
            { playlists = playlists'
            , currentPlaylist = currentPlaylist
            , currentTrack = currentTrack
            }


currentPlaylist : Player a b -> Maybe a
currentPlaylist (Player { currentPlaylist }) =
    currentPlaylist


currentTrack : Player a b -> Maybe b
currentTrack (Player { currentTrack }) =
    currentTrack


playlistContent : a -> Player a b -> List b
playlistContent playlistId (Player { playlists }) =
    playlists
        |> List.filter ((==) playlistId << Playlist.id)
        |> List.head
        |> Maybe.withDefault (Playlist.empty playlistId)
        |> Playlist.items
