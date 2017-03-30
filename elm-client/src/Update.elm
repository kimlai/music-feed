module Update exposing (andThen, identity, addCmd)


andThen : ( model -> ( model, Cmd msg ))
        -> ( model, Cmd msg )
        -> ( model, Cmd msg )
andThen update ( model, cmd ) =
    let
        ( updatedModel, newCmd ) = update model
    in
        updatedModel ! [ cmd, newCmd ]



identity : model -> ( model, Cmd msg )
identity model =
    ( model, Cmd.none )


addCmd : Cmd msg -> ( model, Cmd msg ) -> ( model, Cmd msg )
addCmd newCmd ( model, cmd ) =
    model ! [ cmd, newCmd ]
