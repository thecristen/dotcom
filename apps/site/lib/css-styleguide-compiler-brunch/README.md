## Styleguide Compiler -- Custom Brunch Plugin

This is a brunch plugin that reads SCSS variables from JSON files and writes them to actual SCSS files, then deletes those SCSS files once they have been compiled. It was written to support our StyleGuide's "Single Source of Truth" philosophy -- having this plugin enables us to define SCSS variables once, in a format that can be read by both the SCSS compiler and the StyleGuide definition pages. It was mostly written with color and font-size variables in mind, in an attempt to keep our styleguide as up-to-date as possible without depending on the developer to remember to update the documentation.

Variables are not required to be defined in this format; any that are defined inside of regular SCSS files will still work as expected, but they will not be added to the styleguide.


## Instructions for making a new JSON file accessible to this plugin:

1. Save the JSON file inside of the CSS folder (`apps/site/web/static/css`).
    - File format needs to be JSON, obviously, but the variable names should include the $ at the front. Do not include the semicolon at the end of the variable, that will be added by the compiler.
    - `apps/site/web/static/css/my-new-variables.json`:
        ```JSON
            {
                "$my-new-variable-1": "#CCC",
                "$my-new-variable-2": "#12a7e0"
            }
        ```
2. In `apps/site/brunch-config.js`, add the name of the new JSON file **WITHOUT the .json extension** to the `styleguideVariableFiles` array at the top of the file.
    - `apps/site/brunch-config/js`:
        ```javascript
        var exec = require('child_process').exec;
        var styleguideVariableFiles = [ 'colors', 'my-new-variables' ];     <==== [FILE NAME GOES IN THIS ARRAY]
        exports.config = {
          // See http://brunch.io/#documentation for docs.
        ...
        ```
3. Run `npm run brunch:build` to compile your css files. If you watch the CSS folder you will see `my-new-variables.scss` get created and then destroyed during the build process.