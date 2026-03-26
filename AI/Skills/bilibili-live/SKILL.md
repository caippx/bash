---
name: bilibili-live-room
description: Fetch and interpret Bilibili live room base info from the getRoomBaseInfo API. Use when the user provides a Bilibili room ID or asks for live room status, title, cover, or background image information.
---

# Bilibili Live Room

## Quick start

Use the live room base-info endpoint with the target room ID:

`https://api.live.bilibili.com/xlive/web-room/v1/index/getRoomBaseInfo?room_ids={房间号}&req_biz=web_room_componet&use_cache=false`

Read the JSON response and extract the room entry for the requested ID.

## What to return

Prefer a compact summary with these fields when available:

- `live_status`: `0` = not live, `1` = live
- `title`: live title
- `cover`: cover image URL
- `background`: background image URL

If the response includes multiple room IDs, select the matching room ID entry only.

## Workflow

1. Replace `{房间号}` with the requested room ID.
2. Fetch the endpoint.
3. Parse the response JSON.
4. Return the four fields above.
5. If the API errors or data is missing, state the issue clearly and include the raw status/error summary.

## Notes

- Treat the API as the source of truth for live status.
- Do not invent or guess missing fields.
- If the room is offline, still return the title and images when present.
- For monitoring or alert workflows, stay silent while offline and only announce when `live_status` is `1`.
- When alerting, keep it minimal: room link, title, and cover image only.

## Example

Input room ID: `123456`

Request:

`https://api.live.bilibili.com/xlive/web-room/v1/index/getRoomBaseInfo?room_ids=123456&req_biz=web_room_componet&use_cache=false`

Example output:

- room_id: `123456`
- live_status: `1` (live)
- title: `Tonight's stream`
- cover: `https://.../cover.jpg`
- background: `https://.../bg.jpg`

## Reference

See [references/api.md](references/api.md) for the endpoint shape and response-handling tips.
