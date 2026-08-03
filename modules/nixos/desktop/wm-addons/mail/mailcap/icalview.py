#!/usr/bin/env python

import sys
import html2text
from icalendar import Calendar
from tzlocal import get_localzone

calendar = Calendar.from_ical(sys.stdin.read())
tz = get_localzone()

for event in calendar.walk("vevent"):
    summary = event.get("SUMMARY")

    start = event.decoded("DTSTART").astimezone(tz)
    start = start.strftime("%a %d %b %H:%M %Y")
    end = event.decoded("DTEND").astimezone(tz)
    end = end.strftime("%a %d %b %H:%M %Y")

    attendees = None
    if "ATTENDEE" in event:
        if type(event.decoded("ATTENDEE")) == list:
            attendees = ",\n             ".join(
                [a[7:] for a in event.decoded("ATTENDEE")]
            )
        else:
            attendees = event.decoded("ATTENDEE")[7:]

    description = event.get("DESCRIPTION") or ""
    description = description.replace("\n", "<br>")
    description = html2text.html2text(description)
    description = "\n".join(description.split("\n"))

    print("# " + summary)
    print()
    print("Start:      ", start)
    print("End:        ", end)
    print("Attendee(s):", attendees)
    print("Description:")
    print(description)
