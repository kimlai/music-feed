module Radio.SignupView exposing (view)


import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Radio.SignupForm as SignupForm exposing (SignupForm, Field(..))
import Radio.Update exposing (Msg(..))


view : SignupForm -> Html Msg
view form =
    Html.form
        [ class "signup-form"
        , onSubmit SignupSubmit
        ]
        [ h1 [] [ text "Create an account to save tracks" ]
        , div
            []
            [ input
                [ type_ "text"
                , placeholder "Username"
                , name "name"
                , value form.username
                , onInput SignupUpdateUsername
                , onBlur (SignupBlurredField Username)
                ]
                []
            , div
                [ class "error" ]
                [ text (SignupForm.error Username form |> Maybe.withDefault "") ]
            ]
        , div
            []
            [ input
                [ type_ "text"
                , name "email"
                , placeholder "E-mail"
                , value form.email
                , onInput SignupUpdateEmail
                , onBlur (SignupBlurredField Email)
                ]
                []
            , div
                [ class "error" ]
                [ text (SignupForm.error Email form |> Maybe.withDefault "") ]
            ]
        , div
            []
            [ input
                [ type_ "password"
                , placeholder "Password"
                , value form.password
                , onInput SignupUpdatePassword
                , onBlur (SignupBlurredField Password)
                ]
                []
            , div
                [ class "error" ]
                [ text (SignupForm.error Password form |> Maybe.withDefault "") ]
            ]
        , button
            [ type_ "submit"
            , disabled (not (SignupForm.isValid form))
            ]
            [ text "Go!" ]
        ]
