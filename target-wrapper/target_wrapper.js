var cp = require('child_process');
var http = require('http');
var Etcd = require('node-etcd');

var opts = {
  host: process.env.COREOS_PRIVATE_IPV4 || 'localhost'
};

// allow a list of peers to be passed, overides COREOS_PRIVATE_IPV4
if (process.env.ETCD_PEER_HOSTS) {
  opts.host = process.env.ETCD_PEER_HOSTS.split(',');
}

var etcd = new Etcd(opts.host);
var child = null;

function start() {
  var port = process.env.MAPPED_PORT || 3001;
  var hostname = process.env.COREOS_PRIVATE_IPV4 + ':' + port;

  etcd.set('/services/zetta/' + hostname, JSON.stringify({
    type: 'cloud-target',
    url: 'http://' + hostname,
    //      publicUrl: 'http://' + hostname,
    created: new Date(),
    version: '0'
  }));

  child = cp.fork('./target_server.js');
  child.once('exit', function() {
    etcd.del('/servics/zetta/localhost:' + port);
    setTimeout(start, 2000);
  });
}

start();
