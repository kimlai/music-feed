module Youtube exposing (..)


import Regex


type alias YoutubeId = String


extractYoutubeIdFromUrl : String -> Maybe String
extractYoutubeIdFromUrl url =
    url
        |> Regex.find (Regex.AtMost 1) (Regex.regex "https:\\/\\/www\\.youtube\\.com\\/watch\\?v=(.+)")
        |> List.map .submatches
        |> List.concat
        |> List.filterMap identity
        |> List.head
