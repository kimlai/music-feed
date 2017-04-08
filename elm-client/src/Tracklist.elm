module Tracklist exposing (..)


import Dict exposing (Dict)
import Track exposing (Track, TrackId)


type Tracklist =
    Tracklist (Dict TrackId Track)


empty : Tracklist
empty =
    Tracklist Dict.empty


add : List Track -> Tracklist -> Tracklist
add newTracks (Tracklist tracklist) =
    newTracks
        |> List.map (\track -> ( track.id, track ))
        |> Dict.fromList
        |> Dict.union tracklist
        |> Tracklist


update : TrackId -> (Track -> Track) -> Tracklist -> Tracklist
update trackId fn (Tracklist tracklist) =
    tracklist
        |> Dict.update trackId (Maybe.map fn)
        |> Tracklist


get : TrackId -> Tracklist -> Maybe Track
get trackId (Tracklist tracklist) =
    Dict.get trackId tracklist


getTracks : List TrackId -> Tracklist -> List Track
getTracks ids (Tracklist tracklist) =
    List.filterMap (\trackId -> Dict.get trackId tracklist) ids
