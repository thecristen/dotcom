module.exports = {
  preset: "ts-jest",
  transform: {
    "^.+\\.js?$": "babel-jest",
    "^.+\\.ts?$": "ts-jest"
  },
  testEnvironment: "jsdom",
  setupTestFrameworkScriptFile: "./__tests__/setupTests.ts",
  testPathIgnorePatterns: [
    "/node_modules/",
    "./ts-build",
    "./__tests__/setupTests.ts"
  ]
};
