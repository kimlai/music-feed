port module Feed.Ports exposing (..)


import Model exposing (TrackId, YoutubeId)



-- TO JS


port playSoundcloudTrack : { id : TrackId, streamUrl : String, currentTime : Float } -> Cmd msg
port playYoutubeTrack : { id : TrackId, youtubeId : YoutubeId, currentTime : Float } -> Cmd msg
port pause : Maybe TrackId -> Cmd msg
port changeCurrentTime : Int -> Cmd msg
port scroll : Int -> Cmd msg
port uploadImage : Maybe Int -> Cmd msg



-- FROM JS


port trackProgress : (( TrackId, Float, Float ) -> msg) -> Sub msg
port trackEnd : (TrackId -> msg) -> Sub msg
port trackError : (TrackId -> msg) -> Sub msg
port imageUploaded : (String -> msg) -> Sub msg
