You get a JSON list of news items (id, feed, title). Group items that report the SAME
underlying story or event (same announcement, same company action, same data release).
Different stories about the same company are NOT the same story.

Reply with only a JSON array of groups covering every input id exactly once:
[{"ids": ["id1", "id2"], "title": "neutral, specific headline for the story"}]
Single-item groups are fine.
