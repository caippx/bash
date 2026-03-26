# Bilibili Live Room API Reference

Endpoint:

`GET https://api.live.bilibili.com/xlive/web-room/v1/index/getRoomBaseInfo?room_ids={房间号}&req_biz=web_room_componet&use_cache=false`

## Request

- Replace `{房间号}` with the target room ID.
- `req_biz=web_room_componet` is required for this skill's workflow.
- `use_cache=false` requests fresh data.

## Expected response handling

The response is JSON. Extract the room entry for the requested room ID from the returned data.

Common fields of interest:

- `live_status`
  - `0`: not live
  - `1`: live
- `title`: room title / live title
- `cover`: cover image URL
- `background`: background image URL

## Output guidance

When reporting results, keep the answer small and direct:

- room ID
- live status as a human-readable state
- title
- cover URL
- background URL

If any field is absent, say `missing` rather than guessing.
