module.exports = {
  preset: "ts-jest",
  collectCoverage: true,
  collectCoverageFrom: [
    "**/*.{ts,tsx}",
    "!**/node_modules/**",
    "!**/transit-near-me*.ts*", // transit-near-me entry (not necessary to test), and also transit-near-me.tsx for now
    "!**/search.ts" // for now
  ],
  coverageReporters: ["html"],
  coverageThreshold: {
    global: {
      branches: 95,
      functions: 95,
      lines: 95,
      statements: -25 // No idea what good default is for this, this means "up to 25 uncovered statements allowed"
    },
    "./ts/tnm/components/googleMaps/": {
      // The Google Maps API is difficult to test, so we consider a lower
      // threshold acceptable for these modules. However, callbacks in
      // these modules should always use named functions, and have unit tests.
      branches: 60,
      functions: 60,
      lines: 60,
      statements: -25
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
  ],
  moduleNameMapper: {
    "\\.svg$": "<rootDir>/tnm/__tests__/helpers/svgStubber.js"
  }
};
