#!/usr/bin/env python

import sys
import html2text
import pytz
from icalendar import Calendar

calendar = Calendar.from_ical(sys.stdin.read())

for event in calendar.walk('vevent'):
    tz = pytz.timezone('America/Panama')
    summary = event.get('SUMMARY')
    start = event.decoded('DTSTART').astimezone(tz)
    end = event.decoded('DTEND').astimezone(tz)

    attendees = None
    if 'ATTENDEE' in event:
        if type(event.decoded('ATTENDEE')) == list:
            attendees = ',\n               '.join(
                [a[7:] for a in event.decoded('ATTENDEE')])
        else:
            attendees = event.decoded('ATTENDEE')[7:]

    description = event.get('DESCRIPTION') or ''
    description = html2text.html2text(description)
    description = '    ' + '\n    '.join(description.split('\n'))

    print('=' * len(summary))
    print(summary)
    print('=' * len(summary))
    print()
    print('  Start:      ', start)
    print('  End:        ', end)
    print('  Attendee(s):', attendees)
    print('  Description:')
    print(description)

