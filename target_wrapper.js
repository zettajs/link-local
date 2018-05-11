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
var Etcd = require('node-etcd');

var etcd = new Etcd();
var child = null;

function start() {
  var port = process.env.MAPPED_PORT || 3001;
  setTimeout(function() {
    etcd.set('/services/zetta/localhost:' + port, JSON.stringify({
      type: 'cloud-target',
      url: 'http://localhost:' + port,
//      publicUrl: 'http://127.0.0.1:' + port,
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
