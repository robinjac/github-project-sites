// @ts-ignore
import { Elm } from "./elm/Main.elm";

import view_state from "./test/view_state.json";

type Slug = `${string}-${string}${string}`;
type BranchType = `${string}`;
type Date = `${string}-${string}-${string} ${string}:${string}`;

type Branch = {
    name: string;
    slug: Slug;
    date: Date;
};

type Project = {
    name: string;
    repository: string;
    branches: { [branchType: BranchType]: Branch[] };
};

type ViewState = {
    id: number;
    host_repository: string;
    projects: Project[];
};

Elm.Main.init({
    flags: view_state as ViewState,
    node: document.getElementById("app") as HTMLElement,
});
