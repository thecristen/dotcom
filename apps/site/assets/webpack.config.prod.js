const MiniCssExtractPlugin = require("mini-css-extract-plugin");
const path = require("path");
const postcssPresetEnv = require("postcss-preset-env");
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

  module: {
    rules: [
      {
        test: /\.scss$/,
        use: [
          {
            loader: MiniCssExtractPlugin.loader
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
      }
    ]
  },

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
