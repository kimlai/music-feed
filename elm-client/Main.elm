port module Main exposing(..)

import Dict exposing (Dict)
import Html exposing (Html, a, nav, li, ul, text, div, img)
import Html.App as Html
import Html.Attributes exposing (class, href, src, style)
import Html.Events exposing (onClick, onWithOptions)
import Http
import FeedApi
import Feed exposing (Track, TrackId)
import Task
import Keyboard
import Char
import Json.Decode
import Navigation


main =
    Navigation.program urlParser
        { init = init
        , view = view
        , update = update
        , urlUpdate = urlUpdate
        , subscriptions = subscriptions
        }



-- URL PARSERS


urlParser : Navigation.Parser Page
urlParser =
    Navigation.makeParser
        (\location ->
            case location.pathname of
                "/feed" ->
                    Feed
                "/saved-tracks" ->
                    SavedTracks
                "/published-tracks" ->
                    PublishedTracks
                _ ->
                    Feed
        )


urlUpdate : Page -> Model -> ( Model, Cmd Msg )
urlUpdate page model =
    ( { model | currentPage = page }
    , Cmd.none
    )



-- MODEL


type alias Model =
    { tracks : Dict TrackId Track
    , feed : List TrackId
    , queue : List TrackId
    , nextLink : Maybe String
    , loading : Bool
    , playing : Bool
    , currentTrack : Maybe TrackId
    , currentPage : Page
    , lastKeyPressed : Maybe Char
    }


type Page
    = Feed
    | SavedTracks
    | PublishedTracks


init : Page -> ( Model, Cmd Msg )
init page =
    ( { tracks = Dict.empty
      , feed = []
      , queue = []
      , loading = True
      , playing = False
      , nextLink = Nothing
      , currentTrack = Nothing
      , currentPage = page
      , lastKeyPressed = Nothing
      }
    , fetchFeed Nothing
    )



-- UPDATE


type Msg
    = FetchFeedSuccess ( List Track, String )
    | FetchFeedFail Http.Error
    | FetchMore
    | TogglePlaybackFromFeed Int Track
    | TogglePlayback
    | Next
    | TrackProgress ( TrackId, Float, Float )
    | FastForward
    | Rewind
    | Blacklist TrackId
    | BlacklistFail Http.Error
    | BlacklistSuccess
    | ChangePage String
    | KeyPressed Keyboard.KeyCode


port playTrack : Track -> Cmd msg
port resume : Maybe TrackId -> Cmd msg
port pause : Maybe TrackId -> Cmd msg
port changeCurrentTime : Int -> Cmd msg
port scroll : Int -> Cmd msg


update : Msg -> Model -> ( Model, Cmd Msg )
update message model =
    case message of
        FetchFeedSuccess ( tracks, nextLink ) ->
            let
                updatedTrackDict =
                    tracks
                        |> List.map (\track -> ( track.id, track ))
                        |> Dict.fromList
                        |> Dict.union model.tracks
            in
            ( { model
                | tracks = updatedTrackDict
                , feed = List.append model.feed ( List.map .id tracks )
                , queue = List.append model.queue ( List.map .id tracks )
                , nextLink = Just nextLink
                , loading = False
              }
            , Cmd.none
            )
        FetchFeedFail error ->
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
        TogglePlaybackFromFeed position track ->
            if model.currentTrack == Just track.id then
                update TogglePlayback model
            else
                ( { model
                    | currentTrack = Just track.id
                    , playing = True
                    , queue = List.drop ( position + 1 ) model.feed
                  }
                  , playTrack track
                )
        TogglePlayback ->
            ( { model | playing = not model.playing }
            , if model.playing then
                pause model.currentTrack
              else
                resume model.currentTrack
            )
        Next ->
            let
                newCurrentTrack =
                    List.head model.queue
            in
                ( { model
                    | currentTrack = newCurrentTrack
                    , queue = List.drop 1 model.queue
                  }
                , case newCurrentTrack of
                    Nothing ->
                        pause model.currentTrack
                    Just trackId ->
                        case Dict.get trackId model.tracks of
                            Nothing ->
                                Cmd.none
                            Just track ->
                                playTrack track
                )
        FastForward ->
            ( model
            , changeCurrentTime 10
            )
        Rewind ->
            ( model
            , changeCurrentTime -10
            )
        TrackProgress ( trackId, progress, currentTime ) ->
            ( { model
                | tracks =
                    Dict.update
                        trackId
                        ( \maybeTrack ->
                            maybeTrack `Maybe.andThen`
                            ( \track -> Just { track | progress = progress, currentTime = currentTime } )
                        )
                        model.tracks
              }
            , Cmd.none
            )
        Blacklist trackId ->
            let ( newModel, commands ) =
                if model.currentTrack == Just trackId then
                    update Next model
                else
                    ( model
                    , Cmd.none
                    )
            in
                ( { newModel
                    | feed = List.filter ((/=) trackId) newModel.feed
                    , queue = List.filter ((/=) trackId) newModel.queue
                  }
                , Cmd.batch [ commands, blacklist trackId ]
                )
        BlacklistFail error ->
            ( model
            , Cmd.none
            )
        BlacklistSuccess ->
            ( model
            , Cmd.none
            )
        ChangePage url ->
            ( model
            , Navigation.newUrl url
            )
        KeyPressed keyCode ->
            case ( Char.fromCode keyCode ) of
                'n' ->
                    update Next model
                'p' ->
                    update TogglePlayback model
                'l' ->
                    update FastForward model
                'h' ->
                    update Rewind model
                'm' ->
                    update FetchMore model
                'b' ->
                    case model.currentTrack of
                        Nothing ->
                            ( model
                            , Cmd.none
                            )
                        Just trackId ->
                            update ( Blacklist trackId ) model
                'j' ->
                    ( model
                    , scroll 120
                    )
                'k' ->
                    ( model
                    , scroll -120
                    )
                'g' ->
                    if model.lastKeyPressed == Just 'g' then
                        ( { model | lastKeyPressed = Nothing }
                        , scroll -9999999
                        )
                    else
                        ( { model | lastKeyPressed = Just 'g' }
                        , Cmd.none
                        )
                'G' ->
                    ( model
                    , scroll 99999999
                    )
                _ ->
                    ( model
                    , Cmd.none
                    )



