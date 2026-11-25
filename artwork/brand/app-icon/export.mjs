// Flat images of the app icon for places that cannot use the Icon Composer document:
// the landing site, the join page's link preview and the document type icon.
// Needs Xcode's Icon Composer (ictool), sips and cwebp.
import { execFileSync } from "node:child_process";
import { mkdtempSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";

const repository = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../../..");
const icon = path.join(repository, "apps/apple/App/Shared/AppIcon.icon");
const developer = execFileSync("xcode-select", ["-p"], { encoding: "utf8" }).trim();
const ictool = path.join(developer, "../Applications/Icon Composer.app/Contents/Executables/ictool");
const work = mkdtempSync(path.join(tmpdir(), "app-icon-"));

function render(platform) {
  const output = path.join(work, `${platform}.png`);
  execFileSync(ictool, [icon, "--export-image", "--output-file", output, "--platform", platform,
    "--rendition", "Default", "--width", "1024", "--height", "1024", "--scale", "1"]);
  return output;
}

function write(source, size, destination) {
  const target = path.join(repository, destination);
  const png = destination.endsWith(".webp") ? path.join(work, `${size}.png`) : target;
  execFileSync("sips", ["-s", "format", "png", "-z", String(size), String(size), source, "--out", png], { stdio: "ignore" });
  if (png !== target) execFileSync("cwebp", ["-quiet", "-q", "90", png, "-o", target]);
  console.log(destination);
}

try {
  // Renders fill the canvas. Mac-style images sit inside Apple's icon margin (824 of 1024).
  const mac = path.join(work, "mac-padded.png");
  execFileSync("sips", ["-s", "format", "png", "-z", "824", "824", render("macOS"), "--out", mac], { stdio: "ignore" });
  execFileSync("sips", ["-p", "1024", "1024", mac], { stdio: "ignore" });
  write(mac, 512, "apps/landing/public/assets/appicon.png");
  write(mac, 256, "apps/landing/public/assets/appicon-256.png");
  write(mac, 256, "apps/landing/public/assets/appicon-256.webp");
  write(mac, 128, "apps/landing/public/assets/appicon-128.webp");
  write(mac, 256, "apps/apple/App/Shared/Assets.xcassets/DocumentBadge.imageset/badge-256.png");
  write(mac, 512, "apps/apple/App/Shared/Assets.xcassets/DocumentBadge.imageset/badge-512.png");
  write(render("iOS"), 1024, "apps/sharing/public/share-icon.png");
} finally {
  rmSync(work, { recursive: true, force: true });
}
