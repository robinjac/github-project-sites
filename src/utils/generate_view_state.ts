import fs from "fs";
import { main_branches, branch_types, slug } from "../update-daily/helpers";

const generatedProjectNames = new Map();
const generatedBranchNames: string[] = [];
const generatedUsers: string[] = [];
const generatedVersions: string[] = [];

const alphabet = [
    "a",
    "b",
    "c",
    "d",
    "e",
    "f",
    "g",
    "h",
    "i",
    "j",
    "k",
    "l",
    "m",
    "n",
    "o",
    "p",
    "q",
    "r",
    "s",
    "t",
    "u",
    "v",
    "w",
    "x",
    "y",
    "z"
];

const digits = [
    0,
    1,
    2,
    3,
    4,
    5,
    6,
    7,
    8,
    9
];

const chars: string[] = [
    ...digits.map(n => n.toString()),
    ...alphabet,
    "-",
    "/"
];

const view_state: IDailyMetaData = {
    id: Date.now(),
    host_repository: generateRandomString(10, alphabet),
    projects: []
}

function generateRandomString(len: number, characters: string[]) {
    const str = [];
    const charactersLen = characters.length - 1;

    for (let i = 0; i < len; i++) {

        const c = characters[Math.round(Math.random() * charactersLen)];
        str.push(Math.random() > 0.5 ? c.toUpperCase() : c);
    }

    return str.join("");
}

function generateRandomProjectIdentifier(len: number): string {
    const projectName = generateRandomString(len, alphabet).toUpperCase();

    if (generatedProjectNames.has(projectName)) {
        return generateRandomProjectIdentifier(len);
    } else {
        generatedProjectNames.set(projectName, 1);
    }

    return projectName + "-" + generatedProjectNames.get(projectName);
}

function incrementProjectIdentifier(identifier: string): string {

    if (generatedProjectNames.has(identifier)) {
        generatedProjectNames.set(identifier, generatedProjectNames.get(identifier) + 1);
    } else {
        generatedProjectNames.set(identifier, 1);
    }

    return identifier + "-" + generatedProjectNames.get(identifier);
}

function generateRandomUser(): string {

    const randomUser = generateRandomString(4, alphabet).toLowerCase();

    if (generatedUsers.includes(randomUser)) {
        return generateRandomUser();
    }

    generatedUsers.push(randomUser);

    return randomUser;
}

function generateRandomDate(): string {

    const startDate = new Date(2012, 0, 1);
    const endDate = new Date();

    const date = new Date(startDate.getTime() + Math.random() * (endDate.getTime() - startDate.getTime()));
    const year = date.getFullYear();
    const month = date.getMonth() + 1;
    const day = date.getDate();
    const hour = date.getHours();
    const minute = date.getMinutes();

    // Write the date in yyyy-mm-dd hh:mm.
    return `${year}-${month < 10 ? `0${month}` : month}-${day < 10 ? `0${day}` : day
        } ${hour}:${minute}`;
}

function generateRandomVersion(): string {
    const randomVersion = Math.round(Math.random() * 99).toString() + "." + Math.round(Math.random() * 99).toString() + "." + Math.round(Math.random() * 999).toString();

    if (generatedVersions.includes(randomVersion)) {
        return generateRandomVersion();
    }

    generatedVersions.push(randomVersion);

    return randomVersion;
}


function generateBranchName(type: BranchName): string {

    if (type === "main") {

        for (const branch of main_branches) {
            if (!generatedBranchNames.includes(branch)) {
                generatedBranchNames.push(branch);
                return branch;
            }
        }
    }

    if (type === "user" || type === "feature") {

        const projectIdentifiers = Array.from(generatedProjectNames.keys());

        const projectIdentifier = projectIdentifiers.length === 0
            ? generateRandomProjectIdentifier(2 + Math.round(Math.random() * 2)) + "-"
            : incrementProjectIdentifier(projectIdentifiers[Math.round(Math.random() * (projectIdentifiers.length - 1))]);

        const withProjectIdentifier = Math.random() > 0.5 ? projectIdentifier : "";


        if (type === "feature") {
            return "feature/" + withProjectIdentifier + generateRandomString(Math.round(10 + Math.random() * 10), chars).toLowerCase();
        }


        const useExistingUser = Math.random() > 0.5 || generatedUsers.length === 0 ? generateRandomUser() : generatedUsers[Math.round(Math.random() * (generatedUsers.length - 1))];

        return "user/" + useExistingUser + "/" + withProjectIdentifier + generateRandomString(Math.round(10 + Math.random() * 10), chars).toLowerCase();
    }

    if (type === "release") {
        return "release/" + generateRandomVersion();
    }

    return generateRandomString(Math.round(5 + Math.random() * 10), chars);
}


for (let i = 0; i < 5; i++) {

    const branches: IDailyBranches = {
        main: [],
        user: [],
        release: [],
        feature: [],
        other: []
    };

    for (let k = 0; k < 500; k++) {
        const branchType = branch_types[Math.round(Math.random() * (branch_types.length - 1))];

        const name = generateBranchName(branchType);
        branches[branchType].push({
            name,
            slug: slug(name),
            date: generateRandomDate()
        })
    }

    const project: IDailyProject = {
        name: generateRandomString(10, alphabet),
        repository: generateRandomString(10, alphabet),
        branches
    };
    view_state.projects.push(project);
}

fs.writeFileSync(
    `./src/daily-client/test/view_state.json`,
    JSON.stringify(view_state, null, 4)
);


