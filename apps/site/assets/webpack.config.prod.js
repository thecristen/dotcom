const path = require("path");
const merge = require("webpack-merge");
const base = require("./webpack.config.base");

module.exports = merge(base, {
  mode: "production",

  output: {
    path: path.resolve(__dirname, "../priv/static/js"),
    filename: "[name].js",
    publicPath: "/"
  },

  devtool: "source-map",

  optimization: {
    splitChunks: {
      chunks: "all",
      cacheGroups: {
        vendors: false,
        // Set our own cacheGroups instead of using the default groups
        // Since all entrypoints are dependent on the app entrypoint
        vendor: {
          name: "vendors",
          test: /[\\/]node_modules[\\/](?!react*)/
        },
        react: {
          name: "react",
          test: /[\\/]node_modules[\\/](react*)/
        }
      }
    }
  }
});
