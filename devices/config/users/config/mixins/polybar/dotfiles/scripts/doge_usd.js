#!/usr/bin/env cached-nix-shell
/*
#! nix-shell -i node -p nodejs-14_x
*/

const https = require("https")

async function get(url) {
  const options = {
    method: 'GET',
    headers: {
      'Content-Type': 'application/json',
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

    req.write("")
    req.end()
  })
}

const main = async () => {
  try {
    const dataJSON = await get("https://sochain.com//api/v2/get_price/DOGE/USD")
    const data = JSON.parse(dataJSON)
    const binancePrice = data.data.prices.find(price => price.exchange === "binance")
    console.log(binancePrice.price);
  } catch (e) {
    console.log("ERROR");
  }
}

main()
