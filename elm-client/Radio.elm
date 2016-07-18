port module Radio exposing (..)

import Dict exposing (Dict)
import Regex
import Html exposing (Html, a, nav, li, ul, text, div, img)
import Html.App as Html
import Html.Attributes exposing (class, classList, href, src, style, target)
import Html.Events exposing (onClick, onWithOptions)
import Playlist exposing (Track, TrackId)
import PlaylistStructure
import Task
import Json.Decode
import Navigation
import Time exposing (Time)


main : Program String
main =
    Navigation.programWithFlags urlParser
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
                "/radio" ->
                    Radio

                "/latest" ->
                    LatestTracks

                _ ->
                    Radio
        )


urlUpdate : Page -> Model -> ( Model, Cmd Msg )
urlUpdate page model =
    ( { model | currentPage = page }
    , Cmd.none
    )



-- MODEL


type alias Model =
    { tracks : Dict TrackId Track
    , playlists : List Playlist
    , customQueue : List TrackId
    , playing : Bool
    , currentPlaylist : Maybe PlaylistId
    , currentPage : Page
    , lastKeyPressed : Maybe Char
    , currentTime : Maybe Time
    }


type alias Playlist =
    { id : PlaylistId
    , model : Playlist.Model
    }


type PlaylistId
    = Radio
    | LatestTracks


type alias Page =
    PlaylistId


init : String -> Page -> ( Model, Cmd Msg )
init radioPlaylistJsonString page =
    let
        playlists =
            [ Playlist Radio (Playlist.initialModel "/radio_playlist" "radio")
            , Playlist LatestTracks (Playlist.initialModel "/published_tracks" "publish_track")
            ]

        decodedRadioPayload =
            Json.Decode.decodeString Playlist.decodeFeed radioPlaylistJsonString
                |> Result.withDefault ( [], "/radio_playlist" )

        emptyModel =
            { tracks = Dict.empty
            , playlists = playlists
            , customQueue = []
            , playing = False
            , currentPlaylist = Nothing
            , currentPage = page
            , lastKeyPressed = Nothing
            , currentTime = Nothing
            }

        ( initializedModel, command ) =
            applyMessageToPlaylists (Playlist.FetchSuccess decodedRadioPayload) emptyModel [ Radio ]

        firstTrack =
            List.head (fst decodedRadioPayload)
    in
        ( { initializedModel
            | currentPlaylist = Just Radio
            , playing = firstTrack /= Nothing
          }
        , Cmd.batch
            [ case firstTrack of
                Nothing ->
                    Cmd.none

                Just track ->
                    playTrack
                        { id = track.id
                        , streamUrl = track.streamUrl
                        , currentTime = track.currentTime
                        }
            , Cmd.map (PlaylistMsg LatestTracks) (Playlist.initialCmd "/published_tracks")
            , Time.now |> Task.perform (\_ -> UpdateCurrentTimeFail) UpdateCurrentTime
            ]
        )



-- UPDATE


type Msg
    = PlaylistMsg PlaylistId Playlist.Msg
    | PlaylistEvent PlaylistId Playlist.Event
    | TogglePlayback
    | Next
    | TrackProgress ( TrackId, Float, Float )
    | TrackError TrackId
    | ChangePage String
    | UpdateCurrentTime Time
    | UpdateCurrentTimeFail
    | PlayFromCustomQueue Track


port playTrack : { id : Int, streamUrl : String, currentTime : Float } -> Cmd msg


port resume : Maybe TrackId -> Cmd msg


port pause : Maybe TrackId -> Cmd msg


port changeCurrentTime : Int -> Cmd msg


