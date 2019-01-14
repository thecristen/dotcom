const CopyWebpackPlugin = require("copy-webpack-plugin");
const MiniCssExtractPlugin = require("mini-css-extract-plugin");
const OptimizeCSSAssetsPlugin = require("optimize-css-assets-webpack-plugin");
const path = require("path");
const webpack = require("webpack");

module.exports = {
  entry: {
    app: ["./js/app.js"],
    core: ["./js/core.js"],
    tnm: ["./js/transit-near-me-entry.js"]
  },

  node: {
    console: false,
    fs: "empty",
    net: "empty",
    tls: "empty"
  },

  module: {
    rules: [
      {
        test: /\.js$/,
        exclude: /(node_modules|deps)/,
        use: {
          loader: "babel-loader",
          options: {
            presets: [
              [
                "@babel/preset-env",
                {
                  useBuiltIns: "entry"
                }
              ]
            ]
          }
        }
      },
      {
        test: /\.svg$/,
        use: [
          { loader: "file-loader" },
          {
            loader: "svgo-loader",
            options: {
              externalConfig: "svgo.yml"
            }
          }
        ]
      }
    ]
  },

  plugins: [
    new CopyWebpackPlugin([{ from: "static/**/*", to: "../../" }], {}),
    new MiniCssExtractPlugin({ filename: "../css/[name].css" }),
    new webpack.ProvidePlugin({
      Turbolinks: "turbolinks",
      Tether: "tether",
      "window.Tether": "tether",
      $: "jquery",
      jQuery: "jquery",
      "window.jQuery": "jquery",
      "window.$": "jquery",
      phoenix: "phoenix",
      "autocomplete": "autocomplete.js"
    })
  ]
};
