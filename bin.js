require('./extra-modules-path')

const config = require('rc')('tre-showcontrol', {
  secondsBeforePinging: 15,
  secondsBetweenPings: 5,
  minFailedPings: 10,
  pingTimeoutSeconds: 5,
  shutdownCommand: 'systemctl poweroff -i'
})

console.log(JSON.stringify(config, null, 2))

const Monitor = require('./monitor')
let abort

if (config.monitorIP) {
  start(config.monitorIP, config)
} else {
  console.error('missing --monitorIP')
  process.exit(1)
}

function start(monitorIP, config) {
  if (abort) {
    console.log('Stop monitoring')
    abort()
    abort = null
  }
  if (monitorIP) {
    console.log('Monitoring show control IP:', monitorIP)
    abort = Monitor(monitorIP, config)
  }
}