update : Msg -> Model -> ( Model, Cmd Msg )
update message model =
    case message of
        UpdateCurrentTimeFail ->
            ( model, Cmd.none )

        UpdateCurrentTime newTime ->
            ( { model | currentTime = Just newTime }, Cmd.none )

        PlaylistMsg playlistId playlistMsg ->
            applyMessageToPlaylists playlistMsg model [ playlistId ]

        PlaylistEvent playlistId event ->
            case event of
                Playlist.NewTracksWereFetched ( tracks, nextLink ) ->
                    let
                        updatedTrackDict =
                            tracks
                                |> List.map (\track -> ( track.id, track ))
                                |> Dict.fromList
                                |> Dict.union model.tracks
                    in
                        ( { model | tracks = updatedTrackDict }
                        , Cmd.none
                        )

                Playlist.TrackWasClicked previousTrackId track ->
                    let
                        newModel =
                            { model | currentPlaylist = Just playlistId }
                    in
                        if previousTrackId == Just track.id then
                            update TogglePlayback newModel
                        else
                            ( { newModel | playing = True }
                            , playTrack
                                { id = track.id
                                , streamUrl = track.streamUrl
                                , currentTime = track.currentTime
                                }
                            )

                Playlist.TrackWasAddedToCustomQueue trackId ->
                    ( { model | customQueue = List.append model.customQueue [ trackId ] }
                    , Cmd.none
                    )

        TrackError trackId ->
            let
                newModel =
                    { model
                        | tracks =
                            Dict.update
                                trackId
                                (Maybe.map (\track -> { track | error = True }))
                                model.tracks
                    }

                ( newModel', command ) =
                    update Next newModel
            in
                ( newModel', command )

        TogglePlayback ->
            ( { model | playing = not model.playing }
            , if model.playing then
                pause (currentTrackId model)
              else
                resume (currentTrackId model)
            )

        Next ->
            let
                ( model', command ) =
                    case model.currentPlaylist of
                        Nothing ->
                            ( model, Cmd.none )

                        Just playlistId ->
                            applyMessageToPlaylists Playlist.Next model [ playlistId ]
            in
                ( model'
                , case currentTrackId model' of
                    Nothing ->
                        pause (currentTrackId model)

                    Just trackId ->
                        case Dict.get trackId model.tracks of
                            Nothing ->
                                Cmd.none

                            Just track ->
                                playTrack
                                    { id = track.id
                                    , streamUrl = track.streamUrl
                                    , currentTime = track.currentTime
                                    }
                )

        PlayFromCustomQueue track ->
            ( { model
                | playing = True
                , customQueue = List.filter ((/=) track.id) model.customQueue
              }
            , playTrack
                { id = track.id
                , streamUrl = track.streamUrl
                , currentTime = track.currentTime
                }
            )

        TrackProgress ( trackId, progress, currentTime ) ->
            ( { model
                | tracks =
                    Dict.update
                        trackId
                        (Maybe.map (\track -> { track | progress = progress, currentTime = currentTime }))
                        model.tracks
              }
            , Cmd.none
            )

        ChangePage url ->
            ( model, Navigation.newUrl url )


handlePlaylistMsg : Playlist -> Playlist.Msg -> Model -> ( Model, Cmd Msg )
handlePlaylistMsg playlist playlistMsg model =
    let
        ( updatedPlaylist, command, event ) =
            Playlist.update playlistMsg playlist.model

        updatedModel =
            { model
                | playlists =
                    model.playlists
                        |> List.filter ((/=) playlist.id << .id)
                        |> List.append [ Playlist playlist.id updatedPlaylist ]
            }
    in
        case event of
            Nothing ->
                ( updatedModel
                , Cmd.map (PlaylistMsg playlist.id) command
                )

            Just event ->
                let
                    ( modelAfterEvent, eventCommand ) =
                        update (PlaylistEvent playlist.id event) updatedModel
                in
                    (modelAfterEvent ! [ Cmd.map (PlaylistMsg playlist.id) command, eventCommand ])


applyMessageToPlaylists : Playlist.Msg -> Model -> List PlaylistId -> ( Model, Cmd Msg )
applyMessageToPlaylists playlistMsg model playlistIds =
    let
        playlists =
            List.filter
                (\playlist -> List.member playlist.id playlistIds)
                model.playlists
    in
        List.foldr
            (\playlist ( m, c ) ->
                let
                    ( m', c' ) =
                        handlePlaylistMsg playlist playlistMsg m
                in
                    ( m', Cmd.batch [ c, c' ] )
            )
            ( model, Cmd.none )
            playlists



-- SUBSCRIPTIONS


port trackProgress : (( TrackId, Float, Float ) -> msg) -> Sub msg


port trackEnd : (TrackId -> msg) -> Sub msg


port trackError : (TrackId -> msg) -> Sub msg


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ trackProgress TrackProgress
        , trackEnd (\_ -> Next)
        , trackError TrackError
        ]


currentTrackId : Model -> Maybe TrackId
currentTrackId model =
    let
        findPlaylist id =
            List.filter ((==) id << .id) model.playlists
                |> List.head
    in
        model.currentPlaylist
            `Maybe.andThen` findPlaylist
            `Maybe.andThen` (.model >> .items >> Just)
            `Maybe.andThen` PlaylistStructure.currentItem



-- VIEW


view : Model -> Html Msg
view model =
    let
        currentTrack =
            currentTrackId model
                `Maybe.andThen` \trackId -> Dict.get trackId model.tracks

        currentPagePlaylist =
            List.filter ((==) model.currentPage << .id) model.playlists
                |> List.head
    in
        div
            []
            [ viewGlobalPlayer currentTrack model.playing
            , viewNavigation navigation model.currentPage model.currentPlaylist
            , viewCustomQueue model.tracks model.customQueue
            , div
                []
                [ case currentPagePlaylist of
                    Nothing ->
                        div [] [ text "Well, this is awkward..." ]

                    Just playlist ->
                        case playlist.id of
                            Radio ->
                                let
                                    currentRadioTrack =
                                        case PlaylistStructure.currentItem playlist.model.items of
                                            Nothing ->
                                                Nothing

                                            Just id ->
                                                Dict.get id model.tracks
                                in
                                    viewRadioTrack currentRadioTrack

                            _ ->
                                div [ class "playlist-container" ]
                                    [ Html.map
                                        (PlaylistMsg playlist.id)
                                        (Playlist.view model.currentTime model.tracks playlist.model)
                                    ]
                ]
            ]


viewRadioTrack : Maybe Track -> Html Msg
viewRadioTrack track =
    case track of
        Nothing ->
            div [] [ text "..." ]

        Just track ->
            div
                [ class "radio-track" ]
                [ img
                    [ class "cover"
                    , src (Regex.replace Regex.All (Regex.regex "large") (\_ -> "t500x500") track.artwork_url)
                    ]
                    []
                , div
                    [ class "track-info" ]
                    [ div [ class "artist" ] [ text track.artist ]
                    , div [ class "title" ] [ text track.title ]
                    , a
                        [ class "source"
                        , href track.sourceUrl
                        , target "_blank"
                        ]
                        [ text "Source" ]
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
                        [ classList
                            [ ( "playback-button", True )
                            , ( "playing", playing && not track.error )
                            , ( "error", track.error )
                            ]
                        , onClick (TogglePlayback)
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
                            , style [ ( "width", (toString track.progress) ++ "%" ) ]
                            ]
                            []
                        ]
                    ]
                , div
                    [ class "actions" ]
                    []
                ]


