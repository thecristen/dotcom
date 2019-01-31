module.exports = {
  preset: "ts-jest",
  collectCoverage: true,
  collectCoverageFrom: [
    "**/*.{ts,tsx}",
    "!**/node_modules/**",
    "!**/transit-near-me*.ts*", // transit-near-me entry (not necessary to test), and also transit-near-me.tsx for now
    "!**/search.ts" // for now
  ],
  coverageThreshold: {
    global: {
      branches: 95,
      functions: 95,
      lines: 95,
      statements: -25 // No idea what good default is for this, this means "up to 25 uncovered statements allowed"
    }
  },
  transform: {
    "^.+\\.js?$": "babel-jest",
    "^.+\\.ts?$": "ts-jest"
  },
  testEnvironment: "jsdom",
  setupTestFrameworkScriptFile: "./tnm/__tests__/setupTests.ts",
  testPathIgnorePatterns: [
    "/node_modules/",
    "./ts-build",
    "./tnm/__tests__/setupTests.ts",
    "./tnm/__tests__/helpers"
  ]
};
