import GLib from "gi://GLib";

export const spacing = 7;

// NOTE: personal preference, I like to have only one bar
export const mainOutputName = GLib.getenv("MAIN_OUTPUT_NAME") || "";

export const headlessOutputName = "HEADLESS-1";
