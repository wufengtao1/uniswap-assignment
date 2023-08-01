const fs = require("fs");
const path = require("path");

function writeFile(filePath, content) {
  const folderPath = path.dirname(filePath);
  if (!fs.existsSync(folderPath)) {
    fs.mkdirSync(folderPath);
  }
  fs.writeFileSync(filePath, content, "utf8");
}

function readFile(path) {
  return fs.readFileSync(path, "utf8");
}

module.exports = {
  writeFile,
  readFile
};
