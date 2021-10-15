# Deconstruction

Deconstruction is a mod made for Factorio. When miners run out of resources to mine, they get marked for deconstruction. 

## Chests

Chests receiving input directly from miners can also be marked for deconstruction. This can be toggled off and on within the mod's settings. Chests by default won't be marked for deconstruction. You can set it so they will when their miner gets marked for deconstruction or also set the condition that they have to be empty. If you set it so the chest must also be emptied before getting marked for deconstruction, then the chest has about a minute to get emptied otherwise it won't get marked for deconstruction even if he becomes empty later.

## Belts

Belts receiving input directly from miners can be marked for deconstruction. This can be toggled off and on within the the mod's settings. Belts, which includes underground belts and splitters, by default won't get marked for deconstruction. If you enable this setting then any belts at the end of a line, when they lose their miner will also get marked for deconstruction if they are empty. The belt at the end of the line will need to be empty before it will be marked for destruction and has about a minute to do so. When it is marked for deconstruction the next belt in the line will be checked and so on. Each belt has it's own minute to get emptied starting from when the last one got marked for deconstruction.

## Pipes

Pipes are yet to be implemented, but what they'll essentially do is place ghost pipes down, where nessicary, for uranium mining when a miner get's marked for deconstrcution. It will be best to have construction bots in the area with pipes available to replace the miners with pipes as needed.
