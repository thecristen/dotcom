const path = require("path");
const postcssPresetEnv = require("postcss-preset-env");
const merge = require("webpack-merge");
const base = require("./webpack.config.base");

module.exports = env =>
  merge(base, {
    mode: "development",

    devtool: "cheap-inline-source-map",

    devServer: {
      host: "0.0.0.0",
      headers: {
        "Access-Control-Allow-Origin": "*"
      },
      port: env.port,
      contentBase: path.resolve(__dirname, "../priv/static/"),
      watchContentBase: true,
      compress: true
    },

    module: {
      rules: [
        {
          test: /\.scss$/,
          use: [
            {
              loader: "style-loader",
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
        }
      ]
    }
  });
