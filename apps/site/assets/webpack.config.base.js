const CopyWebpackPlugin = require("copy-webpack-plugin");
const MiniCssExtractPlugin = require("mini-css-extract-plugin");
const TerserPlugin = require("terser-webpack-plugin");
const OptimizeCSSAssetsPlugin = require("optimize-css-assets-webpack-plugin");
const webpack = require("webpack");
const path = require("path");

module.exports = {
  entry: {
    app: ["./js/app.js"],
    core: ["./js/core.js"], // For core.css only, not js
    tnm: ["./ts/transit-near-me-entry.ts"]
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

  optimization: {
    minimizer: [
      new TerserPlugin({
        cache: true,
        parallel: true,
        sourceMap: true,
        terserOptions: {
          ecma: 5,
          safari10: true // You scoundrel you
        }
      }),
      new OptimizeCSSAssetsPlugin({})
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
      autocomplete: "autocomplete.js"
    })
  ],

  resolve: {
    extensions: [".tsx", ".ts", ".jsx", ".js"]
  }
};
