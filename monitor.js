const MyLocalIp = require('my-local-ip')
const MyLocalNetmask = require('my-local-netmask')
const {Netmask} = require('netmask')
const debug = require('debug')('monitor')

const {exec} = require('child_process');
const ping = require('./ping')

module.exports = function(IP, config) {
  const subnet = new Netmask(MyLocalIp(), MyLocalNetmask())
  if (!subnet.contains(IP)) {
    console.log('show control IP not in local subnet')
    console.log('my local IP:', MyLocalIp())
    console.log('my local netmask', MyLocalNetmask())
    return ()=>{}
  }

  let oneSuccess = false
  let failCount = 0
  debug(`Waiting ${config.secondsBeforePinging} seconds before pinging`)
  let timerid = setTimeout(doPing, config.secondsBeforePinging * 1000)

  return function() {
    debug('abort monitoring')
    if (timerid !== null) {
      clearTimeout(timerid)
    }
    timerid = null
  }

  function doPing() {
    function again() {
      debug(`will ping again in ${config.secondsBetweenPings} seconds`)
      timerid = setTimeout(doPing, config.secondsBetweenPings * 1000)
    }
    debug(`ping ${IP}`)
    ping(IP, config.pingTimeoutSeconds, err => {
      if (!err) {
        debug('ping succeeded')
        if (!oneSuccess) {
          console.log('Received ping response')
        }
        oneSuccess = true
        failCount = 0
        return again()
      }
      // ping failed
      debug('ping failed')
      if (!oneSuccess) {
        debug('ignored, because it never was successful')
        return again()
      }
      failCount++
      console.log(`ping failed ${failCount} times in a row`)
      if (failCount >= config.minFailedPings) return poweroff()
      again()
    })
  }

  function poweroff() {
    console.log('Shutting down')
    exec(config.shutdownCommand, (err, stdout, stderr) => {
      console.log(stdout)
      console.log(stderr)
      if (err) {
        console.log('Shutdown failed:', err.message)
        return
      }
    })
  }
}