-- SUBSCRIPTIONS


port trackProgress : ( ( TrackId, Float, Float ) -> msg ) -> Sub msg
port trackEnd : ( TrackId -> msg ) -> Sub msg


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ trackProgress TrackProgress
        , trackEnd ( \_ -> Next )
        , Keyboard.presses KeyPressed
        ]


-- VIEW


view : Model -> Html Msg
view model =
    let
        currentTrack =
            model.currentTrack
                `Maybe.andThen`
                ( \trackId -> Dict.get trackId model.tracks )
    in
        div
            []
            [ viewGlobalPlayer currentTrack model.playing
            , viewNavigation navigation model.currentPage
            , div
                [ class "playlist-container" ]
                [ case model.currentPage of
                    Feed ->
                        viewFeed model
                    SavedTracks ->
                        text "saved tracks"
                    PublishedTracks ->
                        text "published tracks"
                ]
            ]


viewGlobalPlayer : Maybe Track -> Bool -> Html Msg
viewGlobalPlayer track playing =
    case track of
        Nothing ->
            div
                [ class "global-player" ]
                [ div
                    [ class "controls" ]
                    [ div
                        [ class "playback-button" ]
                        [ text "Play" ]
                    , div
                        [ class "next-button" ]
                        [ text "Next" ]
                    ]
                , img [ src "images/placeholder.jpg" ] []
                , div
                    [ class "track-info" ]
                    []
                , div
                    [ class "progress-bar" ]
                    [ div [ class "outer" ] []
                    ]
                , div
                    [ class "actions" ]
                    []
                ]
        Just track ->
            div
                [ class "global-player" ]
                [ div
                    [ class "controls" ]
                    [ div
                        [ class ( "playback-button" ++ ( if playing then " playing" else "" ) )
                        , onClick ( TogglePlayback )
                        ]
                        [ text "Play" ]
                    , div
                        [ class "next-button"
                        , onClick Next
                        ]
                        [ text "Next" ]
                    ]
                , img
                    [ src track.artwork_url ]
                    []
                , div
                    [ class "track-info" ]
                    [ div [ class "artist" ] [ text track.artist ]
                    , div [ class "title" ] [ text track.title ]
                    ]
                , div
                    [ class "progress-bar" ]
                    [ div
                        [ class "outer" ]
                        [ div
                            [ class "inner"
                            , style [ ("width", ( toString track.progress ) ++ "%" ) ]
                            ]
                            []
                        ]
                    ]
                , div
                    [ class "actions" ]
                    []
                ]


viewFeed : Model -> Html Msg
viewFeed model =
    let
        feedTracks =
            List.filterMap ( \trackId -> Dict.get trackId model.tracks ) model.feed
        tracksView =
            List.indexedMap viewTrack feedTracks
    in
        if model.loading == True then
            List.repeat 10 viewTrackPlaceHolder
                |> List.append tracksView
                |> div []
        else
            [ viewMoreButton ]
                |> List.append tracksView
                |> div []


viewTrack : Int -> Track -> Html Msg
viewTrack position track =
    div
        [ class "track"
        , onClick ( TogglePlaybackFromFeed position track )
        ]
        [ div
            [ class "track-info-container" ]
            [ img
                [ src track.artwork_url ]
                []
            , div
                [ class "track-info" ]
                [ div [] [ text track.artist ]
                , div [] [ text track.title ]
                ]
            ]
        , div
            [ class "progress-bar" ]
            [ div
                [ class "outer" ]
                [ div
                    [ class "inner"
                    , style [ ("width", ( toString track.progress ) ++ "%" ) ]
                    ]
                    []
                ]
            ]
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


type alias NavigationItem =
    { displayName : String
    , href : String
    , page : Page
    }


navigation : List NavigationItem
navigation =
    [ NavigationItem "feed" "/" Feed
    , NavigationItem "saved tracks" "/saved-tracks" SavedTracks
    , NavigationItem "published tracks" "/published-tracks" PublishedTracks
    ]



viewNavigation : List NavigationItem -> Page -> Html Msg
viewNavigation navigationItems currentPage =
    navigationItems
        |> List.map ( viewNavigationItem currentPage )
        |> ul []
        |> List.repeat 1
        |> nav [ class "navigation" ]


viewNavigationItem : Page -> NavigationItem -> Html Msg
viewNavigationItem currentPage navigationItem =
    let
        linkAttributes =
            if navigationItem.page == currentPage then
                [ class "active" ]
            else
                []
    in
        li
            [ onWithOptions
                "click"
                { stopPropagation = False
                , preventDefault = True
                }
                ( Json.Decode.succeed ( ChangePage navigationItem.href ) )
            ]
            [ a
                ( List.append linkAttributes [ href navigationItem.href ] )
                [ text navigationItem.displayName ]
            ]



-- HTTP


fetchFeed : Maybe String -> Cmd Msg
fetchFeed nextLink =
    FeedApi.fetch nextLink
        |> Task.perform FetchFeedFail FetchFeedSuccess


blacklist : TrackId -> Cmd Msg
blacklist trackId =
    FeedApi.blacklist trackId
        |> Task.perform BlacklistFail ( \_ -> BlacklistSuccess )
