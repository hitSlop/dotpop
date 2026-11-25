/** Self-contained builder for multi-platform PopCoreFFI.xcframework
 * (macos-arm64, ios-arm64, ios-arm64-simulator) + UniFFI Swift bindings.
 * Publishes to both `packages/PopKit/Generated` and `apps/apple/Packages/PopApple/Generated`.
 * Uses Node/Bun built-ins only so it never triggers JS package installation. */
import { cp, mkdir, mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { existsSync } from "node:fs";
import { homedir, tmpdir } from "node:os";
import { dirname, join, resolve } from "node:path";
import { spawn } from "node:child_process";

const repository = resolve(import.meta.dir, "../..");
const cargoHome = process.env.CARGO_HOME ?? join(homedir(), ".cargo");
const profile = process.env.POP_CARGO_PROFILE || "release";
const rustflags = [
  `--remap-path-prefix=${cargoHome}/registry/src=/cargo/registry/src`,
  `--remap-path-prefix=${cargoHome}/git/checkouts=/cargo/git/checkouts`,
];
const env = {
  ...process.env,
  PATH: `${process.env.HOME}/.cargo/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin:${process.env.PATH}`,
  CARGO_ENCODED_RUSTFLAGS: rustflags.join("\x1f"),
  IPHONEOS_DEPLOYMENT_TARGET: "26.0",
};

function cargoOutput(file: string, target?: string): string {
  return join(repository, "target", ...(target ? [target] : []), profile, file);
}

function run(command: string[]): Promise<void> {
  return new Promise((resolvePromise, reject) => {
    const child = spawn(command[0]!, command.slice(1), {
      cwd: repository,
      env,
      stdio: "inherit",
    });
    child.on("error", reject);
    child.on("close", (code) => {
      if (code === 0) resolvePromise();
      else reject(new Error(`Command failed (${code}): ${command.join(" ")}`));
    });
  });
}

async function writeIfChanged(path: string, bytes: Buffer): Promise<boolean> {
  if (existsSync(path)) {
    const existing = await readFile(path);
    if (existing.equals(bytes)) return false;
  }
  await mkdir(dirname(path), { recursive: true });
  await writeFile(path, bytes);
  return true;
}

export async function buildPopKit() {
  // 1. Host macOS library (dylib for uniffi-bindgen + staticlib for macos-arm64 slice)
  await run(["cargo", "build", "--locked", "--profile", profile, "-p", "pop-core-ffi"]);

  // 2. iOS device + iOS simulator staticlibs
  const iosTargets = ["aarch64-apple-ios", "aarch64-apple-ios-sim"] as const;
  for (const target of iosTargets) {
    await run(["cargo", "build", "--locked", "--profile", profile, "-p", "pop-core-ffi", "--target", target]);
  }

  // 3. Generate UniFFI Swift bindings + C headers
  const bindgen = join(repository, "generated/core-tools/bin/uniffi-bindgen");
  const tmp = await mkdtemp(join(tmpdir(), "popkit-build-"));
  try {
    const bindingsDir = join(tmp, "bindings");
    await mkdir(bindingsDir, { recursive: true });
    await run([
      bindgen,
      "generate",
      "--library",
      cargoOutput("libpop_core_ffi.dylib"),
      "--language",
      "swift",
      "--out-dir",
      bindingsDir,
    ]);

    const headersDir = join(tmp, "include");
    await mkdir(headersDir, { recursive: true });
    await cp(join(bindingsDir, "PopCoreFFI.h"), join(headersDir, "PopCoreFFI.h"));
    await cp(join(bindingsDir, "PopCoreFFI.modulemap"), join(headersDir, "module.modulemap"));

    // 4. Assemble multi-platform XCFramework (macOS arm64 + iOS arm64 + iOS Simulator arm64)
    const framework = join(tmp, "PopCoreFFI.xcframework");
    const cmd = ["xcodebuild", "-create-xcframework"];
    for (const target of [undefined, ...iosTargets]) {
      cmd.push("-library", cargoOutput("libpop_core_ffi.a", target), "-headers", headersDir);
    }
    cmd.push("-output", framework);
    await run(cmd);

    // 5. Publish to both standalone packages/PopKit/Generated and apps/apple/Packages/PopApple/Generated
    const destinations = [
      join(repository, "packages/PopKit/Generated"),
      join(repository, "apps/apple/Packages/PopApple/Generated"),
    ];
    const swiftBytes = await readFile(join(bindingsDir, "PopCoreBinding.swift"));
    const headerBytes = await readFile(join(headersDir, "PopCoreFFI.h"));
    const mapBytes = await readFile(join(headersDir, "module.modulemap"));

    for (const dest of destinations) {
      await mkdir(dest, { recursive: true });
      await writeIfChanged(join(dest, "PopCoreBinding/PopCoreBinding.swift"), swiftBytes);
      await writeIfChanged(join(dest, "include/PopCoreFFI.h"), headerBytes);
      await writeIfChanged(join(dest, "include/module.modulemap"), mapBytes);
      const targetFramework = join(dest, "PopCoreFFI.xcframework");
      await rm(targetFramework, { recursive: true, force: true });
      await cp(framework, targetFramework, { recursive: true });
    }
    console.log("PopKit multi-platform XCFramework & Swift bindings built and synced.");
  } finally {
    await rm(tmp, { recursive: true, force: true });
  }
}

if (import.meta.main) {
  await buildPopKit();
}
