/// <reference path="./typings/index.d.ts" />
import {platform} from "os";
import * as FS from "fs";
import * as Path from "path"
import * as Colors from "colors";

const isWindows: boolean = platform() == "win32";

type ReadResult = { fileName: string, variables: any };
type CreateResult = { fd: number, variables: any };
type WriteResult = number;
type CloseResult = {};
type UnlinkResult = {};
type CompileResult = {
  allSourceFiles: Array<Array<any>>;
  sourceFiles: Array<Array<any>>;
  path: string;
  targets: Array<Array<any>>;
  type: string;
}

let self: CssStyleguideCompilerBrunch;

class CssStyleguideCompilerBrunch {
  brunchPlugin: boolean;
  // type: string = "stylesheet";
  extension: string = "json";
  pattern: RegExp = /\.json$/;
  _bin: string = isWindows ? 'sass.bat' : 'sass';
  _compass_bin: string = isWindows ? 'compass.bat' : 'compass'; //eslint-disable-line camelcase
  config: any;
  writePath: string = Path.join(process.cwd(), 'web/static/css')
  promises: Array<Promise<any>>;

  constructor(private files: Array<string>) {
    self = this;
    this.files.forEach((file: string) => {
      const fullPath: string = this.createJSONPath(file);
      FS.readFile(fullPath, (err: NodeJS.ErrnoException, data: Buffer) => {
        if (err) {
          // Throws in a brunch plugin trigger an NPM error which doesn't give stacktrace,
          // so I'm adding a console.log here to explain why Brunch is failing...
          const message: string = Colors.red.underline(`!!!!! ERROR: ${fullPath} does not exist!`);
          console.log(Colors.bgRed(message))
          throw new Error(message);
        }
      })
    })
  }

  compile(): Promise<any> {
    return new Promise((resolve, reject) => {
      console.log(Colors.magenta("Starting precompile..."));
      this.promises = [];
      this.files.forEach(this.createPrecompilePromise)
      Promise.all(this.promises).then(() => {
        this.promises = [];
        console.log(Colors.magenta("Finished SCSS precompile."));
        resolve()
      }).catch((error: any) => {
        throw error
      })
    })
  }

  createPrecompilePromise(file: string) {
    const promise: Promise<any> = new Promise((_resolve: () => any, _reject: (error: Error) => any): void => {
      self.readJSON(file)
        .then(self.createScssFile)
        .then(self.writeScssFile)
        .then(self.closeScssFile)
        .then(() => _resolve());
    })
    self.promises.push(promise);
  }

  readJSON(fileName: string): Promise<ReadResult> {
    return new Promise((resolve: (result: ReadResult) => Promise<CreateResult>, reject: (error: Error) => any) => {
      FS.readFile(self.createJSONPath(fileName), (readError: NodeJS.ErrnoException, _data: Buffer): void => {
        if (readError) { reject(new Error(`Read error: ${readError.message}`)) }
        const variables: any = JSON.parse(_data.toString());
        resolve({fileName: fileName, variables: variables})
      })
    })
  }

  createScssFile(result: ReadResult): Promise<CreateResult> {
    return new Promise((resolve: (result: CreateResult) => Promise<WriteResult>, reject: (error: Error) => any) => {
      console.log(Colors.magenta(`Creating ${result.fileName}.scss...`));
      const path: string = self.createScssPath(result.fileName);
      FS.open(path, 'w', (openError: NodeJS.ErrnoException, fd: number) => {
        if (openError) { reject(new Error(`Open error: ${openError.message}`)) }
        resolve({fd: fd, variables: result.variables});
      });
    });
  }

  writeScssFile(result: CreateResult): Promise<WriteResult> {
    return new Promise((resolve: (result: WriteResult) => Promise<CloseResult>, reject: (error: Error) => any) => {
      let scssString: string = '';
      try {
        for (const name in result.variables) {
          scssString += `${name}: ${result.variables[name]};\n`;
        }
      } catch (exception) {
        console.error(exception);
        throw new Error(`Error in writeScssFile: ${exception}`)
      }
      FS.write(result.fd, scssString, (writeError: NodeJS.ErrnoException, written: number, str: string) => {
        if (writeError) { throw new Error(`Write Error: ${writeError}`) }
        resolve(result.fd);
      });
    });
  }

  closeScssFile(fd: WriteResult): Promise<CloseResult> {
    return new Promise((resolve, reject) => {
      FS.close(fd, (closeError: NodeJS.ErrnoException) => {
        if (closeError) { throw new Error(`Close Error: ${closeError}`) }
        resolve();
      });
    });
  }

  createTeardownPromise(path: string) {
    try {
      const promise: Promise<any> = new Promise((resolve, reject) => {
        self.checkForScssFile(path).then((fileExists: boolean) => {
          if (fileExists) {
            self.unlinkScssFile(path).then(() => { resolve() }).catch((error: Error) => reject(error));
          } else {
            resolve();
          }
        })
      });
      self.promises.push(promise);
    } catch (exception) {
      console.log(Colors.red(`Error in createTeardownPromise: ${exception}`))
      throw new Error
    }
  }

  checkForScssFile(path: string): Promise<boolean> {
    return new Promise((resolve, reject) => {
      FS.readFile(path, (error: NodeJS.ErrnoException, file: Buffer) => {
        try {
          const fileExists: boolean = error ? false : true;
          resolve(fileExists);
        } catch (exception) {
          console.log(Colors.red(`Error in checkForScssFile: ${exception}`))
          reject(new Error(`Error checking for scss file: ${exception}`));
        }
      })
    })
  }

  unlinkScssFile(path: string): Promise<UnlinkResult> {
    return new Promise((resolve, reject) => {
      console.log(Colors.magenta(`Deleting ${Path.basename(path)}...`));
      FS.unlink(path, (error: NodeJS.ErrnoException) => {
        if (error) {
          console.log(Colors.red(`Error in unlinkScssFile: ${error}`))
          throw new Error(`Unlink error: ${error.message}`)
        }
        resolve();
      });
    });
  }

  createScssPath(file: string) {
    return `${self.writePath}/${file}.scss`
  }

  createJSONPath(file: string) {
    return `${self.writePath}/${file}.json`
  }

  teardown(): Promise<boolean> {
    return new Promise((resolve, reject) => {
      try {
        console.log(Colors.magenta("Starting teardown..."))
        self.promises = [];
        self.files.map(self.createScssPath).forEach(self.createTeardownPromise);
        Promise.all(self.promises)
          .then(() => {
            self.promises = [];
            console.log(Colors.magenta("Finished teardown."));
            resolve();
          })
          .catch((error: Error) => { console.error(`Error in CssStyleguideBrunch.teardown: ${error.message}`); throw error })
      } catch (exception) {
        throw new Error(`Error in teardown: ${exception}`)
      }

    })
  }
}

module.exports = CssStyleguideCompilerBrunch;
