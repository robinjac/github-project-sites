import { writeFileSync } from "fs";
import { join } from "path";
import { extractCommitData } from "./helpers";

const { branch_name } = extractCommitData(
  process.argv.filter((arg) => arg !== "--experimental-modules")[2]
);

// Define the file path
const filePath = join(__dirname, "branch.json");

// Write the JSON data to a file
writeFileSync(
  filePath,
  JSON.stringify(
    {
      name: branch_name,
      date: new Date().toLocaleString(),
    },
    null,
    2
  )
);
