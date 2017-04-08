module Model exposing (..)


type alias NavigationItem page playlist =
    { displayName : String
    , href : String
    , page : page
    , playlist : Maybe playlist
    }
