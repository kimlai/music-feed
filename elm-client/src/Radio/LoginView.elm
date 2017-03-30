module Radio.LoginView exposing (view)


import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Extra exposing (link)
import Radio.LoginForm as LoginForm exposing (LoginForm, Field(..))
import Radio.Update exposing (Msg(..))


view : LoginForm -> Html Msg
view form =
    Html.form
        [ class "login-form"
        , onSubmit LoginSubmit
        , action "login"
        ]
        [ h1 [] [ text "Sign in to Me Likey Radio" ]
        , div
            []
            [ input
                [ type_ "text"
                , placeholder "Username or E-mail"
                , name "name"
                , id "usernameOrEmail"
                , onInput LoginUpdateEmailOrUsername
                , onBlur (LoginBlurredField EmailorUsername)
                ]
                []
            , div
                [ class "error" ]
                [ text (LoginForm.error EmailorUsername form |> Maybe.withDefault "") ]
            ]
        , div
            []
            [ input
                [ type_ "password"
                , placeholder "Password"
                , onInput LoginUpdatePassword
                , onBlur (LoginBlurredField Password)
                , id "password"
                ]
                []
            , div
                [ class "error" ]
                [ text (LoginForm.error Password form |> Maybe.withDefault "") ]
            ]
        , button
            [ type_ "submit"
            , disabled (not (LoginForm.isValid form))
            ]
            [ text "Go!" ]
        , div
            []
            [ span [] [ text "or " ]
            , link
                FollowLink
                "/sign-up"
                []
                [ text "sign up" ]
            ]
        ]
