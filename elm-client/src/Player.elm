module Player exposing (..)


import Playlist exposing (Playlist)


type Player a b =
    Player
        { playlists : List (a, Playlist b)
        , currentPlaylist : Maybe a
        , currentTrack : Maybe b
        }


initialize : List a -> Player a b
initialize playlistIds =
    Player
        { playlists = List.map (\id -> ( id, Playlist.empty )) playlistIds
        , currentPlaylist = Nothing
        , currentTrack = Nothing
        }


appendTracksToPlaylist : a -> List b -> Player a b -> Player a b
appendTracksToPlaylist playlistId tracks (Player { playlists, currentPlaylist, currentTrack }) =
    let
        updatePlaylist ( id, playlist ) =
            if id == playlistId then
                ( id, Playlist.append tracks playlist )
            else
                ( id, playlist )
    in
        Player
            { playlists = List.map updatePlaylist playlists
            , currentPlaylist = currentPlaylist
            , currentTrack = currentTrack
            }


select : a -> Int -> Player a b -> Player a b
select playlistId position (Player { playlists, currentPlaylist, currentTrack }) =
    let
        updatePlaylist ( id, playlist ) =
            if id == playlistId then
                ( id, Playlist.select position playlist )
            else
                ( id, playlist )
        updatedPlaylists =
            List.map updatePlaylist playlists
        selectedTrack =
            updatedPlaylists
                |> List.filter ((==) playlistId << Tuple.first)
                |> List.head
                |> Maybe.map Tuple.second
                |> Maybe.andThen Playlist.currentItem
    in
        Player
            { playlists = updatedPlaylists
            , currentPlaylist = Just playlistId
            , currentTrack = selectedTrack
            }


selectPlaylist : a -> Player a b -> Player a b
selectPlaylist playlistId (Player { playlists, currentPlaylist, currentTrack }) =
    let
        newCurrentTrack =
            playlists
                |> List.filter ((==) playlistId << Tuple.first)
                |> List.head
                |> Maybe.map Tuple.second
                |> Maybe.andThen Playlist.currentItem
    in
        Player
            { playlists = playlists
            , currentPlaylist = Just playlistId
            , currentTrack = newCurrentTrack
            }


next : Player a b -> Player a b
next (Player { playlists, currentPlaylist, currentTrack}) =
    let
        updatePlaylist (id, playlist ) =
            if Just id == currentPlaylist
                && (Playlist.currentItem playlist) == currentTrack then
                ( id, Playlist.next playlist )
            else
                ( id, playlist )
        updatedPlaylists =
            List.map updatePlaylist playlists
        newCurrentTrack =
            updatedPlaylists
                |> List.filter ((==) currentPlaylist << Just << Tuple.first)
                |> List.head
                |> Maybe.map Tuple.second
                |> Maybe.andThen Playlist.currentItem
    in
        Player
            { playlists = updatedPlaylists
            , currentPlaylist = currentPlaylist
            , currentTrack = newCurrentTrack
            }

moveTrack : a -> b -> Player a b -> Player a b
moveTrack playlistId track (Player { playlists, currentPlaylist, currentTrack }) =
    let
        updatePlaylist (id, playlist ) =
            if id == playlistId then
                ( id, Playlist.prepend track playlist )
            else
                ( id, Playlist.remove track playlist )
        updatedPlaylists =
            List.map updatePlaylist playlists
    in
        Player
            { playlists = updatedPlaylists
            , currentPlaylist = currentPlaylist
            , currentTrack = currentTrack
            }


currentPlaylist : Player a b -> Maybe a
currentPlaylist (Player { currentPlaylist }) =
    currentPlaylist


currentTrack : Player a b -> Maybe b
currentTrack (Player { currentTrack }) =
    currentTrack


currentTrackOfPlaylist : a -> Player a b -> Maybe b
currentTrackOfPlaylist playlistId (Player { playlists }) =
    playlists
        |> List.filter ((==) playlistId << Tuple.first)
        |> List.head
        |> Maybe.withDefault ( playlistId, Playlist.empty )
        |> Tuple.second
        |> Playlist.currentItem


playlistContent : a -> Player a b -> List b
playlistContent playlistId (Player { playlists }) =
    playlists
        |> List.filter ((==) playlistId << Tuple.first)
        |> List.head
        |> Maybe.withDefault ( playlistId, Playlist.empty )
        |> Tuple.second
        |> Playlist.items
