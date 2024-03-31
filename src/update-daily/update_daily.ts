
import { readFileSync, writeFileSync } from "fs";
import { execSync } from "child_process";
import { getProject, script_tag, actionHandler, extractCommitData } from "./helpers";

const view_state: IDailyMetaData = JSON.parse(
    readFileSync("./tmp/www/view_state.json", "utf-8")
);

const { action, repository, project_name, branch_name } = extractCommitData(process.argv.filter((arg) => arg !== "--experimental-modules")[2]);

const project = getProject(project_name, repository, view_state.projects);

// If the model changed, we need to update the files.
if (actionHandler(action, project, branch_name)) {
    let index_html = readFileSync("./tmp/index.html", "utf8");

    // Generate some id that we can use to cache bust the file with. Date should be sufficient.
    const id = Date.now();

    if (index_html.includes(script_tag(view_state.id))) {
        index_html = index_html.replace(
            script_tag(view_state.id),
            script_tag(id)
        );
    } else {
        index_html = index_html.replace(
            '<div id="daily_site_model"></div>',
            script_tag(id)
        );
    }

    // Update the id with new date value.
    view_state.id = id;

    const model = `
    // We wrap in a JSON.parse to tell the js engine that it's just a json, which is faster to parse then an ordinary js object.
    // https://v8.dev/blog/cost-of-javascript-2019#json.
    window.DAILY_SITE_DATA = JSON.parse('${JSON.stringify(view_state)}');
    // Prevent mutation.
    Object.freeze(window.DAILY_SITE_DATA);`;

    // Delete old view model.
    try {
        execSync("find www -maxdepth 1 -type f -name 'view_model.*.js' -delete");
    } catch (e) {
        console.log(e);
    }

    // Save all updated files to the repository.
    writeFileSync(
        `./tmp/www/view_state.json`,
        JSON.stringify(view_state, null, 4)
    );
    writeFileSync(`./tmp/www/view_model.${id}.js`, model);
    writeFileSync(`./tmp/index.html`, index_html);
}
