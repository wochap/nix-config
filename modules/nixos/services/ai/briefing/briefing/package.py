"""Stage package: join chapter audio into one MP3 with ID3v2 chapters.

usage: briefing-package --chapters chapters.json --audio DIR --out episode.mp3
                        --title TITLE --album ALBUM --date YYYY-MM-DD [--cover image]

Chapter markers (ID3v2 CHAP frames) let podcast apps such as AntennaPod skip
between sections.
"""

import argparse
import json
import os
import subprocess
import tempfile

from briefing.common import log, read_json

STAGE = "package"
GAP = 0.8


def duration(path):
    result = subprocess.run(
        ["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "json", path], capture_output=True, text=True, check=True
    )
    return float(json.loads(result.stdout)["format"]["duration"])


def escape(text):
    for char in ("\\", "=", ";", "#", "\n"):
        text = text.replace(char, "\\" + char)
    return text


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--chapters", required=True)
    parser.add_argument("--audio", required=True)
    parser.add_argument("--out", required=True)
    parser.add_argument("--title", required=True)
    parser.add_argument("--album", default="Briefing")
    parser.add_argument("--date", required=True)
    parser.add_argument("--cover")
    parser.add_argument("--bitrate", default="96k")
    args = parser.parse_args()

    chapters = read_json(args.chapters)
    with tempfile.TemporaryDirectory() as work:
        padded, marks, cursor = [], [], 0.0
        for index, chapter in enumerate(chapters, start=1):
            source = os.path.join(args.audio, f"{index:02d}-{chapter['key']}.wav")
            target = os.path.join(work, f"{index:02d}.wav")
            subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", source, "-af", f"apad=pad_dur={GAP}", target], check=True)
            length = duration(target)
            marks.append((chapter["title"], cursor, cursor + length))
            cursor += length
            padded.append(target)

        listing = os.path.join(work, "list.txt")
        with open(listing, "w", encoding="utf-8") as handle:
            handle.writelines(f"file '{path}'\n" for path in padded)

        metadata = os.path.join(work, "metadata.txt")
        with open(metadata, "w", encoding="utf-8") as handle:
            handle.write(";FFMETADATA1\n")
            handle.write(f"title={escape(args.title)}\nalbum={escape(args.album)}\nartist={escape(args.album)}\ndate={args.date}\ngenre=Podcast\n")
            for title, start, end in marks:
                handle.write(f"\n[CHAPTER]\nTIMEBASE=1/1000\nSTART={int(start * 1000)}\nEND={int(end * 1000)}\ntitle={escape(title)}\n")

        command = ["ffmpeg", "-y", "-loglevel", "error", "-f", "concat", "-safe", "0", "-i", listing, "-i", metadata]
        if args.cover and os.path.exists(args.cover):
            command += ["-i", args.cover, "-map", "0:a", "-map", "2:v", "-c:v", "copy", "-disposition:v", "attached_pic"]
        else:
            command += ["-map", "0:a"]
        command += ["-map_metadata", "1", "-map_chapters", "1", "-c:a", "libmp3lame", "-b:a", args.bitrate, "-ac", "1", "-id3v2_version", "3", f"{args.out}.tmp.mp3"]
        subprocess.run(command, check=True)
        os.replace(f"{args.out}.tmp.mp3", args.out)
    log(STAGE, f"{args.out}: {len(chapters)} chapters, {cursor / 60:.1f} min")


if __name__ == "__main__":
    main()
