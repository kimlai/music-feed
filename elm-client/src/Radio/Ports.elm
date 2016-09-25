port module Radio.Ports exposing (..)


import Model exposing (TrackId)
import Youtube exposing (YoutubeId)



-- TO JS


port scroll : Int -> Cmd msg
