# godot-inheritance-dock

Godot Engine does a terrific job of organizing built-in nodes and allowing you to create new ones or replace existing ones. However, it does not do quite as well for scripted types or custom types (which are also scripted). Likewise, it doesn't provide a convenient overview of the relationships between your project's various scenes. It also is more cumbersome than it should be do edit resource files in your projects. This plugin seeks to remedy those problems.

With this plugin, you will be able to...

- Quickly locate existing scenes, scripts, and resources with filenames that match custom regex filters.
- Visually see scene/script/resource relationships.
- Open any scene/script/resource in the dock.
- Instance scenes and nodes with scripts into the scene tree.
- Extend new scenes and scripts from the dock.
- Change nodes to use or extend a script in the dock.
- Add children that use or extend a script in the dock.
- Create and edit new resources easily from the dock.
- NEW: Can now filter by in-engine class type (scenes are filtered based on the root node).

TODO:

Add Undo/Redo capabilities.

KNOWN ISSUES:

When new files are created (scenes, scripts resources) sometimes they won't show up in the FileSystem dock immediately. You can try to fix this by clicking out of the editor and having it regain focus in your operating system. Every now and then the FileSystem dock will reset itself, but it should pick up on the new file's existence pretty soon.

When activating the plugin or opening a project with the plugin for the first time, it will need to "re-import assets" for the icons. This will cause the scripts to not load properly the first time. Re-open the project a second time, and it should be fine.

Currently, the plugin has some slight memory leaks I've been trying to track down.

Credits:

"Folder" and "Sync-Arrows" icons made or derived from the works of [SmashIcons](https://www.flaticon.com/authors/smashicons) and [Freepik](https://www.flaticon.com/authors/freepik) from [www.flaticon.com](https://www.flaticon.com/). Licensed by [CC 3.0 BY](http://creativecommons.org/licenses/by/3.0/)
