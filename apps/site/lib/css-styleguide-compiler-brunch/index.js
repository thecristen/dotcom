"use strict";
var os_1 = require("os");
var FS = require("fs");
var Path = require("path");
var Colors = require("colors");
var isWindows = os_1.platform() == "win32";
var self;
var CssStyleguideCompilerBrunch = (function () {
    function CssStyleguideCompilerBrunch(files) {
        var _this = this;
        this.files = files;
        this.extension = "json";
        this.pattern = /\.json$/;
        this._bin = isWindows ? 'sass.bat' : 'sass';
        this._compass_bin = isWindows ? 'compass.bat' : 'compass';
        this.writePath = Path.join(process.cwd(), 'web/static/css');
        this.copyPath = Path.join(process.cwd(), 'priv/static/css');
        self = this;
        this.files.forEach(function (file) {
            var fullPath = _this.createJSONPath(file);
            FS.readFile(fullPath, function (err, data) {
                if (err) {
                    var message = Colors.red.underline("!!!!! ERROR: " + fullPath + " does not exist!");
                    console.log(Colors.bgRed(message));
                    throw new Error(message);
                }
            });
        });
    }
    CssStyleguideCompilerBrunch.prototype.compile = function () {
        var _this = this;
        return new Promise(function (resolve, reject) {
            console.log(Colors.magenta("Starting precompile..."));
            _this.promises = [];
            _this.files.forEach(_this.createPrecompilePromise);
            Promise.all(_this.promises).then(function () {
                _this.promises = [];
                console.log(Colors.magenta("Finished SCSS precompile."));
                resolve();
            }).catch(function (error) {
                throw error;
            });
        });
    };
    CssStyleguideCompilerBrunch.prototype.createPrecompilePromise = function (file) {
        var promise = new Promise(function (_resolve, _reject) {
            self.readJSON(file)
                .then(self.createScssFile)
                .then(self.writeScssFile)
                .then(self.closeScssFile)
                .then(function () { return _resolve(); });
        });
        self.promises.push(promise);
    };
    CssStyleguideCompilerBrunch.prototype.readJSON = function (fileName) {
        return new Promise(function (resolve, reject) {
            FS.readFile(self.createJSONPath(fileName), function (readError, _data) {
                if (readError) {
                    reject(new Error("Read error: " + readError.message));
                }
                var variables = JSON.parse(_data.toString());
                resolve({ fileName: fileName, variables: variables });
            });
        });
    };
    CssStyleguideCompilerBrunch.prototype.createScssFile = function (result) {
        return new Promise(function (resolve, reject) {
            console.log(Colors.magenta("Creating " + result.fileName + ".scss..."));
            var path = self.createScssPath(result.fileName);
            FS.open(path, 'w', function (openError, fd) {
                if (openError) {
                    reject(new Error("Open error: " + openError.message));
                }
                resolve({ fd: fd, variables: result.variables });
            });
        });
    };
    CssStyleguideCompilerBrunch.prototype.writeScssFile = function (result) {
        return new Promise(function (resolve, reject) {
            var scssString = '';
            try {
                for (var name_1 in result.variables) {
                    scssString += name_1 + ": " + result.variables[name_1] + ";\n";
                }
            }
            catch (exception) {
                console.error(exception);
                throw new Error("Error in writeScssFile: " + exception);
            }
            FS.write(result.fd, scssString, function (writeError, written, str) {
                if (writeError) {
                    throw new Error("Write Error: " + writeError);
                }
                resolve(result.fd);
            });
        });
    };
    CssStyleguideCompilerBrunch.prototype.closeScssFile = function (fd) {
        return new Promise(function (resolve, reject) {
            FS.close(fd, function (closeError) {
                if (closeError) {
                    throw new Error("Close Error: " + closeError);
                }
                resolve();
            });
        });
    };
    CssStyleguideCompilerBrunch.prototype.createTeardownPromise = function (path) {
        try {
            var promise = new Promise(function (resolve, reject) {
                self.checkForScssFile(path).then(function (fileExists) {
                    if (fileExists) {
                        self.unlinkScssFile(path).then(function () { resolve(); }).catch(function (error) { return reject(error); });
                    }
                    else {
                        resolve();
                    }
                });
            });
            self.promises.push(promise);
        }
        catch (exception) {
            console.log(Colors.red("Error in createTeardownPromise: " + exception));
            throw new Error;
        }
    };
    CssStyleguideCompilerBrunch.prototype.checkForScssFile = function (path) {
        return new Promise(function (resolve, reject) {
            FS.readFile(path, function (error, file) {
                try {
                    var fileExists = error ? false : true;
                    resolve(fileExists);
                }
                catch (exception) {
                    console.log(Colors.red("Error in checkForScssFile: " + exception));
                    reject(new Error("Error checking for scss file: " + exception));
                }
            });
        });
    };
    CssStyleguideCompilerBrunch.prototype.unlinkScssFile = function (path) {
        return new Promise(function (resolve, reject) {
            console.log(Colors.magenta("Deleting " + Path.basename(path) + "..."));
            FS.unlink(path, function (error) {
                if (error) {
                    console.log(Colors.red("Error in unlinkScssFile: " + error));
                    throw new Error("Unlink error: " + error.message);
                }
                resolve();
            });
        });
    };
    CssStyleguideCompilerBrunch.prototype.copyJsonFile = function (path) {
        var promise = new Promise(function (resolve, reject) {
            console.log(Colors.magenta("Copying " + Path.basename(path) + " to priv/static/css..."));
            self.readJsonCopy(path)
                .then(self.writeJsonCopy)
                .catch(function (error) {
                console.log(Colors.red("Error copying JSON file to priv: " + error));
                throw new Error("copyJson error: " + error.message);
            });
        });
        self.promises.push(promise);
    };
    CssStyleguideCompilerBrunch.prototype.readJsonCopy = function (path) {
        return new Promise(function (resolve, reject) {
            FS.readFile(self.createJSONPath(path), function (error, data) {
                if (error)
                    return reject(error);
                resolve({ data: data.toString(), path: path });
            });
        });
    };
    CssStyleguideCompilerBrunch.prototype.writeJsonCopy = function (result) {
        return new Promise(function (resolve, reject) {
            FS.open(self.createJSONcopyPath(result.path), 'w', function (error, fd) {
                if (error)
                    return reject(error);
                FS.write(fd, result.data, function (error, written, str) {
                    if (error)
                        return reject(error);
                    console.log("successfully copied JSON file");
                    resolve("successfully copied JSON file");
                    FS.close(fd, function (_error) {
                        if (_error)
                            return reject(error);
                        resolve();
                    });
                });
            });
        });
    };
    CssStyleguideCompilerBrunch.prototype.createScssPath = function (file) {
        return self.writePath + "/" + file + ".scss";
    };
    CssStyleguideCompilerBrunch.prototype.createJSONPath = function (file) {
        return self.writePath + "/" + file + ".json";
    };
    CssStyleguideCompilerBrunch.prototype.createJSONcopyPath = function (file) {
        return self.copyPath + "/" + file + ".json";
    };
    CssStyleguideCompilerBrunch.prototype.teardown = function () {
        return new Promise(function (resolve, reject) {
            try {
                console.log(Colors.magenta("Starting teardown..."));
                self.promises = [];
                self.files.forEach(self.copyJsonFile);
                self.files.map(self.createScssPath).forEach(self.createTeardownPromise);
                Promise.all(self.promises)
                    .then(function () {
                    self.promises = [];
                    console.log(Colors.magenta("Finished teardown."));
                    resolve();
                })
                    .catch(function (error) { console.error("Error in CssStyleguideBrunch.teardown: " + error.message); throw error; });
            }
            catch (exception) {
                throw new Error("Error in teardown: " + exception);
            }
        });
    };
    return CssStyleguideCompilerBrunch;
}());
module.exports = CssStyleguideCompilerBrunch;
