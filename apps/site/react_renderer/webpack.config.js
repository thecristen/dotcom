const path = require("path");

module.exports = {
  entry: {
    app: ["./app.js"]
  },

  target: "node",

  mode: "production",

  module: {
    rules: [
      {
        test: /\.(ts|tsx)$/,
        exclude: /node_modules/,
        use: [{ loader: "babel-loader" }, { loader: "ts-loader" }]
      },
      {
        test: /\.(js)$/,
        exclude: [/node_modules/, path.resolve(__dirname, "ts/")],
        use: {
          loader: "babel-loader"
        }
      }
    ]
  },

  resolve: {
    extensions: [".tsx", ".ts", ".jsx", ".js"]
  },

  output: {
    path: path.resolve(__dirname, "./dist")
  }
};
