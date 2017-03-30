module Radio.LoginForm exposing (..)


type alias LoginForm =
    { emailOrUsername : String
    , password : String
    , fieldsWhichShouldBeValid : List Field
    , serverErrors : List ( Field, String )
    }


type Field
    = EmailorUsername
    | Password


empty : LoginForm
empty =
    { emailOrUsername = ""
    , password = ""
    , fieldsWhichShouldBeValid = []
    , serverErrors = []
    }


updateEmailOrUsername : String -> LoginForm -> LoginForm
updateEmailOrUsername newEmailOrUsername form =
    { form | emailOrUsername = newEmailOrUsername
    , serverErrors = List.filter (\( field, error) -> field /= EmailorUsername) form.serverErrors
    }


updatePassword : String -> LoginForm -> LoginForm
updatePassword newPassword form =
    { form | password = newPassword
    , serverErrors = List.filter (\( field, error) -> field /= Password) form.serverErrors
    }


startValidating : Field -> LoginForm -> LoginForm
startValidating field form =
    { form | fieldsWhichShouldBeValid = (::) field form.fieldsWhichShouldBeValid }


setServerErrors : List ( Field, String ) -> LoginForm -> LoginForm
setServerErrors errors form =
    { form | serverErrors = errors }


serverError : Field -> LoginForm -> Maybe String
serverError field { serverErrors } =
    List.filter (\( id, error ) -> id == field ) serverErrors
        |> List.head
        |> Maybe.map Tuple.second


validateEmailOrUsername : LoginForm -> Maybe String
validateEmailOrUsername =
    validate
        [ serverError EmailorUsername
        , .emailOrUsername >> ifEmpty "Please enter your username or E-mail"
        ]


validatePassword : LoginForm -> Maybe String
validatePassword =
    validate
        [ serverError Password
        , .password >> ifEmpty "Please enter a password"
        ]


validate : List (LoginForm -> Maybe String) -> LoginForm-> Maybe String
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


error : Field -> LoginForm -> Maybe String
error field form =
    if not (shouldBeValid field form) then
        Nothing
    else
        case field of
            EmailorUsername ->
                validateEmailOrUsername form
            Password ->
                validatePassword form


shouldBeValid : Field -> LoginForm -> Bool
shouldBeValid field { fieldsWhichShouldBeValid } =
    fieldsWhichShouldBeValid
        |> List.filter ((==) field)
        |> List.isEmpty
        |> not


isValid : LoginForm -> Bool
isValid form =
    validate
        [ validateEmailOrUsername
        , validatePassword
        ]
        form
        |> (==) Nothing
