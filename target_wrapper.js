var cp = require('child_process');
var Etcd = require('node-etcd');

var etcd = new Etcd();
var child = null;

function start() {
  var port = process.env.MAPPED_PORT || 3001;
  setTimeout(function() {
    etcd.set('/services/zetta/localhost:' + port, JSON.stringify({
      type: 'cloud-target',
      url: 'http://localhost:' + port,
      publicUrl: 'http://127.0.0.1:' + port,
      created: new Date(),
      version: '0'
    }));
  }, 1);

  child = cp.fork('./zetta-target-server/target_server.js');
  child.once('exit', function() {
    etcd.del('/servics/zetta/localhost:' + port);
    setTimeout(start, 2000);
  })
}

start();
