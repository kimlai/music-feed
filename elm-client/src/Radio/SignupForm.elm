module Radio.SignupForm exposing (..)


import Dict exposing (Dict)
import Regex


type alias SignupForm =
    { email : String
    , username : String
    , password : String
    , fieldsWhichShouldBeValid : List Field
    , serverErrors : List ( Field, String )
    , usernameAvailabilities : Dict String Bool
    , emailAvailabilities : Dict String Bool
    }


type Field
    = Email
    | Username
    | Password


empty : SignupForm
empty =
    { email = ""
    , username = ""
    , password = ""
    , fieldsWhichShouldBeValid = []
    , serverErrors = []
    , usernameAvailabilities = Dict.empty
    , emailAvailabilities = Dict.empty
    }


updateEmail : String -> SignupForm -> SignupForm
updateEmail newEmail form =
    { form | email = newEmail
    , serverErrors = List.filter (\( field, error) -> field /= Email) form.serverErrors
    }


updateUsername : String -> SignupForm -> SignupForm
updateUsername newUsername form =
    { form | username = newUsername
    , serverErrors = List.filter (\( field, error) -> field /= Username) form.serverErrors
    }


updatePassword : String -> SignupForm -> SignupForm
updatePassword newPassword form =
    { form | password = newPassword
    , serverErrors = List.filter (\( field, error) -> field /= Password) form.serverErrors
    }


updateAvailabilities : ( ( String, Bool ), ( String, Bool ) ) -> SignupForm -> SignupForm
updateAvailabilities ( ( email, emailAvailability ), ( username, usernameAvailability ) ) form =
    { form
    | usernameAvailabilities = Dict.insert username usernameAvailability form.usernameAvailabilities
    , emailAvailabilities = Dict.insert email emailAvailability form.emailAvailabilities
    }


startValidating : Field -> SignupForm -> SignupForm
startValidating field form =
    { form | fieldsWhichShouldBeValid = (::) field form.fieldsWhichShouldBeValid }


setServerErrors : List ( Field, String ) -> SignupForm -> SignupForm
setServerErrors errors form =
    { form | serverErrors = errors }


serverError : Field -> SignupForm -> Maybe String
serverError field { serverErrors } =
    List.filter (\( id, error ) -> id == field ) serverErrors
        |> List.head
        |> Maybe.map Tuple.second


validateUsername : SignupForm -> Maybe String
validateUsername form =
    validate
        [ serverError Username
        , .username >> ifEmpty "Please enter a username"
        , .username >> ifNotAvailable form.usernameAvailabilities "Username is already taken"
        ]
        form


validateEmail : SignupForm -> Maybe String
validateEmail form =
    validate
        [ serverError Email
        , .email >> ifEmpty "Please enter an Email address"
        , .email >> ifNotValidEmail "Please enter a valid Email"
        , .email >> ifNotAvailable form.emailAvailabilities "Email is already taken"
        ]
        form


validatePassword : SignupForm -> Maybe String
validatePassword form =
    validate [ .password >> ifEmpty "Please enter a password" ] form


validate : List (SignupForm -> Maybe String) -> SignupForm-> Maybe String
validate validators form =
    case validators of
        [] ->
            Nothing
        validator :: others ->
            case validator form of
                Just error ->
                    Just error
                Nothing ->
                    validate others form


ifEmpty : String -> String -> Maybe String
ifEmpty errorMessage value =
    if String.isEmpty value then
        Just errorMessage
    else
        Nothing


ifNotAvailable : Dict String Bool -> String -> String -> Maybe String
ifNotAvailable availablities errorMessage value =
    if Dict.get value availablities == Just False then
        Just errorMessage
    else
        Nothing


ifNotValidEmail : String -> String -> Maybe String
ifNotValidEmail errorMessage value =
    let
        isValidEmail =
            Regex.contains (Regex.regex "^[^@]+@[^@]+\\.[^@]+$")
    in
        if isValidEmail value then
            Nothing
        else
            Just errorMessage


error : Field -> SignupForm -> Maybe String
error field form =
    if not (shouldBeValid field form) then
        Nothing
    else
        case field of
            Username ->
                validateUsername form
            Email ->
                validateEmail form
            Password ->
                validatePassword form


shouldBeValid : Field -> SignupForm -> Bool
shouldBeValid field { fieldsWhichShouldBeValid } =
    fieldsWhichShouldBeValid
        |> List.filter ((==) field)
        |> List.isEmpty
        |> not


isValid : SignupForm -> Bool
isValid form =
    validate
        [ validateUsername
        , validateEmail
        , validatePassword
        ]
        form
        |> (==) Nothing
