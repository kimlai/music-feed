module Html.Extra exposing (link)


import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode


link : (String -> msg ) -> String -> List (Attribute msg) -> List (Html msg) -> Html msg
link followLink target attributes children =
    a
        (List.append
            attributes
            [ href target
            , onWithOptions
                "click"
                { stopPropagation = False
                , preventDefault = True
                }
                (Json.Decode.succeed (followLink target))
            ]
        )
        children
