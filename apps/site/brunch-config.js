var exec = require('child_process').exec;

exports.config = {
  // See http://brunch.io/#documentation for docs.
  files: {
    javascripts: {
      joinTo: "js/app.js",
      order: {
        before: [
          "vendor/fixedsticky.js"
        ]
      }

      // To use a separate vendor.js bundle, specify two files path
      // https://github.com/brunch/brunch/blob/stable/docs/config.md#files
      // joinTo: {
      //  "js/app.js": /^(web\/static\/js)/,
      //  "js/vendor.js": /^(web\/static\/vendor)|(deps)/
      // }
      //
      // To change the order of concatenation of files, explicitly mention here
      // https://github.com/brunch/brunch/tree/master/docs#concatenation
      // order: {
      //   before: [
      //     "web/static/vendor/js/jquery-2.1.1.js",
      //     "web/static/vendor/js/bootstrap.min.js"
      //   ]
      // }
    },
    stylesheets: {
      joinTo: {
        'css/core.css': /^web\/static\/css\/core/,
        'css/app.css': /^web\/static\/css\/app/,
        'css/style_guide.css': /^web\/static\/css\/style_guide/
      }
    }
  },

  conventions: {
    // This option sets where we should place non-css and non-js assets in.
    // By default, we set this to "/web/static/assets". Files in this directory
    // will be copied to `paths.public`, which is "priv/static" by default.
    assets: /^(web\/static\/assets)/
  },

  // Phoenix paths configuration
  paths: {
    // Dependencies and current project directories to watch
    watched: [
      "web/static",
      "vendor/fixedsticky.js",
      "node_modules/bootstrap/dist/js/modal.js",
      "node_modules/bootstrap/dist/js/collapse.js",
      "node_modules/bootstrap/dist/js/tooltip.js",
      "test/static"
    ],

    // Where to compile files to
    public: "priv/static"
  },

  // Configure your plugins
  plugins: {
    babel: {
      presets: ["es2015"],
      // Do not use ES6 compiler in vendor code
      ignore: [/web\/static\/vendor/]
    },

    sass: {
      mode: 'ruby',
      precision: 8,
      allowCache: true,
      includePaths: ['web/static/css'],
    },

    postcss: {
      processors: [
        require('autoprefixer')(['last 20 versions'])
      ]
    }
  },

  modules: {
    autoRequire: {
      "js/app.js": ["web/static/js/app.js"]
    }
  },

  npm: {
    // Whitelist the npm deps to be pulled in as front-end assets.
    // All other deps in package.json will be excluded from the bundle.
    globals: {
      Tether: "tether",
      collapse: "bootstrap/dist/js/umd/collapse",
      modal: "bootstrap/dist/js/umd/modal",
      tooltip: "bootstrap/dist/js/umd/tooltip",
      Turbolinks: "turbolinks"
    }
  },

  hooks: {
    onCompile: function() {
      exec("node_modules/svgo/bin/svgo -f priv/static/images --config svgo.yml");
    }
  }
};

if (process.env["MIX_ENV"] != "prod") {
  // dev-only dep for now
  exports.config.npm.globals["phoenix"] = "phoenix";
}
