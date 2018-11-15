const CopyWebpackPlugin = require("copy-webpack-plugin");
const MiniCssExtractPlugin = require("mini-css-extract-plugin");
const OptimizeCSSAssetsPlugin = require("optimize-css-assets-webpack-plugin");
const path = require("path");
const webpack = require("webpack");
const UglifyJsPlugin = require("uglifyjs-webpack-plugin");
const postcssPresetEnv = require("postcss-preset-env");

module.exports = env => ({
  mode: env.production ? "production" : "development",

  entry: {
    app: ["./js/app.js"],
    core: ["./js/core.js"]
  },
  node: {
    console: false,
    fs: "empty",
    net: "empty",
    tls: "empty"
  },

  output: env.production
    ? {
        path: path.resolve(__dirname, "../priv/static/js"),
        filename: "[name].js",
        publicPath: "/"
      }
    : {
        path: path.resolve(__dirname, "public"),
        filename: "[name].js",
        publicPath: "http://localhost:8090/"
      },

  devtool: env.production ? "source-map" : "eval",

  resolve: {
    extensions: [".js", ".json"]
  },

  devServer: {
    headers: {
      "Access-Control-Allow-Origin": "*"
    },
    port: 8090,
    contentBase: path.resolve(__dirname, "../priv/static/css"),
    watchContentBase: true,
    compress: true
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
        test: /\.scss$/,
        use: [
          {
            loader: env.production
              ? MiniCssExtractPlugin.loader
              : "style-loader",
            options: { sourceMap: false }
          },
          {
            loader: "css-loader",
            options: { importLoaders: 1 }
          },
          {
            loader: "postcss-loader",
            options: {
              ident: "postcss",
              plugins: () => [postcssPresetEnv()]
            }
          },
          {
            loader: "sass-loader",
            options: {
              includePaths: [
                "node_modules/bootstrap/scss",
                "node_modules/font-awesome/scss"
              ],
              precision: 8
            }
          }
        ]
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
      env.production
        ? new UglifyJsPlugin({
            cache: true,
            parallel: true,
            sourceMap: true
          })
        : new UglifyJsPlugin({
            cache: true,
            parallel: true
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
      "autocomplete": "autocomplete.js"
    })
  ]
});
