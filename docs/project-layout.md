---
name: project-layout
description: DreamWeaver lives in a Team Create place "Untitled Experience" in Roblox Studio (R15); local folder only has a .rbxl; ChibiAvatars server script installed
metadata:
  type: project
  modified: 2026-11-27T07:27:29.233Z
---

- The real place is the cloud Team Create place "Untitled Experience" (collaborator Thing_1 also edits). The local folder C:\CODE\untitled_experience only holds an old "Untitled Experience.rbxl" (no Rojo, no git); script copies live in scripts/.
- Avatars are already R15. Avatar Settings > Body has Custom Scale height clamp 3.6–6.5 studs.
- 2026-11-27: ServerScriptService/ChibiAvatars installed (chibi body via HumanoidDescription scales + SurfaceGui sparkly eyes). Daniel asked to delete the old PlushKidCharacters kid-size script; it was removed.

- 0205bmj is a second player/collaborator. To have easierbycode and 0205bmj in the same test, use Test > Team Test > Start (others click Join); plain Play gives each person a private server.
- Windows "Click to Do" overlay sometimes steals focus; Studio once froze on a blank "RobloxStudio" dialog and needed a restart.

- Pushing: the Surface's gh/git account is shmupX and the device blocks switching to easierbycode. Working route (2026-11-27): `git bundle create` on the device, stage it, fetch into a cloud clone of easierbycode/dreamweaver (saved to project) and push from there; then `git update-ref refs/remotes/origin/main <sha>` on the device.
- Story system: ReplicatedStorage.StoryData (sections per stage), ServerScriptService.StoryService (playBeforeStage) + StoryStarter, StarterPlayerScripts.StoryPlayer.

**How to apply:** In Studio via computer use, do NOT call open_application for Roblox Studio while a place is open — it launches a new instance and can open the place twice ("Multiple Sessions Detected"). Insert scripts via the command bar (it's multi-line; click Run, Enter adds a newline). Don't drag in the viewport to resize panels — it moves parts.
