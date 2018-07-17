var exec = require('child_process').exec;

exports.config = {
  // See http://brunch.io/#documentation for docs.
  files: {
    javascripts: {
      joinTo: "js/app.js",
      order: {
        before: [
          "vendor/accessible-date-picker.js",
          "vendor/fixedsticky.js"
        ]
      }

      // To use a separate vendor.js bundle, specify two files path
      // https://github.com/brunch/brunch/blob/stable/docs/config.md#files
      // joinTo: {
      //  "js/app.js": /^(js)/,
      //  "js/vendor.js": /^(vendor)|(deps)/
      // }
      //
      // To change the order of concatenation of files, explicitly mention here
      // https://github.com/brunch/brunch/tree/master/docs#concatenation
      // order: {
      //   before: [
      //     "vendor/js/jquery-2.1.1.js",
      //     "vendor/js/bootstrap.min.js"
      //   ]
      // }
    },
    stylesheets: {
      joinTo: {
        'css/core.css': /^css\/core/,
        'css/app.css': /^css\/app/,
        'css/style_guide.css': /^css\/style_guide/
      }
    }
  },

  conventions: {
    // This option sets where we should place non-css and non-js assets in.
    // By default, we set this to "/assets/static". Files in this directory
    // will be copied to `paths.public`, which is "priv/static" by default.
    assets: /^(static)/,
    ignored: [
      /\/_/, 
      /vendor\/(node|j?ruby-.+|bundle)\//,
      /css\/layout.scss/
    ]
  },

  // Phoenix paths configuration
  paths: {
    // Dependencies and current project directories to watch
    watched: [
      "js",
      "css",
      "static",
      "vendor/fixedsticky.js",
      "vendor/accessible-date-picker.js",
      "node_modules/bootstrap/dist/js/modal.js",
      "node_modules/bootstrap/dist/js/collapse.js",
      "node_modules/bootstrap/dist/js/tooltip.js",
      "test"
    ],

    // Where to compile files to
    public: "../priv/static"
  },

  optimize: true, // <--- required for pleeease to run

  // Configure your plugins
  plugins: {
    babel: {
      presets: ["es2015"],
      // Do not use ES6 compiler in vendor code
      ignore: [/vendor/, /node_modules/]
    },
    cleancss: {
      level: 2
    },
    sass: {
      mode: 'ruby',
      precision: 8,
      allowCache: true,
      includePaths: ['css'],
    },
    pleeease: {
      filters: false,
      rem: false,
      pseudoElements: false,
      opacity: false,
      import: false,
      minifier: true,
      autoprefixer: {
        browsers: [
          "safari >= 4",
          "ie >= 9",
          "last 20 versions"
        ]
      }
    },
    off: ['postcss']
  },

  modules: {
    autoRequire: {
      "js/app.js": ["js/app"]
    }
  },

  npm: {
    // Whitelist the npm deps to be pulled in as front-end assets.
    // All other deps in package.json will be excluded from the bundle.
    globals: {
      Tether: "tether",
      jQuery: "jquery/dist/jquery.min",
      collapse: "bootstrap/dist/js/umd/collapse",
      modal: "bootstrap/dist/js/umd/modal",
      tooltip: "bootstrap/dist/js/umd/tooltip",
      Turbolinks: "turbolinks",
      autocomplete: "autocomplete.js"
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
