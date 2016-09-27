port module PlayerEngine exposing
    ( play, pause, changeCurrentTime, seekToPercentage
    , trackProgress, trackEnd, trackError
    )


import Model exposing (Track, TrackId, StreamingInfo(..))
import Youtube exposing (YoutubeId)



-- TO JS


port playSoundcloudTrack : { id : TrackId, streamUrl : String, currentTime : Float } -> Cmd msg
port playYoutubeTrack : { id : TrackId, youtubeId : YoutubeId, currentTime : Float } -> Cmd msg
port pause : Maybe TrackId -> Cmd msg
port changeSoundcloudCurrentTime : Int -> Cmd msg
port changeYoutubeCurrentTime : Int -> Cmd msg
port seekSoundcloudToPercentage : Float -> Cmd msg
port seekYoutubeToPercentage : Float -> Cmd msg



-- FROM JS


port trackProgress : (( TrackId, Float, Float ) -> msg) -> Sub msg
port trackEnd : (TrackId -> msg) -> Sub msg
port trackError : (TrackId -> msg) -> Sub msg


play : Track -> Cmd msg
play track =
    case track.streamingInfo of
        Soundcloud streamUrl ->
            playSoundcloudTrack
                { id = track.id
                , streamUrl = streamUrl
                , currentTime = track.currentTime
                }
        Youtube youtubeId ->
            playYoutubeTrack
                { id = track.id
                , youtubeId = youtubeId
                , currentTime = track.currentTime
                }


changeCurrentTime : Maybe Track -> Int -> Cmd msg
changeCurrentTime currentTrack amount =
    case currentTrack of
        Nothing ->
            Cmd.none
        Just track ->
            case track.streamingInfo of
                Soundcloud streamUrl ->
                    changeSoundcloudCurrentTime amount
                Youtube youtubeId ->
                    changeYoutubeCurrentTime amount


seekToPercentage : Maybe Track -> Float -> Cmd msg
seekToPercentage currentTrack positionInPercentage =
    case currentTrack of
        Nothing ->
            Cmd.none
        Just track ->
            case track.streamingInfo of
                Soundcloud streamUrl ->
                    seekSoundcloudToPercentage positionInPercentage
                Youtube youtubeId ->
                    seekYoutubeToPercentage positionInPercentage