viewCustomQueue : Dict TrackId Track -> List TrackId -> Html Msg
viewCustomQueue tracks queue =
    queue
        |> List.filterMap (\trackId -> Dict.get trackId tracks)
        |> List.map (viewCustomPlaylistItem)
        |> div [ class "custom-queue" ]


viewCustomPlaylistItem : Track -> Html Msg
viewCustomPlaylistItem track =
    div
        [ class "custom-queue-track"
        , onClick (PlayFromCustomQueue track)
        ]
        [ img [ src track.artwork_url ] []
        , div
            [ class "track-info" ]
            [ div [] [ text track.artist ]
            , div [] [ text track.title ]
            ]
        ]


type alias NavigationItem =
    { displayName : String
    , href : String
    , page : Page
    }


navigation : List NavigationItem
navigation =
    [ NavigationItem "radio" "/radio" Radio
    , NavigationItem "latest tracks" "/latest" LatestTracks
    ]


viewNavigation : List NavigationItem -> Page -> Maybe PlaylistId -> Html Msg
viewNavigation navigationItems currentPage currentPlaylist =
    navigationItems
        |> List.map (viewNavigationItem currentPage currentPlaylist)
        |> ul []
        |> List.repeat 1
        |> nav [ class "navigation" ]


viewNavigationItem : Page -> Maybe PlaylistId -> NavigationItem -> Html Msg
viewNavigationItem currentPage currentPlaylist navigationItem =
    let
        classes =
            classList
                [ ( "active", navigationItem.page == currentPage )
                , ( "playing", Just navigationItem.page == currentPlaylist )
                ]
    in
        li
            [ onWithOptions
                "click"
                { stopPropagation = False
                , preventDefault = True
                }
                (Json.Decode.succeed (ChangePage navigationItem.href))
            ]
            [ a
                (classes :: [ href navigationItem.href ])
                [ text navigationItem.displayName ]
            ]
