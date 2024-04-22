// @ts-ignore
import { Elm } from "./elm/Main.elm";

import view_state from "./test/view_state_2.json";

const projects = Object.entries(view_state).map(([projectName, branch]) => ({
  name: projectName,
  branches: Object.entries(branch).map(([branchSlug, data]) => ({
    name: data.name,
    slug: branchSlug,
    date: data.date,
  })),
}));

Elm.Main.init({
  flags: {
    owner: "robinjac",
    hostRepository: "daily-sites",
    selectedProject: projects[0],
    projects,
  },
  node: document.getElementById("app") as HTMLElement,
});
