module.exports = {
  defaultBrowser: "Firefox",
  handlers: [
    {
      match: [
        finicky.matchDomains(/localhost|amazonaws|zeplin/)
      ],
      browser: "Google Chrome"
    },
    {
      match: [
        finicky.matchDomains(/meet\.google\.com/)
      ],
      browser: "Safari"
    },
  ]
};
