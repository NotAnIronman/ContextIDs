# Context IDs

Shows item, NPC, and world-object IDs in the game's hover text and right-click
menu. Interface IDs appear beside the cursor. Inventory and bank items show
their item ID.

Enable **Hold Control to show** in the plugin's gear settings to display IDs
only while Control is held. This setting is off by default and saved on reload.
An open right-click menu keeps the IDs it had when opened.

Interface IDs use the hovered component supplied by the client's menu. UI
backgrounds without menu entries may not expose an ID. NPC IDs are config IDs,
not the unique ID of an individual NPC instance.

Clone this repository into `dev_plugins/ContextIDs`, or extract the release ZIP
there. Run `prf` and `pon ContextIDs` in the developer console. To reload, run
`prf` and `prl ContextIDs`.
