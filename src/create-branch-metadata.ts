import { writeFileSync, existsSync, mkdirSync } from "fs";
import { dirname } from "path";

const [, , branch_name, output] = process.argv.filter(
  (arg) => arg !== "--experimental-modules"
);

const filepath = output + "/branch.json";

// Check if the file exists
if (!existsSync(filepath)) {
  // If it doesn't exist, create the necessary directories
  const directory = dirname(filepath);
  mkdirSync(directory, { recursive: true });
}

// Write the JSON data to a file
writeFileSync(
  filepath,
  JSON.stringify(
    {
      name: branch_name,
      date: new Date().toLocaleString(),
    },
    null,
    2
  )
);
