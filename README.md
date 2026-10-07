# Default NWN Mod

A Git workspace for Neverwinter Nights 1 / Enhanced Edition modding.
This repository is a project scaffold; it does not yet contain a playable module.

## Layout

| Directory | Contents |
| --- | --- |
| `scripts/` | Authored NWScript source (`.nss`). |
| `resources/` | Exported module resources, blueprints, conversations, and custom data. |
| `assets/` | Original artwork, models, audio, and other custom asset sources. |
| `modules/` | Authored module (`.mod`), hak (`.hak`), and talk table (`.tlk`) snapshots when needed. |
| `docs/` | Design notes, dependencies, and playtest notes. |
| `build/` | Generated compilation and packaging output (ignored by Git). |
| `dist/` | Release packages (ignored by Git). |

## Working on the mod

1. Create or open your module in the Aurora Toolset. See the original
   [BioWare module construction tutorial](https://neverwintervault.org/sites/neverwintervault.org/files/project/1463/files/auroratoolsettutorial.pdf).
2. Keep authored script sources in `scripts/` and exported resources in
   `resources/`. Copy edited scripts into the module through your chosen toolset
   or import workflow, and keep the repository copies in sync.
3. Compile scripts and package the module with your chosen tools. Record tool
   versions and commands in `docs/` once a build workflow is selected.
4. Test the module in the game before committing changes. Save a module snapshot
   under `modules/` if you use the toolset as your primary authoring workflow.
5. Review and commit your work:

   ```sh
   git status
   git diff
   git add scripts resources assets modules docs
   git commit -m "Describe the mod change"
   ```

## Version control conventions

- Track authored resources and source assets. Packed `.mod`, `.hak`, `.erf`, and
  `.tlk` files are allowed, but Git cannot provide useful text diffs for them.
- Compiled scripts (`.ncs`), toolset temporary module directories, save games,
  logs, and output directories are ignored. Keep the corresponding source scripts.
  If a dependency is supplied only as a compiled script, explicitly track that
  file with `git add -f path/to/file.ncs` and document its origin.
- Keep installed game files and third-party dependencies outside the repository.
  Record dependency versions, download locations, and required module settings
  in `docs/`.
- No compiler, game path, or deployment target is configured yet.
- Add a license before distributing your own work, and record permissions for
  any third-party assets you include.

## Connecting a remote

After creating an empty repository on your preferred Git host:

```sh
git remote add origin <repository-url>
git push -u origin main
```
