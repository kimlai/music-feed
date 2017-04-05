module Update exposing (andThen, identity, addCmd, when)


andThen : (model -> ( model, Cmd msg ))
       -> ( model, Cmd msg )
       -> ( model, Cmd msg )
andThen update ( model, cmd ) =
    let
        ( updatedModel, newCmd ) = update model
    in
        updatedModel ! [ cmd, newCmd ]


when : (model -> Bool)
    -> (model -> ( model, Cmd msg ))
    -> ( model, Cmd msg )
    -> ( model, Cmd msg )
when predicate update ( model, cmd ) =
    if predicate model then
        andThen update ( model, cmd )
    else
        ( model, cmd )


identity : model -> ( model, Cmd msg )
identity model =
    ( model, Cmd.none )


addCmd : Cmd msg -> ( model, Cmd msg ) -> ( model, Cmd msg )
addCmd newCmd ( model, cmd ) =
    model ! [ cmd, newCmd ]
