module Icons exposing (..)


import Svg exposing (..)
import Svg.Attributes exposing (id, fill, viewBox, d)
import Html.Attributes exposing (attribute)


play : Svg msg
play =
    svg [ attribute "height" "20px", attribute "version" "1.1", viewBox "0 0 17 20", attribute "width" "17px", attribute "xmlns" "http://www.w3.org/2000/svg" ]
        [ node "title" []
            [ text "Play" ]
        , g [ fill "none", attribute "fill-rule" "evenodd", id "Page-1", attribute "stroke" "none", attribute "stroke-width" "1" ]
            [ g [ fill "#333333", id "Player", attribute "transform" "translate(-2758.000000, -394.000000)" ]
                [ path [ d "M2758,394 L2758,414 L2775,404 L2758,394 Z", id "Play" ]
                    []
                ]
            ]
        ]


pause : Svg msg
pause =
    svg [ attribute "height" "20px", attribute "version" "1.1", viewBox "0 0 14 20", attribute "width" "14px", attribute "xmlns" "http://www.w3.org/2000/svg" ]
        [ node "title" []
            [ text "Pause" ]
        , g [ fill "none", attribute "fill-rule" "evenodd", id "Page-1", attribute "stroke" "none", attribute "stroke-width" "1" ]
            [ g [ fill "#333333", id "Player", attribute "transform" "translate(-2710.000000, -394.000000)" ]
                [ g [ id "Pause", attribute "transform" "translate(2710.000000, 394.000000)" ]
                    [ g [ id "Rectangle-131-+-Rectangle-131" ]
                        [ node "rect" [ attribute "height" "20", id "Rectangle-131", attribute "width" "5", attribute "x" "0", attribute "y" "0" ]
                            []
                        , node "rect" [ attribute "height" "20", id "Rectangle-131", attribute "width" "5", attribute "x" "9", attribute "y" "0" ]
                            []
                        ]
                    ]
                ]
            ]
        ]


error : Svg msg
error =
    svg [ attribute "height" "20px", id "svg3017", viewBox "0 0 17 20", attribute "width" "17px", attribute "xmlns" "http://www.w3.org/2000/svg" ]
        [ node "sodipodi:namedview"
            [ attribute "bordercolor" "#666666", attribute "borderopacity" "1" ]
            []
        , node "title" [ id "title3019" ]
            [ text "Play" ]
        , path [ d "M 1.5198618,2.970639 15.440414,16.580311", id "path3032", attribute "inkscape:connector-curvature" "0", attribute "sodipodi:nodetypes" "cc", attribute "style" "fill:none;stroke:#000000;stroke-width:3.5;stroke-linecap:butt;stroke-linejoin:miter;stroke-miterlimit:4;stroke-opacity:1;stroke-dasharray:none" ]
            []
        , text ""
        , path [ d "M 15.405872,3.0051813 1.4853195,16.580311", id "path3034", attribute "inkscape:connector-curvature" "0", attribute "sodipodi:nodetypes" "cc", attribute "style" "fill:none;stroke:#000000;stroke-width:3.5;stroke-linecap:butt;stroke-linejoin:miter;stroke-miterlimit:4;stroke-opacity:1;stroke-dasharray:none" ]
            []
        , text ""
        ]


next : Svg msg
next =
    svg [ attribute "height" "14px", attribute "version" "1.1", viewBox "0 0 12 14", attribute "width" "12px", attribute "xmlns" "http://www.w3.org/2000/svg" ]
        [ node "title" []
            [ text "Skip" ]
        , g [ fill "none", attribute "fill-rule" "evenodd", id "Page-1", attribute "stroke" "none", attribute "stroke-width" "1" ]
            [ g [ fill "#333333", id "Player", attribute "transform" "translate(-2620.000000, -397.000000)" ]
                [ path [ d "M2630,403 L2620,397 L2620,411 L2630,405 L2630,411 L2632,411 L2632,397 L2630,397 L2630,403 Z", id "Skip" ]
                    []
                ]
            ]
        ]


heart: Svg msg
heart =
    svg [ attribute "data-id" "geomicon-heart"
        , fill "currentColor"
        , attribute "height" "16"
        , viewBox "0 0 32 32"
        , attribute "width" "16"
        , attribute "xmlns" "http://www.w3.org/2000/svg"
        ]
        [ path
            [ d "M0 10 C0 6, 3 2, 8 2 C12 2, 15 5, 16 6 C17 5, 20 2, 24 2 C30 2, 32 6, 32 10 C32 18, 18 29, 16 30 C14 29, 0 18, 0 10"
            ]
            []
        ]
