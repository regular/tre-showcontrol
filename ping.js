const {spawn} = require('child_process')

module.exports = function(ip, timeout, cb) {
  timeout = Number(timeout)
  if (isNaN(timeout)) timeout = 2

  const ping = spawn(process.env.SHELL, [
    '-c',
    `ping ${ip} -c 1 -W ${timeout}`
  ])
  ping.on('close', code =>{
    cb(code == 0 ? null : new Error(`exit code: ${code}`))
  })
}
