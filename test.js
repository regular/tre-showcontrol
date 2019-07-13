const monitor = require('./monitor')

const abort = monitor('192.168.188.20', {
  secondsBeforePinging: 5,
  secondsBetweenPings: 2,
  pingTimeoutSeconds: 1,
  minFailedPings: 3,
  shutdownCommand: 'echo bye'
})

setTimeout(abort, 60000)
