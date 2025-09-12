const metroShim = require('./tools/metro-sourcemap-shim');
const { getDefaultConfig }=require("expo/metro-config"); const cfg=getDefaultConfig(__dirname); module.exports=cfg;
