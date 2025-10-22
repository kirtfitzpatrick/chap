#!/usr/bin/env node

const _ = require("./lodash-lib.js");

const methodName = process.argv[2];
const arrayArgs = process.argv.slice(3);

switch (methodName) {
  case "pascalCase":
    console.log(_.upperFirst(_.camelCase(arrayArgs)));
    break;
  case "join":
    const separator = arrayArgs[0];
    console.log(_.join(arrayArgs.slice(1), separator));
    break;
  default:
    console.log(_[methodName](arrayArgs));
}
