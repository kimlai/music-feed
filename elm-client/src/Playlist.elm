module Playlist exposing
    ( Playlist
    , empty
    , append, prepend, remove
    , currentItem, next, select, items
    )

import Array exposing (Array)

type Playlist a =
    Playlist
        { items : Array a
        , position : Int
        }


empty : Playlist a
empty =
    Playlist
        { items = Array.empty
        , position = 0
        }


append : List a -> Playlist a -> Playlist a
append newItems (Playlist { items, position }) =
    Playlist
        { items = Array.append items (Array.fromList newItems)
        , position = position
        }


prepend : a -> Playlist a -> Playlist a
prepend item (Playlist { items, position }) =
    Playlist
        { items = Array.append (Array.fromList [item]) items
        , position = position + 1
        }


remove : a -> Playlist a -> Playlist a
remove item playlist =
    let
        (Playlist { items, position }) =
            playlist
        current = currentItem playlist
        matchCountBeforePosition =
            Array.slice 0 position items
                |> Array.filter ((==) item)
                |> Array.length
    in
        Playlist
            { items = Array.filter ((/=) item) items
            , position = position - matchCountBeforePosition
            }


next : Playlist a -> Playlist a
next (Playlist { items, position }) =
    Playlist
        { items = items
        , position = position + 1
        }


currentItem : Playlist a -> Maybe a
currentItem (Playlist { items, position }) =
    Array.get position items


select : Int -> Playlist a -> Playlist a
select newPosition (Playlist { items, position }) =
    Playlist
        { items = items
        , position = newPosition
        }


items : Playlist a -> List a
items (Playlist { items }) =
    Array.toList items
