#!/usr/bin/env cached-nix-shell
/*
#! nix-shell -i node -p nodejs-14_x
*/

const https = require("https")

async function post(url, data) {
  const dataString = JSON.stringify(data)

  const options = {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Content-Length': dataString.length,
    },
    timeout: 1000,
  }

  return new Promise((resolve, reject) => {
    const req = https.request(url, options, (res) => {
      if (res.statusCode < 200 || res.statusCode > 299) {
        return reject(new Error(`HTTP status code ${res.statusCode}`))
      }

      const body = []
      res.on('data', (chunk) => body.push(chunk))
      res.on('end', () => {
        const resString = Buffer.concat(body).toString()
        resolve(resString)
      })
    })

    req.on('error', (err) => {
      reject(err)
    })

    req.on('timeout', () => {
      req.destroy()
      reject(new Error('Request time out'))
    })

    req.write(dataString)
    req.end()
  })
}

const main = async () => {
  const dataJSON = await post("https://app.rextie.com/api/v1/fxrates/rate/?origin=home", {})
  const data = JSON.parse(dataJSON)
  console.log(data.fx_rate_buy);
}

main()
