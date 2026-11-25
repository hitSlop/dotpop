# App icon

The dotpop app icon is an Icon Composer document, `apps/apple/App/Shared/AppIcon.icon`: a
pearl-white frame around three layers (blended blue, violet and pink; one soft translucent
current; a raised glass lens). Xcode renders every size, the dark and tinted appearances and the
flat icon for macOS 15 from that one document. Open it in Icon Composer (Xcode > Open Developer
Tool) to look at or tune the material.

- `node artwork/brand/app-icon/build.mjs` writes the document (its `icon.json` and SVG layers).
  Change the icon here, or edit it in Icon Composer and carry the change back into this script.
- `node artwork/brand/app-icon/export.mjs` writes the flat images used where the document cannot
  be: the landing site (`apps/landing/public/assets/appicon*`), the join page's preview image
  (`apps/sharing/public/share-icon.png`) and the document type icon (`DocumentBadge`). Run it
  after changing the icon and commit the results.

The export needs Xcode 27 or later (for Icon Composer's `ictool`), `sips` and `cwebp`.
