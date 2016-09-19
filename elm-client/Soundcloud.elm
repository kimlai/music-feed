module Soundcloud exposing (..)


import Api exposing (decodeTrack)
import Http
import Model exposing (Track)
import Task exposing (Task)


resolve : String -> String -> Task Http.Error Track
resolve clientId url =
    Http.get
        decodeTrack
        ("https://api.soundcloud.com/resolve?url=" ++ url ++ "&client_id=" ++ clientId)
