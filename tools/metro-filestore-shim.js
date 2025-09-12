/* tools/metro-filestore-shim.js */
class FileStore {
  constructor(){ }
  get(){ return null }
  set(){ /* noop */ }
  clear(){ /* noop */ }
}
module.exports = FileStore;