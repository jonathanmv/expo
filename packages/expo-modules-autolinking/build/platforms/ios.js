"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.formatArrayOfReactDelegateHandler = exports.generatePackageListAsync = exports.resolveModuleAsync = void 0;
const spawn_async_1 = __importDefault(require("@expo/spawn-async"));
const fast_glob_1 = __importDefault(require("fast-glob"));
const fs_extra_1 = __importDefault(require("fs-extra"));
const path_1 = __importDefault(require("path"));
/**
 * Resolves module search result with additional details required for iOS platform.
 */
async function resolveModuleAsync(packageName, revision, options) {
    var _a, _b, _c;
    const [podspecFile] = await (0, fast_glob_1.default)('{*/,}*.podspec', {
        cwd: revision.path,
        ignore: ['**/node_modules/**'],
    });
    if (!podspecFile) {
        return null;
    }
    const podName = path_1.default.basename(podspecFile, path_1.default.extname(podspecFile));
    const podspecDir = path_1.default.dirname(path_1.default.join(revision.path, podspecFile));
    return {
        podName,
        podspecDir,
        flags: options.flags,
        modulesClassNames: (_a = revision.config) === null || _a === void 0 ? void 0 : _a.iosModulesClassNames(),
        appDelegateSubscribers: (_b = revision.config) === null || _b === void 0 ? void 0 : _b.iosAppDelegateSubscribers(),
        reactDelegateHandlers: (_c = revision.config) === null || _c === void 0 ? void 0 : _c.iosReactDelegateHandlers(),
    };
}
exports.resolveModuleAsync = resolveModuleAsync;
/**
 * Generates Swift file that contains all autolinked Swift packages.
 */
async function generatePackageListAsync(modules, targetPath) {
    const className = path_1.default.basename(targetPath, path_1.default.extname(targetPath));
    const generatedFileContent = await generatePackageListFileContentAsync(modules, className);
    await fs_extra_1.default.outputFile(targetPath, generatedFileContent);
}
exports.generatePackageListAsync = generatePackageListAsync;
/**
 * Generates the string to put into the generated package list.
 */
async function generatePackageListFileContentAsync(modules, className) {
    const modulesToImport = modules.filter((module) => module.modulesClassNames.length ||
        module.appDelegateSubscribers.length ||
        module.reactDelegateHandlers.length);
    const importSwiftModules = await Promise.all(modulesToImport.map((module) => normalizePodModuleAsync(module)));
    const modulesClassNames = []
        .concat(...modulesToImport.map((module) => module.modulesClassNames))
        .filter(Boolean);
    const appDelegateSubscribers = []
        .concat(...modulesToImport.map((module) => module.appDelegateSubscribers))
        .filter(Boolean);
    const reactDelegateHandlerModules = modulesToImport.filter((module) => !!module.reactDelegateHandlers.length);
    return `/**
 * Automatically generated by expo-modules-autolinking.
 *
 * This autogenerated class provides a list of classes of native Expo modules,
 * but only these that are written in Swift and use the new API for creating Expo modules.
 */

import ExpoModulesCore
${importSwiftModules.map((module) => `import ${module}\n`).join('')}
@objc(${className})
public class ${className}: ModulesProvider {
  public override func getModuleClasses() -> [AnyModule.Type] {
    return ${formatArrayOfClassNames(modulesClassNames)}
  }

  public override func getAppDelegateSubscribers() -> [ExpoAppDelegateSubscriber.Type] {
    return ${formatArrayOfClassNames(appDelegateSubscribers)}
  }

  public override func getReactDelegateHandlers() -> [ReactDelegateHandlerTupleType] {
    return ${formatArrayOfReactDelegateHandler(reactDelegateHandlerModules)}
  }
}
`;
}
/**
 * Formats an array of class names to Swift's array containing these classes.
 */
function formatArrayOfClassNames(classNames) {
    const indent = '  ';
    return `[${classNames.map((className) => `\n${indent.repeat(3)}${className}.self`).join(',')}
${indent.repeat(2)}]`;
}
/**
 * Formats an array of module to Swift's array containing ReactDelegateHandlers
 */
function formatArrayOfReactDelegateHandler(modules) {
    const values = [];
    for (const module of modules) {
        for (const handler of module.reactDelegateHandlers) {
            values.push(`(packageName: "${module.packageName}", klass: ${handler}.self)`);
        }
    }
    const indent = '  ';
    return `[${values.map((value) => `\n${indent.repeat(3)}${value}`).join(',')}
${indent.repeat(2)}]`;
}
exports.formatArrayOfReactDelegateHandler = formatArrayOfReactDelegateHandler;
async function normalizePodModuleAsync(module) {
    let result = module.podName;
    const podspecFile = path_1.default.join(module.podspecDir, `${module.podName}.podspec`);
    console.log('podspecFile', podspecFile);
    if (await fs_extra_1.default.pathExists(podspecFile)) {
        const { stdout } = await (0, spawn_async_1.default)('pod', ['ipc', 'spec', podspecFile]);
        const podspecJson = JSON.parse(stdout);
        if (podspecJson.header_dir) {
            result = podspecJson.header_dir;
        }
    }
    return result;
}
//# sourceMappingURL=ios.js.map