module TimeAgo exposing (timeAgo)


import Date exposing (Date)
import Time exposing (Time)


timeAgo : Maybe Time -> Date -> String
timeAgo currentTime date =
    case currentTime of
        Nothing ->
            ""

        Just time ->
            let
                timeAgo =
                    time - Date.toTime date

                day =
                    24 * Time.hour

                week =
                    7 * day

                month =
                    30 * day

                year =
                    365 * day

                inUnitAgo value ( unitName, unit ) =
                    let
                        valueInUnit =
                            value / unit |> floor

                        pluralize value string =
                            if value > 1 then
                                string ++ "s"
                            else
                                string ++ ""
                    in
                        if valueInUnit == 0 then
                            Nothing
                        else
                            Just (toString valueInUnit ++ " " ++ (pluralize valueInUnit unitName) ++ " ago")
            in
                (List.filterMap
                    (inUnitAgo timeAgo)
                    [ ( "year", year )
                    , ( "month", month )
                    , ( "week", week )
                    , ( "day", day )
                    , ( "hour", Time.hour )
                    , ( "minute", Time.minute )
                    ]
                )
                    |> List.head
                    |> Maybe.withDefault "Just now"
