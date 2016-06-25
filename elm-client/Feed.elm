module Feed exposing (..)


type alias Track =
    { id : TrackId
    , artist : String
    , artwork_url : String
    , title : String
    , streamUrl : String
    , progress : Float
    , currentTime : Float
    }


type alias TrackId = Int
