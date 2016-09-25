module Model exposing (..)


import Date exposing (Date)
import Youtube exposing (YoutubeId)


type alias TrackId = String


type alias Track =
    { id : TrackId
    , artist : String
    , artwork_url : String
    , title : String
    , streamingInfo: StreamingInfo
    , sourceUrl : String
    , createdAt : Date
    , progress : Float
    , currentTime : Float
    , error : Bool
    }


type StreamingInfo
    = Soundcloud StreamUrl
    | Youtube YoutubeId


type alias StreamUrl = String


type alias NavigationItem =
    { displayName : String
    , href : String
    }

type alias Page a =
    { url : String
    , playlist : Maybe a
    }
