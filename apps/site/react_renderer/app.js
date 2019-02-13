import ReactServer from "react-dom/server";
import React from "react";
import readline from "readline";

import TransitNearMe from "../assets/ts/tnm/components/TransitNearMe";

const Components = {
  TransitNearMe
};

const makeHtml = ({ name, props }) => {
  try {
    if (!Components[name]) {
      throw Error(`Unknown component: ${name}`);
    }
    const element = Components[name];
    const createdElement = React.createElement(element, props);
    const markup = ReactServer.renderToString(createdElement);

    return {
      error: null,
      markup: markup,
      component: name
    };
  } catch (err) {
    return {
      error: {
        type: err.constructor.name,
        message: err.message,
        stack: err.stack
      },
      markup: null,
      component: name
    };
  }
};

process.stdin.on("end", () => {
  process.exit();
});

readline
  .createInterface({
    input: process.stdin,
    output: process.stdout,
    terminal: false
  })
  .on("line", line => {
    const input = JSON.parse(line);
    const result = makeHtml(input);
    const jsonResult = JSON.stringify(result) + "\n";
    process.stdout.write(jsonResult);
  });
