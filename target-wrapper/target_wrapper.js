// Copyright 2018 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

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
