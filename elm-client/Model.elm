module Model exposing (..)


import Date exposing (Date)


type alias TrackId = Int


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


type alias NavigationItem =
    { displayName : String
    , href : String
    }

type alias Page a =
    { url : String
    , playlist : Maybe a
    }
