
export function getProject(project_name: string, repo: string, projects: IDailyProject[]): IDailyProject {

    let project = projects.find(project => project.name === project_name);

    if (!project) {
        project = {
            name: project_name,
            repository: repo,
            branches: {
                main: [],
                release: [],
                feature: [],
                user: [],
                other: []
            }
        };
        projects.push(project);
    }

    return project;
}

export const script_tag = (_id: number): string =>
    `<script id="daily_site_view_model" src="./www/view_model.${_id}.js"></script>`;

export function actionHandler(action: TDailyAction, project: IDailyProject, branch_name: string): boolean {

    const slug_name = slug(branch_name);
    const slug_parts = slug_name.split("-");
    const type = getBranchType(slug_parts);

    const branch_data = {
        name: branch_name.includes("/") ? branch_name : "N/A",
        slug: slug_name,
        date: getDate()
    };

    switch (action.toLowerCase()) {
        case "created":
        case "updated":
            if (!project.branches[type].find(_branch => sameBranch(_branch, branch_data))) {
                project.branches[type].push(branch_data);
                return true;
            }

            return false;
        case "deleted":
            if (project.branches[type].find(_branch => sameBranch(_branch, branch_data))) {
                project.branches[type] = project.branches[type].filter(_branch => !sameBranch(_branch, branch_data));
                return true;
            }

            return false;
        case "page-push":
            return true;
        default:
            return false;
    }
}

export function getDate(): string {
    const date = new Date();
    const year = date.getFullYear();
    const month = date.getMonth() + 1;
    const day = date.getDate();
    const hour = date.getHours();
    const minute = date.getMinutes();
    // Write the date in yyyy-mm-dd hh:mm.
    return `${year}-${month < 10 ? `0${month}` : month}-${day < 10 ? `0${day}` : day
        } ${hour}:${minute}`;
}

export const main_branches = ["master", "develop", "devel", "development", "main"];
export const branch_types: BranchName[] = ["main", "release", "feature", "user", "other"];

export function getBranchType(slug_parts: string[]): BranchName {
    let type = slug_parts[0];

    if (main_branches.includes(type)) {
        type = "main";
    } else if (!branch_types.includes(type as BranchName)) {
        type = "other";
    }

    return type as BranchName;
}

export function sameBranch(branch1: string | IBranchData, branch2: string | IBranchData): boolean {

    const name1 = typeof branch1 === "string" ? branch1 : branch1.name;
    const name2 = typeof branch2 === "string" ? branch2 : branch2.name;

    return name1 === name2;
}

/**
 * Slug implementation taken from: https://github.com/rlespinasse/github-slug-action/blob/v3.x/src/slug.ts
 */

const MAX_SLUG_STRING_SIZE = 63;

/**
 * slug_cs will take envVar and then :
 * - replace any character by `-` except `0-9`, `a-z`, `.`, and `_`
 * - remove leading and trailing `-` character
 * - limit the string size to 63 characters
 * @param envVar to be slugged
 */
function slug_cs(envVar: string): string {
    return trailHyphen(replaceAnyNonAlphanumericCharacter(envVar)).substring(
        0,
        MAX_SLUG_STRING_SIZE
    );
}

/**
 * slug will take envVar and then :
 * - put the variable content in lower case
 * - replace any character by `-` except `0-9`, `a-z`, `.`, and `_`
 * - remove leading and trailing `-` character
 * - limit the string size to 63 characters
 * @param envVar to be slugged
 */
export function slug(envVar: string): string {
    return slug_cs(envVar.toLowerCase());
}

function trailHyphen(envVar: string): string {
    return envVar.replace(RegExp("^-*", "g"), "").replace(RegExp("-*$", "g"), "");
}

function replaceAnyNonAlphanumericCharacter(envVar: string): string {
    return envVar.replace(RegExp("[^a-zA-Z0-9._]", "g"), "-");
}

export function extractCommitData(commit_title: string): { actor: string, action: TDailyAction, project_name: string, repository: string, branch_name: string } {

    const commit_title_parts = commit_title.split(" ");

    const actor = commit_title_parts.shift() as string;

    const repository = commit_title_parts.shift() as string;

    const project_name =
        commit_title_parts.length === 2 ? repository : commit_title_parts.shift() as string;
    const action = commit_title_parts.shift() as TDailyAction;
    const branch_name = commit_title_parts.shift() as string;

    return {
        actor,
        action,
        project_name,
        repository,
        branch_name
    }
}
