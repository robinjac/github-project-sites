module Main exposing (Msg(..), main, update, view)

import Browser
import Dict exposing (Dict)
import Html exposing (Attribute, Html)
import Html.Attributes as Attr exposing (class, colspan, value)
import Html.Events exposing (onClick, onInput)
import Http
import Icons
import Iso8601
import Json.Decode exposing (Decoder, andThen, field, list, map, map3, maybe, string, succeed)
import Maybe exposing (Maybe, withDefault)


type alias DailySiteData =
    { owner : String
    , selectedProject : Project
    , projects : List Project
    , hostRepository : String
    }


type alias Branch =
    { name : String
    , slug : String
    , date : String
    }


type alias Project =
    { name : String
    , path : String
    , branches : List Branch
    }


type Page
    = Start
    | End
    | Prev
    | Next


type alias DailySiteState model =
    { model | currentPageIndex : Int }


type alias Model =
    DailySiteState DailySiteData


type ApplicationModel
    = Loading
    | Error
    | Success Model


type Msg
    = SelectProject Project
    | Pagination Page
    | GotProjects (Result Http.Error (List Project))
    | GotBranches (Result Http.Error (List Branch))


maxRows : Int
maxRows =
    10


init : () -> ( ApplicationModel, Cmd Msg )
init _ =
    ( Loading
    , getProjects
    )


subscriptions : ApplicationModel -> Sub Msg
subscriptions _ =
    Sub.none


main : Program () ApplicationModel Msg
main =
    Browser.element { init = init, subscriptions = subscriptions, update = update, view = view }


produrl =
    "https://api.github.com/repos/robinjac/daily-sites/contents/"


testurl =
    "../mock-github/content.json"


url : Maybe String -> String
url maybePath =
    testurl
        ++ withDefault "" maybePath


projectDecoder : Decoder (Maybe Project)
projectDecoder =
    let
        decodeProject =
            map3 Project
                (field "name" string)
                (field "path" string)
                (succeed [])
    in
    field "dir" string
        |> andThen
            (\value ->
                if value == "dir" then
                    map Just decodeProject

                else
                    succeed Nothing
            )


branchDecoder : Decoder Branch
branchDecoder =
    map3 Branch
        (field "name" string)
        (field "slug" string)
        (field "date" string)


getProjects : Cmd Msg
getProjects =
    Http.get
        { url = url Nothing
        , expect = Http.expectJson GotProjects (map (List.filterMap identity) (list projectDecoder))
        }


getBranches : Project -> Cmd Msg
getBranches project =
    Http.get
        { url = url (Just project.path)
        , expect = Http.expectJson GotBranches (list branchDecoder)
        }


handleSuccess : ApplicationModel -> (Model -> Model) -> ( ApplicationModel, Cmd Msg )
handleSuccess applicationModel updater =
    case applicationModel of
        Success model ->
            ( Success (updater model), Cmd.none )

        _ ->
            ( applicationModel, Cmd.none )


update : Msg -> ApplicationModel -> ( ApplicationModel, Cmd Msg )
update msg applicationModel =
    case msg of
        GotProjects result ->
            case result of
                Ok projects ->
                    ( Loading, Cmd.none )

                Err _ ->
                    ( Error, Cmd.none )

        GotBranches result ->
            case result of
                Ok branches ->
                    ( Loading, Cmd.none )

                Err _ ->
                    ( Error, Cmd.none )

        SelectProject project ->
            handleSuccess applicationModel (\model -> { model | selectedProject = project, currentPageIndex = 0 })

        Pagination page ->
            handleSuccess applicationModel
                (\model ->
                    let
                        maxIndex =
                            List.length model.selectedProject.branches // maxRows

                        nextPageIndex =
                            case page of
                                Start ->
                                    0

                                Prev ->
                                    if model.currentPageIndex == 0 then
                                        model.currentPageIndex

                                    else
                                        model.currentPageIndex - 1

                                Next ->
                                    if model.currentPageIndex >= maxIndex then
                                        model.currentPageIndex

                                    else
                                        model.currentPageIndex + 1

                                End ->
                                    maxIndex
                    in
                    { model | currentPageIndex = nextPageIndex }
                )


dailyUrl : Model -> Branch -> String
dailyUrl { selectedProject, hostRepository } branch =
    String.join "/" [ "/" ++ hostRepository, .name selectedProject, branch.slug, "branch" ]


formatIso8601 : String -> String
formatIso8601 str =
    case Iso8601.toTime str of
        Ok posix ->
            Iso8601.fromTime posix
                |> String.dropRight 5
                |> String.split "T"
                |> String.join " "

        Err _ ->
            "N/A"


rowElement : Model -> RowType -> Branch -> Html Msg
rowElement model rowType branch =
    Html.tr [ rowClass rowType ]
        [ Html.td []
            [ Html.text branch.name
            ]
        , Html.td [ class "w-40" ] [ Html.text (formatIso8601 branch.date) ]
        , Html.td [ class "w-20 h-12 flex justify-end items-center" ]
            [ Html.a
                [ class "text-gray-900"
                , Attr.href (dailyUrl model branch)
                ]
                [ Icons.newWindow ]
            ]
        ]


