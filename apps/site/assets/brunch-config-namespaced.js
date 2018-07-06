var exec = require('child_process').exec;

exports.config = {
  // See http://brunch.io/#documentation for docs.
  files: {
    javascripts: {
      joinTo: "js/layout.js",
    },
    stylesheets: {
      joinTo: {
        'css/layout.css': /^css\/layout/,
      }
    }
  },

  conventions: {
    // This option sets where we should place non-css and non-js assets in.
    // By default, we set this to "/assets/static". Files in this directory
    // will be copied to `paths.public`, which is "priv/static" by default.
    assets: /^(static)/
  },

  // Phoenix paths configuration
  paths: {
    // Dependencies and current project directories to watch
    watched: [
      "css/layout.scss",
      "vendor/collapse.js",
    ],

    // Where to compile files to
    public: "../priv/static"
  },

  // Turn off brunch source maps in favor of inline postcss maps
  sourceMaps: false,

  // Configure your plugins
  plugins: {
    sass: {
      mode: 'ruby',
      precision: 8,
      allowCache: true,
      includePaths: ['css'],
    },
    postcss: {
      modules: {
        generateScopedName: 'mbta-[local]'
      },
      processors: [
        require('autoprefixer')(["safari >= 4",
        "ie >= 9",
        "last 20 versions"]),
        require('csswring')({ removeAllComments: true })
      ],
    },
    on: ['uglify-js-brunch'] // instead of optimize, to prevent pleeeease from running
  },
  modules: {
    autoRequire: {
      "js/app.js": ["js/app"]
    },
  },

  npm: {
    // Whitelist the npm deps to be pulled in as front-end assets.
    // All other deps in package.json will be excluded from the bundle.
    globals: {
      jQuery: "jquery/dist/jquery.min",
      Util: "bootstrap/dist/js/umd/util"
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
