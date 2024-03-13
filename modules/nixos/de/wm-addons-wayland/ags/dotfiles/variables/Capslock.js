export const Capslock = Variable(
  { text: "", class: "" },
  {
    listen: ["capslock", (out) => JSON.parse(out)],
  },
);
