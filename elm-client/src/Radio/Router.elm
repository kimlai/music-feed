module Radio.Router exposing (..)


import Radio.Model exposing(Page(..))


urlToPage : String -> Page
urlToPage url =
    routes
        |> List.filter ((==) url << Tuple.first)
        |> List.head
        |> Maybe.map Tuple.second
        |> Maybe.withDefault PageNotFound


pageToUrl : Page -> String
pageToUrl page =
    routes
        |> List.filter ((==) page << Tuple.second)
        |> List.head
        |> Maybe.map Tuple.first
        |> Maybe.withDefault "/404"


routes : List ( String, Page )
routes =
    [ ( "/",  RadioPage )
    , ( "/queue/played", PlayedPage )
    , ( "/queue/next", UpNextPage )
    , ( "/latest",  LatestTracksPage )
    , ( "/likes",  LikesPage )
    , ( "/sign-up",  Signup )
    , ( "/login", Login )
    ]