type RowType
    = LastRow
    | NotLastRow


rowClass : RowType -> Attribute msg
rowClass row =
    case row of
        LastRow ->
            class "h-12"

        NotLastRow ->
            class "h-12 border-b border-gray-200 "


tableBody : List (Html Msg) -> Html Msg
tableBody rows =
    Html.table [ class "mt-4 w-full box-content" ]
        [ Html.thead []
            [ Html.tr [ rowClass NotLastRow ]
                [ Html.th [ class "text-left" ] [ Html.text "Branch" ]
                , Html.th [ class "text-left w-40" ] [ Html.text "Updated" ]
                , Html.th [ class "text-right w-20" ] [ Html.text "Site" ]
                ]
            ]
        , Html.tbody [] <|
            if List.isEmpty rows then
                [ Html.tr [ class "h-12" ]
                    [ Html.td [ colspan 3, class "text-center" ] [ Html.text "No branches" ]
                    ]
                ]

            else
                rows
        ]


tableHeader : Model -> Html Msg
tableHeader model =
    selectField
        [ availableProjects model
        ]


availableProjects : Model -> Html Msg
availableProjects model =
    let
        toProject projects input =
            SelectProject <|
                case List.filter (\project -> project.name == input) projects of
                    [ project ] ->
                        project

                    _ ->
                        model.selectedProject
    in
    model.projects |> selectDropdown (onInput (toProject model.projects))


selectDropdown : Attribute Msg -> List Project -> Html Msg
selectDropdown handleClick projects =
    let
        render project =
            Html.option [] [ Html.text project.name ]
    in
    projects |> List.map render |> Html.select [ class " text-gray-900 cursor-pointer pr-1 outline-none", handleClick ]


selectField : List (Html msg) -> Html msg
selectField =
    Html.div [ class "flex flex-row justify-between border border-gray-300 rounded-md p-2 w-min select-none" ]


shouldDisable : Bool -> String
shouldDisable bool =
    if bool then
        " pointer-events-none opacity-40"

    else
        " hover:bg-gray-900 hover:text-white"


pagination : Int -> Int -> Int -> Html Msg
pagination page rows pages =
    let
        visablePages =
            page * maxRows

        liClasses =
            "border border-gray-300 bg-gray-200 text-gray-900 rounded-md mr-1 w-8 h-8 cursor-pointer select-none inline-flex justify-center items-center"
    in
    Html.nav [ class "w-full flex justify-between items-center mt-auto" ]
        [ Html.div [ class "inline-flex items-center" ] [ Html.text (String.fromInt (1 + visablePages) ++ "-" ++ String.fromInt (rows + visablePages)), Html.text (" of " ++ String.fromInt pages) ]
        , Html.div
            [ class "inline-flex" ]
            [ Html.div [ class (liClasses ++ shouldDisable (page == 0)), onClick (Pagination Start) ] [ Icons.chevronDoubleLeft ]
            , Html.div [ class (liClasses ++ shouldDisable (page == 0)), onClick (Pagination Prev) ] [ Icons.chevronLeft ]
            , Html.div [ class (liClasses ++ shouldDisable (1 + visablePages + maxRows >= pages)), onClick (Pagination Next) ] [ Icons.chevronRight ]
            , Html.div [ class (liClasses ++ shouldDisable (1 + visablePages + maxRows >= pages)), onClick (Pagination End) ] [ Icons.chevronDoubleRight ]
            ]
        ]


table : Model -> Html Msg
table model =
    let
        reversed =
            List.reverse model.selectedProject.branches

        visibleRows =
            reversed
                |> List.drop (model.currentPageIndex * maxRows)
                |> List.take maxRows

        lastRow =
            List.take 1 visibleRows |> List.map (rowElement model LastRow)

        firstRows =
            List.drop 1 visibleRows |> List.map (rowElement model NotLastRow)

        rows =
            firstRows ++ lastRow
    in
    Html.div [ class "bg-white max-w-screen-lg mx-auto h-[calc(100vh-11rem)] shadow-md mt-12 p-5 pb-2 border border-gray-200 rounded-md flex flex-col justify-self-start" ]
        [ tableHeader model
        , tableBody rows
        , pagination model.currentPageIndex (List.length visibleRows) (List.length reversed)
        ]


view : ApplicationModel -> Html Msg
view applicationModel =
    Html.div [ class "absolute inset-0 overflow-hidden bg-neutral-100" ]
        [ Html.div [ class "relative inset-x-0 h-20 bg-teal-800 top-0 shadow-lg" ]
            [ Html.div [ class "relative h-full max-w-screen-lg mx-auto pt-7 px-5" ]
                [ Html.div [ class "relative left-0 w-48 h-full overflow-hidden" ]
                    [ Icons.logo "white" "Daily Sites"
                    ]
                ]
            ]
        , case applicationModel of
            Loading ->
                Html.text "loading"

            Error ->
                Html.text "oops something went wrong!"

            Success model ->
                table model
        ]
