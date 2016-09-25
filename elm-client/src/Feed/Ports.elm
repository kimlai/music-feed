port module Feed.Ports exposing (..)


-- TO JS


port scroll : Int -> Cmd msg
port uploadImage : Maybe Int -> Cmd msg



-- FROM JS


port imageUploaded : (String -> msg) -> Sub msg
