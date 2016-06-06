import Html exposing (Html, a, nav, li, ul, text, div, img)
import Html.App as Html
import Html.Attributes exposing (class, href, src)
import Html.Events exposing (onClick)
import Http
import Json.Decode as Json
import Json.Decode exposing ((:=))
import Json.Decode.Extra exposing ((|:))
import Task


main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = \_ -> Sub.none
        }



-- MODEL


type alias Model =
    { tracks : List Track
    , nextLink : Maybe String
    , loading : Bool
    }


type alias Track =
    { id : Int
    , artist : String
    , artwork_url : Maybe String
    , title : String
    }


type alias FetchFeedPayload =
    { tracks : List Track
    , nextLink : String
    }


init : ( Model, Cmd Msg )
init =
    ( { tracks = []
        , loading = True
        , nextLink = Nothing
      }
    , fetchFeed Nothing
    )



-- UPDATE


type Msg
    = FetchFeedSuccess FetchFeedPayload
    | FetchFeedFail Http.Error
    | FetchMore


update : Msg -> Model -> ( Model, Cmd Msg )
update message model =
    case message of
        FetchFeedSuccess payload ->
            ( { model
                | tracks = List.append model.tracks payload.tracks
                , nextLink = Just payload.nextLink
                , loading = False
              }
            , Cmd.none
            )
        FetchFeedFail error ->
            let _ = Debug.log "error" error in
            ( { model
                | loading = False
              }
            , Cmd.none
            )
        FetchMore ->
            ( { model
                | loading = True
              }
            , fetchFeed model.nextLink
            )


view : Model -> Html Msg
view model =
    div
        []
        [ viewNavigation navigation
        , div
            [ class "playlist-container" ]
            [ viewFeed model ]
        ]


viewFeed : Model -> Html Msg
viewFeed model =
    let
        tracksView =
            List.map viewTrack model.tracks
    in
        if model.loading == True then
            List.repeat 10 viewTrackPlaceHolder
                |> List.append tracksView
                |> div []
        else
            [ viewMoreButton ]
                |> List.append tracksView
                |> div []


viewTrack : Track -> Html Msg
viewTrack track =
    div
        [ class "track" ]
        [ div
            [ class "track-info-container" ]
            [ img
                [ src ( Maybe.withDefault "/images/placeholder.jpg" track.artwork_url ) ]
                []
            , div
                [ class "track-info" ]
                [ div [] [ text track.artist ]
                , div [] [ text track.title ]
                ]
            ]
        , div
            [ class "progress-bar" ]
            [ div [ class "outer" ] [] ]
        ]


viewTrackPlaceHolder : Html Msg
viewTrackPlaceHolder =
    div
        [ class "track" ]
        [ div
            [ class "track-info-container" ]
            [ img [ src "/images/placeholder.jpg" ] [] ]
        , div
            [ class "progress-bar" ]
            [ div [ class "outer" ] [] ]
        ]


viewMoreButton : Html Msg
viewMoreButton =
    div
        [ class "more-button"
        , onClick FetchMore
        ]
        [ text "More" ]


type alias Navigation =
    { items : List NavigationItem
    , activeItem : NavigationItem
    }


type alias NavigationItem =
    { displayName : String
    , href : String
    }


navigation : Navigation
navigation =
    Navigation
        [ NavigationItem "feed" "/"
        , NavigationItem "saved tracks" "/saved-tracks"
        , NavigationItem "published tracks" "/pubished-tracks"
        ]
        ( NavigationItem "feed" "/" )



viewNavigation : Navigation -> Html Msg
viewNavigation navigation =
    navigation.items
        |> List.map ( viewNavigationItem navigation.activeItem )
        |> ul []
        |> List.repeat 1
        |> nav [ class "navigation" ]


viewNavigationItem : NavigationItem -> NavigationItem -> Html Msg
viewNavigationItem activeNavigationItem navigationItem =
    let
        linkAttributes =
            if navigationItem == activeNavigationItem then
                [ class "active" ]
            else
                []
    in
        li
            []
            [ a
                ( List.append linkAttributes [ href navigationItem.href ] )
                [ text navigationItem.displayName ]
            ]



-- HTTP


fetchFeed : Maybe String -> Cmd Msg
fetchFeed nextLink =
    Http.get decodeFeed ( Maybe.withDefault "/feed" nextLink )
        |> Task.perform FetchFeedFail FetchFeedSuccess


decodeFeed : Json.Decoder FetchFeedPayload
decodeFeed =
    Json.Decode.succeed FetchFeedPayload
        |: ( "tracks" := Json.Decode.list decodeTrack )
        |: ( "next_href" := Json.Decode.string )


decodeTrack : Json.Decode.Decoder Track
decodeTrack =
    Json.Decode.succeed Track
        |: ("id" := Json.Decode.int)
        |: (Json.Decode.at [ "user", "username" ] Json.Decode.string)
        |: ("artwork_url" := Json.Decode.Extra.maybeNull Json.Decode.string)
        |: ("title" := Json.Decode.string)

