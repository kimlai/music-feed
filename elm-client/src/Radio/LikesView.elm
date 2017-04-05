module Radio.LikesView exposing (view)


import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Radio.Update exposing (Msg(..))


view : Html Msg
view =
    div []
        [ text "Likes" ]
