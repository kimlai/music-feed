module Playlist exposing
    ( Playlist
    , empty
    , append, prepend, remove
    , currentItem, next, select, items, id
    )

import Array exposing (Array)

type Playlist a b =
    Playlist
        { id: a
        , items : Array b
        , position : Int
        }


empty : a -> Playlist a b
empty id =
    Playlist
        { id = id
        , items = Array.empty
        , position = 0
        }


append : List b -> Playlist a b -> Playlist a b
append newItems (Playlist { id, items, position }) =
    Playlist
        { id = id
        , items = Array.append items (Array.fromList newItems)
        , position = position
        }


prepend : b -> Playlist a b -> Playlist a b
prepend item (Playlist { id, items, position }) =
    Playlist
        { id = id
        , items = Array.append (Array.fromList [item]) items
        , position = position + 1
        }


remove : b -> Playlist a b -> Playlist a b
remove item playlist =
    let
        (Playlist { id, items, position }) =
            playlist
        current = currentItem playlist
        matchCountBeforePosition =
            Array.slice 0 position items
                |> Array.filter ((==) item)
                |> Array.length
    in
        Playlist
            { id = id
            , items = Array.filter ((/=) item) items
            , position = position - matchCountBeforePosition
            }


next : Playlist a b -> Playlist a b
next (Playlist { id, items, position }) =
    Playlist
        { id = id
        , items = items
        , position = position + 1
        }


currentItem : Playlist a b -> Maybe b
currentItem (Playlist { items, position }) =
    Array.get position items


select : Int -> Playlist a b -> Playlist a b
select newPosition (Playlist { id, items, position }) =
    Playlist
        { id = id
        , items = items
        , position = newPosition
        }


items : Playlist a b -> List b
items (Playlist { items }) =
    Array.toList items


id : Playlist a b -> a
id (Playlist { id }) =
    id
