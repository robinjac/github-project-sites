module Main exposing (Msg(..), main, update, view)

import Browser
import Dict exposing (Dict)
import Html exposing (Attribute, Html)
import Html.Attributes as Attr exposing (class, colspan, value)
import Html.Events exposing (onClick, onInput)
import Maybe exposing (withDefault)


type alias SiteMetaData =
    { id : Int
    , projects : List Project
    , host_repository : String
    }


type alias BranchData =
    { name : String
    , slug : String
    , date : String
    }


type alias Branches =
    List BranchData


type alias Project =
    { name : String
    , repository : String
    , branches : BranchRecord
    }


type alias Projects =
    Dict String Project


type alias BranchRecord =
    { main : Branches
    , release : Branches
    , user : Branches
    , other : Branches
    }


type Page
    = Start
    | End
    | Prev
    | Next


type alias Model =
    { selectedProject : Maybe Project
    , selectedBranchType : String
    , projects : Projects
    , branches : Maybe Branches
    , currentPageIndex : Int
    , hostRepository : String
    }


type Msg
    = SelectProject String
    | SelectBranchType String
    | Pagination Page


branchTypes : List String
branchTypes =
    [ "main", "release", "user", "other" ]


maxRows : Int
maxRows =
    10


getBranchesByType : String -> BranchRecord -> Branches
getBranchesByType branchType branchRecord =
    case branchType of
        "main" ->
            branchRecord.main

        "release" ->
            branchRecord.release

        "user" ->
            branchRecord.user

        _ ->
            branchRecord.other


getBranches : Maybe Project -> String -> Projects -> Maybe Branches
getBranches project branchType projects =
    Maybe.andThen
        (\{ name } ->
            Dict.get name projects
                |> Maybe.map (.branches >> getBranchesByType branchType)
        )
        project


init : SiteMetaData -> ( Model, Cmd Msg )
init meta =
    let
        firstProject =
            List.head meta.projects

        projects =
            meta.projects |> List.map (\project -> ( project.name, project )) |> Dict.fromList

        model =
            { selectedBranchType = "main"
            , selectedProject = firstProject
            , projects = projects
            , branches = Maybe.map (.branches >> .main) firstProject
            , currentPageIndex = 0
            , hostRepository = meta.host_repository
            }
    in
    ( model, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


main : Program SiteMetaData Model Msg
main =
    Browser.element { init = init, subscriptions = subscriptions, update = update, view = view }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SelectBranchType branchType ->
            ( { model | selectedBranchType = branchType, branches = getBranches model.selectedProject branchType model.projects, currentPageIndex = 0 }, Cmd.none )

        SelectProject projectName ->
            let
                project =
                    Dict.get projectName model.projects
            in
            ( { model | selectedProject = project, branches = getBranches project model.selectedBranchType model.projects, currentPageIndex = 0 }, Cmd.none )

        Pagination page ->
            let
                maxIndex =
                    List.length (withDefault [] model.branches) // maxRows

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
            ( { model | currentPageIndex = nextPageIndex }, Cmd.none )


dailyUrl : Model -> BranchData -> Maybe String
dailyUrl { selectedProject, hostRepository } data =
    Maybe.map (\{ name } -> String.join "/" [ "/" ++ hostRepository, name, data.slug ]) selectedProject


rowElement : Model -> RowType -> BranchData -> Html Msg
rowElement model rowType data =
    Html.tr [ rowClass rowType ]
        [ Html.td []
            [ Html.text data.name
            ]
        , Html.td [ class "w-40" ] [ Html.text data.date ]
        , Html.td [ class "w-10 text-center" ]
            [ Html.a
                [ class "px-1 border font-bold border-gray-300 bg-gray-200 text-gray-900 hover:bg-gray-900 hover:text-white rounded"
                , Attr.href (withDefault "" (dailyUrl model data))
                ]
                [ Html.text "+" ]
            ]
        ]


layout : Model -> Html Msg
layout model =
    let
        reversed =
            model.branches |> withDefault [] |> List.reverse

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
    Html.div [ class "md:container md:mx-auto mt-16 p-2 border min-h-664 border-gray-200 rounded-md flex flex-col justify-self-start" ]
        [ content model
        , dailyTable rows
        , pagination model.currentPageIndex (List.length visibleRows) (List.length reversed)
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


tableContent : List (Html Msg) -> List (Html Msg)
tableContent rows =
    if List.length rows == 0 then
        [ Html.tr [ rowClass LastRow ] [ Html.td [ colspan 3, class "text-center" ] [ Html.text "No branches" ] ] ]

    else
        rows


dailyTable : List (Html Msg) -> Html Msg
dailyTable rows =
    Html.table [ class "mt-8 w-full box-content" ]
        [ Html.thead []
            [ Html.tr [ rowClass NotLastRow ]
                [ Html.th [ class "text-left" ] [ Html.text "Branch" ]
                , Html.th [ class "text-left w-40" ] [ Html.text "Updated" ]
                , Html.th [ class "text-center w-10" ] [ Html.text "Site" ]
                ]
            ]
        , Html.tbody [] (tableContent rows)
        ]


content : Model -> Html Msg
content model =
    selectField
        [ availableProjects model
        , availableBranches
        ]


availableProjects : Model -> Html Msg
availableProjects model =
    Dict.keys model.projects |> selectDropdown (onInput SelectProject)


availableBranches : Html Msg
availableBranches =
    branchTypes |> selectDropdown (onInput SelectBranchType)


selectDropdown : Attribute Msg -> List String -> Html Msg
selectDropdown handleClick items =
    let
        render item =
            Html.option [ value item ] [ Html.text item ]
    in
    items |> List.map render |> Html.select [ class " text-gray-900 cursor-pointer", handleClick ]


selectField : List (Html msg) -> Html msg
selectField selects =
    Html.div [ class "flex flex-row justify-between border border-gray-300 rounded-md p-1 w-60 select-none" ] selects


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
            "border font-bold border-gray-300 bg-gray-200 text-gray-900 rounded-md mr-1 text-center leading-8 w-8 h-8 cursor-pointer select-none"
    in
    Html.nav [ class "w-full flex justify-between mt-auto" ]
        [ Html.div [ class "flex items-center ml-2" ] [ Html.text (String.fromInt (1 + visablePages) ++ "-" ++ String.fromInt (rows + visablePages)), Html.text (" of " ++ String.fromInt pages) ]
        , Html.ul
            [ class "flex list-none mr-2" ]
            [ Html.li [ class (liClasses ++ shouldDisable (page == 0)), onClick (Pagination Start) ] [ Html.text "|<" ]
            , Html.li [ class (liClasses ++ shouldDisable (page == 0)), onClick (Pagination Prev) ] [ Html.text "<" ]
            , Html.li [ class (liClasses ++ shouldDisable (1 + visablePages + maxRows >= pages)), onClick (Pagination Next) ] [ Html.text ">" ]
            , Html.li [ class (liClasses ++ shouldDisable (1 + visablePages + maxRows >= pages)), onClick (Pagination End) ] [ Html.text ">|" ]
            ]
        ]


view : Model -> Html Msg
view model =
    layout model
