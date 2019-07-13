#!/usr/bin/env node

const config = require('rc')('tre-showcontrol', {
  secondsBeforePinging: 15,
  secondsBetweenPings: 5,
  minFailedPings: 10,
  pingTimeoutSeconds: 5,
  shutdownCommand: 'sudo systemctl poweroff -i'
})

console.log(JSON.stringify(config, null, 2))

const Monitor = require('./monitor')
let abort

if (config.monitorIP) {
  start(config.monitorIP, config)
} else {
  console.log('Tracking station for show-control-ip')
  require('tre-track-stations/bin')( kvm => {
    console.log(kvm)
    const content = kvm && kvm.value && kvm.value.content
    const monitorIP = content && content['show-control-ip']
    start(monitorIP, config)
  })
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

