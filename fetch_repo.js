const config = {
  headers: {
    Authorization: `token ${process.env.ACCESS_TOKEN}`,
  },
};

const url = (path) =>
  `https://api.github.com/repos/${process.env.OWNER}/${process.env.REPO}/contents/${path}`;

const toJson = (response) => {
  if (!response.ok) {
    throw new Error(
      `Failed to fetch: ${response.status} ${response.statusText}`
    );
  }
  return response.json();
};

const view_state = {};

fetch(url(""), config)
  .then(toJson)
  .then(async (data) => {
    const projects = data.filter(({ type }) => type === "dir");

    for (const project of projects) {
      view_state[project.name] = {};

      const res = await fetch(url(project.path), config);
      const branches = await res.json();

      for (const branch of branches) {
        view_state[project.name][branch.name] = {
          name: branch.name,
          path: branch.path,
        };
      }
    }

    console.log(view_state);
  })
  .catch((error) => {
    console.error("Error fetching data:", error);
  });
